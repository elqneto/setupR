#Remove previous R and RStudio installation
sudo apt-get remove rstudio
sudo apt-get --purge remove r-base r-base-dev r-base-core r-recommended
sudo rm -rf /usr/local/lib/R/site-library

sudo apt update

#Install gdebi 
sudo apt install gdebi-core

# Install R and a several additional linux tools. The commands required for Ubuntu 18.04 are
sudo apt update
sudo apt-get install g++
sudo apt install gdebi libxml2-dev libssl-dev libcurl4-openssl-dev libopenblas-dev libpoppler-cpp-dev default-jre default-jdk libfreetype6-dev
sudo apt-get install -y gfortran libreadline6-dev libx11-dev libxt-dev libcairo2-dev libbz2-dev liblzma-dev libgtk2.0-dev cmake build-essential librsvg2-bin librsvg2-dev 
sudo apt-get install libicu-dev unixodbc-dev libpq-dev libgdal-dev libproj-dev cargo libgsl-dev libnetcdf-dev libgeos-dev libudunits2-dev libv8-dev

sudo apt install r-base r-base-core r-base-dev 

sudo apt update

# Install RStudio
cd ~/Downloads
wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.3.959-amd64.deb
sudo gdebi rstudio-1.3.959-amd64.deb
printf '\nexport QT_STYLE_OVERRIDE=gtk\n' | sudo tee -a ~/.profile

# Changing R library folder permissions
sudo chmod a+rwx /usr/local/lib/R/site-library

# Install common packages
R --vanilla << EOF
install.packages(c("tidyverse","data.table","dplyr","magrittr","devtools","roxygen2","bit64","readr", "utf8", "lubridate", "rio"), repos = "https://cran.rstudio.com/", type="source")
rio::install_formats()
q()
EOF


# Install Data Base packages
R --vanilla << EOF
install.packages(c("rJava",  "odbc", "dbplyr", "RMySQL", "RJDBC"), repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Install some text 'wrestling'packages
R --vanilla << EOF
install.packages(c("janitor", "stringr"), repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Install Graphics, Maps, Spatial Analysis and Visualization common packages
R --vanilla << EOF

install.packages(c("ggplot2", "shiny", "visNetwork", "htmlwidgets", "igraph","threejs", "networkD3"), repos = "https://cran.rstudio.com/", type="source")

install.packages(c("leaflet", "leaflet.extras", "sf", "sp", "rgdal", "rgeos", "maps", "geosphere", "raster", "geor", "ggmap", "rosm", "gstat", "rmaps", "mapdata", "ncdf4"), repos = "https://cran.rstudio.com/", type="source")  


q()
EOF


# Install Statistical and Timeseries Analysis common packages
R --vanilla << EOF

install.packages(c("stats", "statmod", "graphics","quanteda", "tseries","tstools", "zoo", "xts", "dygraph", "gtools"), repos = "https://cran.rstudio.com/", type="source")

q()
EOF



# Install Parallel Computing common packages
R --vanilla << EOF

install.packages(c("Rcpp", "RSpectra", "robustbase", "RcppArmadillo", "Gmedian", "purrr"), repos = "https://cran.rstudio.com/", type="source")

q()
EOF


# Configuring H2O, Sparklyr and RSparkling packages (compatible among themselves)
R --vanilla << EOF


install.packages(c("methods", "RCurl", "jsonlite", "tools", "utils"), repos = "https://cran.studio.com/", type="source")

install.packages("h2o", type = "source", repos = "http://h2o-release.s3.amazonaws.com/h2o/rel-yau/3/R")

devtools::install_version("sparklyr", version = "1.0.3", repos = "http://cran.us.r-project.org")

sparklyr::spark_install(version = "2.2")

install.packages("rsparkling", type = "source", repos = "http://h2o-release.s3.amazonaws.com/sparkling-water/spark-2.2/3.26.3-2.2/R")

q()
EOF

# Install Radiant and Esquisse packages
R --vanilla << EOF

install.packages("httpuv", type="source")
install.packages("rsvg", type="source")
install.packages("esquisse", type="source")


devtools::install_version("mnormt", version = "1.5-6", repos = "http://cran.us.r-project.org")
devtools::install_version("radiant", version = "0.9.9.1", repos = "http://cran.us.r-project.org")

q()
EOF

# Install TDD packages
R --vanilla << EOF
install.packages("testthis", repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Export to HTML/Excel
R --vanilla << EOF
install.packages(c("htmlTable","openxlsx", "readODS"), repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Blog tools
R --vanilla << EOF
install.packages(c("knitr","rmarkdown"), repos='http://cran.us.r-project.org', type="source")
q()
EOF


# PDF extraction tools
sudo apt install r-cran-rjava
sudo R CMD javareconf
R --vanilla << EOF
library(devtools)
install.packages("pdftools", repos = "https://cran.rstudio.com/", type="source")
install_github("ropensci/tabulizer")
q()
EOF

# TTF/OTF fonts usage
R --vanilla << EOF
install.packages("showtext", repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Cairo for graphic devices
R --vanilla << EOF
install.packages("Cairo", repos = "https://cran.rstudio.com/", type="source")
q()
EOF

# Texlive for Latex/knitr
sudo apt -y install texlive
sudo apt -y install texlive-latex-recommended texlive-pictures texlive-latex-extra
