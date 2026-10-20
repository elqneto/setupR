#!/usr/bin/env bash
# Instala o R atual, o Positron e pacotes de ciência de dados.
# Compatível com Ubuntu 26.04 LTS e versões mais novas.
# Última atualização: 2026-10-20

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

run_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    DEBIAN_FRONTEND=noninteractive "$@"
  else
    sudo DEBIAN_FRONTEND=noninteractive "$@"
  fi
}

require_ubuntu() {
  if [[ ! -r /etc/os-release ]]; then
    echo "Não foi possível identificar o sistema." >&2
    exit 1
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "Este script suporta apenas Ubuntu. Sistema detectado: ${PRETTY_NAME:-desconhecido}." >&2
    exit 1
  fi
  local oldest
  oldest="$(printf '%s\n%s\n' "26.04" "${VERSION_ID}" | sort -V | head -n1)"
  if [[ "${oldest}" != "26.04" ]]; then
    echo "Requer Ubuntu 26.04 LTS ou mais recente. Sistema detectado: ${PRETTY_NAME}." >&2
    exit 1
  fi
  CODENAME="${VERSION_CODENAME}"
  UBUNTU_PRETTY="${PRETTY_NAME}"
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(sha256sum "${file}" | awk '{print $1}')"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "Checksum inválido para $(basename "${file}")." >&2
    echo "Esperado: ${expected}" >&2
    echo "Obtido:   ${actual}" >&2
    exit 1
  fi
}

import_repository_keys() {
  local gnupg_home
  gnupg_home="$(run_root mktemp -d)"
  # shellcheck disable=SC2064
  trap "run_root rm -rf '${gnupg_home}'" RETURN
  if ! run_root gpg --homedir "${gnupg_home}" --no-default-keyring \
      --keyring /usr/share/keyrings/r2u.gpg \
      --keyserver keyserver.ubuntu.com \
      --recv-keys A1489FE2AB99A21A 67C2D66C4B1D4339 51716619E084DAB9 F2B6E89C389782D0 5E25F516B04C661B \
    && ! run_root gpg --homedir "${gnupg_home}" --no-default-keyring \
      --keyring /usr/share/keyrings/r2u.gpg \
      --keyserver keys.openpgp.org \
      --recv-keys A1489FE2AB99A21A 67C2D66C4B1D4339 51716619E084DAB9 F2B6E89C389782D0 5E25F516B04C661B; then
    echo "Não foi possível obter as chaves dos repositórios do R." >&2
    exit 1
  fi
  run_root gpg --homedir "${gnupg_home}" --no-default-keyring \
    --keyring /usr/share/keyrings/r2u.gpg \
    --export --armor A1489FE2AB99A21A | run_root tee /etc/apt/trusted.gpg.d/eddelbuettel.asc >/dev/null
  run_root gpg --homedir "${gnupg_home}" --no-default-keyring \
    --keyring /usr/share/keyrings/r2u.gpg \
    --export --armor F2B6E89C389782D0 5E25F516B04C661B 51716619E084DAB9 | run_root tee /etc/apt/trusted.gpg.d/rutter.asc >/dev/null
}

configure_repositories() {
  if ! curl -fsI "https://cloud.r-project.org/bin/linux/ubuntu/${CODENAME}-cran40/Release" >/dev/null; then
    echo "O CRAN ainda não publica o R para ${UBUNTU_PRETTY} (${CODENAME})." >&2
    exit 1
  fi

  run_root tee /etc/apt/sources.list.d/cran.sources >/dev/null <<EOF
Types: deb
URIs: https://cloud.r-project.org/bin/linux/ubuntu
Suites: ${CODENAME}-cran40/
Components:
Architectures: amd64 arm64
Signed-By: /etc/apt/trusted.gpg.d/rutter.asc
EOF

  USE_R2U=0
  if curl -fsI "https://r2u.stat.illinois.edu/ubuntu/dists/${CODENAME}/Release" >/dev/null; then
    USE_R2U=1
    run_root tee /etc/apt/sources.list.d/r2u.sources >/dev/null <<EOF
Types: deb
URIs: https://r2u.stat.illinois.edu/ubuntu
Suites: ${CODENAME}
Components: main
Architectures: amd64 arm64
Signed-By: /etc/apt/trusted.gpg.d/eddelbuettel.asc
EOF
    run_root tee /etc/apt/preferences.d/99cranapt >/dev/null <<'EOF'
Package: *
Pin: release o=CRAN-Apt Project
Pin: release l=CRAN-Apt Packages
Pin-Priority: 700
EOF
  else
    echo "O r2u ainda não publica binários para ${CODENAME}. Os pacotes do R serão compilados."
  fi
}

enable_bspm() {
  if [[ "${USE_R2U}" -ne 1 ]]; then
    return 0
  fi
  run_root apt-get install -y --no-install-recommends python3-dbus python3-gi python3-apt
  run_root touch /etc/R/Rprofile.site
  run_root Rscript --vanilla -e 'install.packages("bspm", repos="https://cloud.r-project.org")'
  if ! run_root grep -q 'bspm::enable()' /etc/R/Rprofile.site 2>/dev/null; then
    run_root tee -a /etc/R/Rprofile.site >/dev/null <<'EOF'
suppressMessages(bspm::enable())
options(bspm.version.check=FALSE)
EOF
  fi
}

configure_java() {
  local arch java_home renviron
  arch="$(dpkg --print-architecture)"
  java_home="/usr/lib/jvm/java-21-openjdk-${arch}"
  if [[ ! -x "${java_home}/bin/java" ]]; then
    echo "O OpenJDK 21 não foi instalado em ${java_home}." >&2
    exit 1
  fi
  renviron="/etc/R/Renviron.site"
  run_root touch "${renviron}"
  if run_root grep -q '^JAVA_HOME=' "${renviron}"; then
    run_root sed -i "s|^JAVA_HOME=.*|JAVA_HOME=${java_home}|" "${renviron}"
  else
    echo "JAVA_HOME=${java_home}" | run_root tee -a "${renviron}" >/dev/null
  fi
  run_root env JAVA_HOME="${java_home}" R CMD javareconf
}

install_positron() {
  local meta version arch cdn_arch deb url work expected
  echo "Buscando a versão mais recente do Positron..."
  meta="$(curl -fsSL "https://api.github.com/repos/posit-dev/positron/releases/latest")"
  version="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])' <<<"${meta}")"
  if [[ -z "${version}" ]]; then
    echo "Não foi possível identificar a versão mais recente do Positron." >&2
    exit 1
  fi
  arch="$(dpkg --print-architecture)"
  case "${arch}" in
    amd64) cdn_arch="x86_64"; deb="Positron-${version}-x64.deb" ;;
    arm64) cdn_arch="arm64"; deb="Positron-${version}-arm64.deb" ;;
    *)
      echo "Arquitetura não suportada pelo Positron: ${arch}." >&2
      exit 1
      ;;
  esac
  url="https://cdn.posit.co/positron/releases/deb/${cdn_arch}/${deb}"
  work="$(mktemp -d)"
  echo "Baixando Positron ${version}..."
  curl -fL --retry 5 --retry-delay 2 -o "${work}/${deb}" "${url}"
  curl -fsSL --retry 5 --retry-delay 2 -o "${work}/checksums.json" \
    "https://cdn.posit.co/positron/releases/checksums/positron-${version}-checksums.json"
  expected="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "${work}/checksums.json" "${deb}")"
  verify_sha256 "${work}/${deb}" "${expected}"
  run_root apt-get install -y "${work}/${deb}"
  rm -rf "${work}"
}

install_quarto() {
  local meta arch url digest work deb expected
  echo "Buscando a versão mais recente do Quarto..."
  meta="$(curl -fsSL "https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest")"
  arch="$(dpkg --print-architecture)"
  mapfile -t quarto_info < <(python3 -c 'import json,sys
rel=json.load(sys.stdin)
arch=sys.argv[1]
name="quarto-%s-linux-%s.deb" % (rel["tag_name"].lstrip("v"), arch)
asset=next(a for a in rel["assets"] if a["name"]==name)
print(asset["browser_download_url"])
print(asset["name"])
print(asset.get("digest",""))' <<<"${meta}" "${arch}")
  url="${quarto_info[0]}"
  deb="${quarto_info[1]}"
  digest="${quarto_info[2]}"
  work="$(mktemp -d)"
  echo "Baixando ${deb}..."
  curl -fL --retry 5 --retry-delay 2 -o "${work}/${deb}" "${url}"
  if [[ "${digest}" == sha256:* ]]; then
    expected="${digest#sha256:}"
    verify_sha256 "${work}/${deb}" "${expected}"
  fi
  run_root apt-get install -y "${work}/${deb}"
  rm -rf "${work}"
}

install_r_packages() {
  local missing_file
  missing_file="$(run_root mktemp)"
  run_root chmod 644 "${missing_file}"
  echo "Instalando pacotes do R..."
  if ! run_root env SETUPR_MISSING="${missing_file}" Rscript - <<'EOF'
options(repos = c(CRAN = "https://cloud.r-project.org"))
options(Ncpus = max(1L, parallel::detectCores(logical = FALSE)))
pkgs <- c(
  "tidyverse", "data.table", "dplyr", "magrittr", "devtools", "roxygen2",
  "usethis", "bit64", "readr", "utf8", "lubridate", "rio", "janitor",
  "stringr", "bibliometrix", "arrow", "duckdb",
  "rJava", "DBI", "odbc", "dbplyr", "RMariaDB", "RMySQL", "RPostgres", "RSQLite", "RJDBC",
  "ggplot2", "shiny", "bslib", "visNetwork", "htmlwidgets", "igraph",
  "threejs", "networkD3", "sf", "leaflet", "plotly", "ragg", "svglite",
  "httpuv", "rsvg", "esquisse", "radiant",
  "testthat", "testthis",
  "htmlTable", "openxlsx", "readODS", "readxl", "writexl",
  "knitr", "rmarkdown", "quarto",
  "pdftools", "tabulapdf", "showtext", "systemfonts", "Cairo"
)
install.packages(pkgs)
if (requireNamespace("rio", quietly = TRUE)) {
  tryCatch(rio::install_formats(), error = function(e) message(conditionMessage(e)))
}
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing)) {
  writeLines(missing, Sys.getenv("SETUPR_MISSING"))
  quit(status = 1)
}
EOF
  then
    if [[ -s "${missing_file}" ]]; then
      echo "Estes pacotes do R não foram instalados:" >&2
      cat "${missing_file}" >&2
    else
      echo "A instalação dos pacotes do R falhou." >&2
    fi
    run_root rm -f "${missing_file}"
    exit 1
  fi
  run_root rm -f "${missing_file}"
}

main() {
  require_ubuntu
  if [[ "${EUID}" -ne 0 ]]; then
    sudo -v
  fi

  echo "Atualizando o índice de pacotes de ${UBUNTU_PRETTY}..."
  run_root apt-get update
  run_root apt-get install -y --no-install-recommends ca-certificates curl gnupg python3

  if dpkg-query -W -f='${Status}' rstudio 2>/dev/null | grep -q 'install ok installed'; then
    echo "Removendo o RStudio antigo..."
    run_root apt-get remove -y rstudio
  fi

  echo "Configurando os repositórios do R..."
  import_repository_keys
  configure_repositories
  run_root apt-get update
  run_root apt-get install -y --no-install-recommends r-base r-base-dev

  echo "Instalando bibliotecas de sistema..."
  run_root apt-get install -y --no-install-recommends \
    build-essential g++ gfortran cmake pkg-config \
    libxml2-dev libssl-dev libcurl4-openssl-dev libopenblas-dev \
    libpoppler-cpp-dev openjdk-21-jdk \
    libfreetype-dev libpng-dev libjpeg-dev libtiff-dev \
    libreadline-dev libx11-dev libxt-dev libcairo2-dev \
    libbz2-dev liblzma-dev librsvg2-bin librsvg2-dev libicu-dev \
    unixodbc-dev libpq-dev libmariadb-dev libsqlite3-dev \
    libgdal-dev libproj-dev libgeos-dev libudunits2-dev \
    libgsl-dev libnetcdf-dev libfontconfig1-dev libharfbuzz-dev \
    libfribidi-dev libgit2-dev libsodium-dev zlib1g-dev \
    cargo rustc pandoc

  configure_java
  enable_bspm
  install_quarto
  install_positron

  echo "Instalando LaTeX..."
  run_root apt-get install -y \
    texlive texlive-latex-recommended texlive-pictures \
    texlive-latex-extra texlive-fonts-recommended \
    texlive-xetex texlive-luatex

  install_r_packages
  echo "Instalação concluída com sucesso."
  echo "R: $(R --version | awk 'NR==1{print $3}')"
  echo "Positron: $(dpkg-query -W -f='${Version}' positron 2>/dev/null || echo indisponível)"
  echo "Quarto: $(quarto --version 2>/dev/null || echo indisponível)"
}

main "$@"
