#!/bin/bash

# R and RStudio installation and configuration script for Ubuntu 18.04
# This script updates the current installation of R and RStudio, installs some additional tools and packages,
# and configures some common settings.
# Last updated: 2023-03-13

#Remove previous R and RStudio installation
sudo apt-get remove rstudio
sudo apt-get --purge remove r-base r-base-dev r-base-core r-recommended
sudo rm -rf /usr/local/lib/R/site-library

# Update system and install gdebi
sudo apt update
sudo apt install -y gdebi-core

# Install R and some additional tools
# update indices
sudo apt update -qq
# install two helper packages we need
sudo apt install --no-install-recommends software-properties-common dirmngr
# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
# Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

sudo apt-get install -y g++
sudo apt-get install -y libxml2-dev libssl-dev libcurl4-openssl-dev libopenblas-dev libpoppler-cpp-dev default-jre default-jdk libfreetype6-dev
sudo apt-get install -y gfortran libreadline6-dev libx11-dev libxt-dev libcairo2-dev libbz2-dev liblzma-dev libgtk2.0-dev cmake build-essential librsvg2-bin librsvg2-dev 
sudo apt-get install -y libicu-dev unixodbc-dev libpq-dev libgdal-dev libproj-dev cargo libgsl-dev libnetcdf-dev libgeos-dev libudunits2-dev libv8-dev

# Install some common packages
R --vanilla << EOF
install.packages(c("tidyverse","data.table","dplyr","magrittr","devtools","roxygen2","bit64","readr", "utf8", "lubridate", "rio"), repos = "https://cran.rstudio.com/", type="source")
rio::install_formats()
q()
EOF

# Install packages for database manipulation
R --vanilla << EOF
install.packages(c("rJava",  "odbc", "dbplyr", "RMySQL", "RJDBC"), repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Install packages for text processing
R --vanilla << EOF
install.packages(c("janitor", "stringr"), repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Install packages for graphics, maps, spatial analysis and visualization
R --vanilla << EOF
install.packages(c("ggplot2", "shiny", "visNetwork", "htmlwidgets", "igraph","threejs", "networkD3"), repos = "https://cran.rstudio.com/", type="R --vanilla << EOF
install.packages(c("tidyverse","data.table","dplyr","magrittr","devtools","roxygen2","bit64","readr", "utf8", "lubridate", "rio"), repos = "https://cran.rstudio.com/", type="source")
rio::install_formats()
q()
EOF

R --vanilla << EOF
install.packages(c("tidyverse","data.table","dplyr","magrittr","devtools","roxygen2","bit64","readr", "utf8", "lubridate", "rio"), repos = "https://cran.rstudio.com/", type="source")
rio::install_formats()
q()
EOF


#Install Radiant and Esquisse packages
R --vanilla << EOF
install.packages("httpuv", type="source")
install.packages("rsvg", type="source")
install.packages("esquisse", type="source")
devtools::install_version("mnormt", version = "1.5-6", repos = "http://cran.us.r-project.org")
devtools::install_version("radiant", version = "0.9.9.1", repos = "http://cran.us.r-project.org")
q()
EOF

#Install TDD packages
R --vanilla << EOF
install.packages("testthis", repos = "https://cran.rstudio.com/", type="source")
q()
EOF

#Export to HTML/Excel
R --vanilla << EOF
install.packages(c("htmlTable","openxlsx", "readODS"), repos = "https://cran.rstudio.com/", type="source")
q()
EOF

#Blog tools
R --vanilla << EOF
install.packages(c("knitr","rmarkdown"), repos='http://cran.us.r-project.org', type="source")
q()
EOF

#PDF extraction tools
sudo apt install r-cran-rjava
sudo R CMD javareconf
R --vanilla << EOF
library(devtools)
install.packages("pdftools", repos = "https://cran.rstudio.com/", type="source")
install_github("ropensci/tabulizer")
q()
EOF

#TTF/OTF fonts usage
R --vanilla << EOF
install.packages("showtext", repos = "https://cran.rstudio.com/", type="source")
q()
EOF

#Cairo for graphic devices
R --vanilla << EOF
install.packages("Cairo", repos = "https://cran.rstudio.com/", type="source")
q()
EOF

#Texlive for Latex/knitr
sudo apt -y install texlive
sudo apt -y install texlive-latex-recommended texlive-pictures texlive-latex-extra

#Finalização
echo "Instalação concluída com sucesso!"
