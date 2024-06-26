% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper-scripts.R
\name{CHECK_secrets_OK}
\alias{CHECK_secrets_OK}
\title{CHECK_secrets_OK
Check .secrets_mysql.php file exists on CSCN server and writes a file in ~/Downloads}
\usage{
CHECK_secrets_OK(
  path_to_secrets = "../../../",
  credentials_file = ".vault/.credentials"
)
}
\arguments{
\item{path_to_secrets}{Location of the .secrets_mysql.php in the server}

\item{credentials_file}{Path to .credentials file. By default: \code{.vault/.credentials}}
}
\description{
CHECK_secrets_OK
Check .secrets_mysql.php file exists on CSCN server and writes a file in ~/Downloads
}
