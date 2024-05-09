get_table <- function(table_name, con) {

  TABLE <- dplyr::tbl(src = con, table_name) |> dplyr::as_tibble()
  cli::cli_progress_update(.envir = .GlobalEnv)

  return(TABLE)
}



# Called in parallel in mysql_extract_tables()
get_table_parallel <- function(table_name, DB_credentials) {

  con = openDBconnection(DB_credentials)

  TABLE <- dplyr::tbl(src = con, table_name) |> dplyr::as_tibble()

  DBI::dbDisconnect(con)

  return(TABLE)
}



openDBconnection <- function(DB_credentials, Driver = "MySQL ODBC 8.1 Unicode Driver") {

  drivers_available = odbc::odbcListDrivers()$name |> unique()
  Driver_DB_credentials = DB_credentials$value$Driver

  if (!Driver_DB_credentials %in% drivers_available) {

    cli::cli_alert_danger("{.code {Driver_DB_credentials}} not found in this computer, using {.code {Driver}} instead")
    Driver_DB_credentials = Driver

  }

  con <- DBI::dbConnect(odbc::odbc(),
                        Driver = Driver_DB_credentials,
                        host = DB_credentials$value$host,
                        port = DB_credentials$value$port,
                        UID = DB_credentials$value$UID,
                        PWD = DB_credentials$value$PWD,
                        Database = DB_credentials$value$Database
  )

  return(con)

}




check_start_ssh_tunnel <- function(list_credentials) {


  start_ssh_tunnel <- function(list_credentials) {

    ssh_cscn <- function(list_credentials) {
      system(paste0("sshpass -p ", list_credentials$value$password, " ssh -tt -o StrictHostKeyChecking=no ", list_credentials$value$user, "@", list_credentials$value$IP, " -L 3308:127.0.0.1:3306"))
    }

    ssh_tunnel =  callr::r_bg(func = ssh_cscn, args = list(list_credentials))

    return(ssh_tunnel)
  }

  start_ssh_tunnel_safely = purrr::safely(start_ssh_tunnel)


  ssh_tunnel = start_ssh_tunnel_safely(list_credentials)
  # ssh_tunnel$result$kill()

  OUTPUT = ssh_tunnel$result$read_output_lines()

  # Need to stop until ssh connection is completed
  while (!grepl("Welcome to Ubuntu", OUTPUT[1])) {
    Sys.sleep(.5)
    OUTPUT = ssh_tunnel$result$read_output_lines()
    if (!is.na(OUTPUT[1])) cli::cli_alert_info(OUTPUT[1])
  }
  # ssh_tunnel$result$get_status()

  if (!exists("ssh_tunnel")) {

    cli::cli_alert_info("Opening ssh_tunnel")
    ssh_tunnel = start_ssh_tunnel_safely(list_credentials)

  } else {

    if (!is.null(ssh_tunnel$result$get_exit_status())) {
      cli::cli_alert_info("Re-opening ssh_tunnel")
      ssh_tunnel = start_ssh_tunnel_safely(list_credentials)
    }
    cli::cli_alert_success("ssh_tunnel open")

  }

  return(ssh_tunnel)
}





add_pwd_for_pid_data <- function(pid) {

  # DEBUG
  # pid = 22

  mysupersecretpassword = rstudioapi::askForPassword("password to decrypt and re-encrypt data")


  # INFORMATION FOR MAIN ENCRYPTED CREDENTIALS -------------------------------
  DATA_unencrypted = decrypt_data(key_public =  readLines(".vault/data_public_key.txt"),
                                  data_encrypted = ".vault/data_encrypted.rds",
                                  mysupersecretpassword = mysupersecretpassword)



  # ADD USER ----------------------------------------------------------------

  NEW_PASSWORD = rstudioapi::askForPassword(prompt = glue::glue("Password for project {pid} DATA"))

  # ADD to main file
  NEW_VAR = paste0("password_pid_", pid)
  DATA_unencrypted$value[[NEW_VAR]] = NEW_PASSWORD
  # DATA_unencrypted$value$password = ""


  file.copy(from = ".vault/data_encrypted.rds",
            to = ".vault/data_encrypted_CS.rds")

  encrypt_data(data_unencrypted = DATA_unencrypted,
               output_name = "data",
               mysupersecretpassword = mysupersecretpassword)


  # Create new file for pid -------------------------------------------------

  # This will have a specific password just for this pid
  DATA_unencrypted_NEW = list()
  DATA_unencrypted_NEW$value[[NEW_VAR]] = NEW_PASSWORD

  encrypt_data(data_unencrypted = DATA_unencrypted_NEW,
               output_name = pid,
               mysupersecretpassword = NEW_PASSWORD)



}


encrypt_data <- function(mysupersecretpassword = NULL, data_unencrypted, output_name) {

  if (grepl("\\.|\\/", output_name)) cli::cli_abort("output_name must NOT be a file name. Use a simple string as: 'passwords'")


  #Your password
  # mysupersecretpassword <- "dfsdf"
  if (is.null(mysupersecretpassword)) mysupersecretpassword = rstudioapi::askForPassword("password to encrypt data")

  #Your data
  # data_unencrypted <- data.frame(id = seq(1:10))

  #Private key
  key_private <- sodium::sha256(charToRaw(mysupersecretpassword))
  # paste("Private Key:", paste(key_private, collapse = " "))

  #Public key
  key_public  <- sodium::pubkey(key_private)
  public_print = paste(key_public, collapse = " ")
  output_public_key = paste0(".vault/", output_name, "_public_key.txt")

  cli::cli_h1("Public key")
  cli::cli_alert_info(public_print)
  cli::cli_alert_success("Storing public key in {output_public_key}")


  writeLines(public_print, output_public_key)



  #Encrypt data
  data_encrypted <- sodium::simple_encrypt(serialize(data_unencrypted, NULL), key_public)

  #Save data
  # saveRDS(data_encrypted, "data_encrypted.rds")
  output_name = paste0(".vault/", output_name, "_encrypted.rds")
  saveRDS(data_encrypted, output_name)
  cli::cli_alert_success("Encrypted file stored in {output_name}")

  #Cleanup
  rm(list=ls())

}


decrypt_data <- function(key_public, data_encrypted, mysupersecretpassword = NULL) {

  if (grepl("\\.|\\/", key_public)) cli::cli_abort("key_public must NOT be a file name. Use readLines(), for example: readLines('{key_public}')")
  if (is.null(mysupersecretpassword)) mysupersecretpassword = rstudioapi::askForPassword("password to decrypt data")

  data_encrypted = readRDS(data_encrypted)

  #Private key
  key_private <- sodium::sha256(charToRaw(mysupersecretpassword))

  #Check if private key provided is correct
  if(paste(sodium::pubkey(key_private), collapse = " ") == key_public) {

    cli::cli_alert_success("Correct password")

    #Unencrypt data and make it available elsewhere
    data_unencrypted <- unserialize(sodium::simple_decrypt(data_encrypted, key_private))

  } else {

    cli::cli_abort("Wrong password")

  }

  return(data_unencrypted)
  rm(list = c("key_public", "data_encrypted", "data_unencrypted", "key_private"))

}



delete_MySQL_tables_pid <- function(pid) {

  # pid = 999

  out <- utils::menu(c("yes", "no"), title = glue::glue("{cli::col_red('DELETE')} MySQL tables for pid {pid}?"))

  if (out == 1) {

    DB_credentials = decrypt_data(key_public = readLines(".vault/data_public_key.txt"), data_encrypted = ".vault/data_encrypted.rds", mysupersecretpassword = rstudioapi::askForPassword(prompt = "Enter the SERVER password"))

    cli::cli_h1("Connecting to Mysql DB")
    ssh_tunnel = check_start_ssh_tunnel(list_credentials = DB_credentials)
    # PID_ssh_tunnel = ssh_tunnel$result$get_pid()

    # Connect to mysql DB
    db_con = openDBconnection(DB_credentials = DB_credentials)

    cli::cli_h1("DELETE all tables for pid {pid}")

    # SET pid
    DBI::dbGetQuery(db_con, sprintf(paste0("SET @PID = ", pid, ";")))

    # Selects
    # DBI::dbGetQuery(db_con, sprintf("SELECT * FROM db001_cscn.experimental_condition where id_protocol=@PID;"))
    # DBI::dbGetQuery(db_con, sprintf("SELECT * from task where id_protocol=@PID;"))

    # DELETE
    DBI::dbGetQuery(db_con, sprintf("delete from experimental_condition where id_protocol=@PID;"))
    DBI::dbGetQuery(db_con, sprintf("delete from user where id_protocol=@PID;"))
    DBI::dbGetQuery(db_con, sprintf("delete from user_condition where id_protocol=@PID;"))
    DBI::dbGetQuery(db_con, sprintf("delete from user_task where id_protocol=@PID;"))
    DBI::dbGetQuery(db_con, sprintf("delete from task where id_protocol=@PID;"))
    DBI::dbGetQuery(db_con, sprintf("delete from protocol where id_protocol=@PID;"))
    DBI::dbGetQuery(db_con, sprintf("delete from combination_between where id_protocol=@PID;"))

    cli::cli_alert_success("Tables deleted for pid {pid}")

    DBI::dbDisconnect(db_con)
    if (exists("ssh_tunnel")) ssh_tunnel$result$kill()
    cli::cli_alert_info("Disconnected from DB")


  } else {
    cli::cli_alert_info("Nothing done")
  }

}



backup_MySQL_DB <- function() {

  list_credentials = source(here::here(".vault/.credentials"))

  DB_credentials = decrypt_data(key_public = readLines(here::here(".vault/data_public_key.txt")),
                                data_encrypted = here::here(".vault/data_encrypted.rds"),
                                mysupersecretpassword = list_credentials$value$password)

  output_file = paste0('apps/uai-cscn/DB_dumps/', Sys.Date(), '_backupDB.sql.gz')

  prepare_backup_command <- function(DB_credentials, output_file) {

    # Prepare commands
    Connect_command = paste0("sshpass -p ", DB_credentials$value$password, " ssh -tt -o StrictHostKeyChecking=no ", DB_credentials$value$user, "@", DB_credentials$value$IP, " -L 3308:127.0.0.1:3306")

    DB_command = paste0('mysqldump  --host=localhost --default-character-set=utf8 --user=', DB_credentials$value$UID, ' --password=', DB_credentials$value$PWD, '  --no-tablespaces --protocol=tcp --single-transaction=TRUE --routines --events "db001_cscn" | gzip -9 > ', output_file)

# Connect to server and run backup
# **These lines need to be completely to the left**
system(paste0(Connect_command, " << EOF
", DB_command, ";
EOF
"))
# *** ***

  }

  # Run in background
  ssh_tunnel =  callr::r_bg(func = prepare_backup_command, args = list(DB_credentials, output_file))

  cli::cli_alert_info("MySQL backup: {.code {output_file}}")
  # After 60s, kill bg process
  # Sys.sleep(60)
  # ssh_tunnel$kill()

}
