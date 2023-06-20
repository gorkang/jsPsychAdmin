#' check_status_participants_protocol
#' CHECKS the mysql database and extracts the number of participants completed, discarded and assigned per protocol
#'
#' @return
#' @export
#'
#' @examples
check_status_participants_protocol <- function() {


  list_credentials = source(".vault/.credentials")
  PASSWORD = list_credentials$value$password

  source("R/mysql_extract_tables.R")
  source("R/mysql_helper_functions.R")

  #Load encrypted data
  data_encrypted <- readRDS(".vault/data_encrypted.rds")

  #Public key (its okay to hardcode it here, public keys are designed for sharing)
  key_public = readLines(".vault/data_public_key.txt")

  #Private key
  key_private <- sodium::sha256(charToRaw(PASSWORD))

  #Check if private key provided is correct
  if(paste(sodium::pubkey(key_private), collapse = " ") == key_public) {


    #Unencrypt data and make it available elsewhere
    data_unencrypted <- unserialize(sodium::simple_decrypt(data_encrypted, key_private))

    # Extract tables using data_unencrypted
    LIST_tables = extract_tables(list_credentials = data_unencrypted, serial_parallel = "parallel") # ~7s

    DF_user = LIST_tables$user

    DF_table_clean = DF_user |>
      dplyr::group_by(id_protocol) |>
      dplyr::count(status) |>
      tidyr::pivot_wider(names_from = status, values_from = n) |>
      tidyr::replace_na(replace = list(completed = 0,
                                       discarded = 0,
                                       assigned = 0))

  }


  TABLE_clean = DF_table_clean |> gt::gt(groupname_col = NA)

  # Total online participants in MySQL DB
  TOTAL_participants =
    DF_table_clean |>
    dplyr::ungroup() |>
    dplyr::summarise(TOTAL_completed = sum(completed, na.rm = TRUE))

  OUTPUT = list(TABLE_clean = TABLE_clean,
                TOTAL_participants = TOTAL_participants)

  return(OUTPUT)


}
