# setupR

Script to install current R, [Positron](https://positron.posit.co/), and data-science packages on Ubuntu 26.04 LTS and newer.

Positron is the [Posit](https://posit.co/) development environment for R and Python. Posit is the company formerly known as RStudio. RStudio Desktop still exists, and Positron is the product this script installs in its place.

## Usage

On Ubuntu 26.04.1 LTS or newer:

```bash
chmod +x r_setup.sh
./r_setup.sh
```

The script asks for an administrator password and needs internet access. It installs the latest Positron and Quarto releases, checks the SHA-256 checksum of each installer, and gets R from the CRAN repository. When [r2u](https://github.com/eddelbuettel/r2u) publishes binaries for that Ubuntu release, R packages are installed from it.

Installing LaTeX and the packages can take a long time and several gigabytes of disk space.

## What the script changes

- Removes the old `rstudio` package, if it is installed, and installs Positron.
- Stops pinning old Radiant and `mnormt` versions.
- Installs `RMariaDB` and `RMySQL`, and replaces `tabulizer` with `tabulapdf`.
- Installs OpenJDK 21 for `rJava` instead of the distribution's default Java.
- Does not delete an R package library already installed on the system.

## License

MIT. See [LICENSE](LICENSE).
