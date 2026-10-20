# setupR

Script para instalar o R atual, o [Positron](https://positron.posit.co/) e pacotes de ciência de dados no Ubuntu 26.04 LTS e em versões mais novas.

O Positron é o ambiente de desenvolvimento da [Posit](https://posit.co/) para R e Python. A Posit é a empresa que antes se chamava RStudio. O RStudio Desktop ainda existe, e o Positron é o software que o sucede neste script.

## Uso

No Ubuntu 26.04.1 LTS ou mais recente:

```bash
chmod +x r_setup.sh
./r_setup.sh
```

O script pede senha de administrador e precisa de internet. Ele instala a versão mais recente do Positron e do Quarto, confere o SHA-256 de cada instalador e obtém o R pelo repositório do CRAN. Quando o [r2u](https://github.com/eddelbuettel/r2u) publica binários para essa versão do Ubuntu, os pacotes do R são instalados por ele.

A instalação do LaTeX e dos pacotes pode levar bastante tempo e alguns gigabytes de disco.

## O que o script troca

- Remove o pacote antigo `rstudio`, se ele estiver instalado, e instala o Positron.
- Deixa de fixar versões antigas do Radiant e do `mnormt`.
- Instala o `RMariaDB` e o `RMySQL`, e troca o `tabulizer` pelo `tabulapdf`.
- Instala o OpenJDK 21, que o `rJava` usa, em vez do Java padrão da distribuição.
- Não apaga a biblioteca de pacotes do R já instalada no sistema.

## Licença

MIT. Veja [LICENSE](LICENSE).
