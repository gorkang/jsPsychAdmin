# Test function to avoid warning about jsPsychMaker when Checking project
TEST <- function() {
  jsPsychMaker::check_NEW_tasks_Github()
}


#' DELETE_data_server
#' Delete contents of data folder in the server: /.data/pid
#'
#' @param pid Protocol id
#'
#' @return
#' @export
#'
#' @examples
DELETE_data_server <- function(pid = NULL) {

  # CHECKS  ------------------------
  if (is.null(pid)) cli::cli_abort("pid needs a value")
  credentials_exist = file.exists(".vault/.credentials")
  SSHPASS = Sys.which("sshpass") # Check if sshpass is installed

  if (credentials_exist) {
    # sshpass installed
    if (SSHPASS != "") {
      # cli::cli_text(cli::col_green("{cli::symbol$tick} "), "`sshpass` and credentials exist")
    } else {
      cli::cli_abort("'sshpass' not installed")
    }
  } else {
    cli::cli_abort("Can't find server credentials in '.vault/.credentials'")
  }


  # DELETE ------------------------------------------------------------------

  list_credentials = source(".vault/.credentials") # Get server credentials
  folder_to_delete = paste0(pid, '/.data/')

  cli::cli_alert_info("Checking files in {.pkg https://cscn.uai.cl/lab/public/instruments/protocols/{folder_to_delete}}. This can take a while...")

  FILES_in_folder =
    suppressWarnings(
      system(paste0('sshpass -p ', list_credentials$value$password, ' ssh ', list_credentials$value$user, '@', list_credentials$value$IP, ' ls ', list_credentials$value$main_FOLDER, folder_to_delete), intern = TRUE)
    )

  # CHECK if folder .data exists
  if (!is.null(attr(FILES_in_folder, "status"))) {
    if (attr(FILES_in_folder, "status") == 2) cli::cli_abort("Folder '{folder_to_delete}' does NOT exist! Create it before continuing!")
  }


  if (length(FILES_in_folder) == 0) {

    cli::cli_alert_info("NO files found in `{.pkg {folder_to_delete}}`")

  } else {

    cli::cli_par()
    cli::cli_h1("PROCEED (?)")
    cli::cli_end()

    response_prompt = utils::menu(choices = c("Yes", "NO"),
                           title =
                             cli::cli(
                               {
                                 cli::cli_par()
                                 cli::cli_alert_info("{cli::style_bold((cli::col_red('DELETE')))} {length(FILES_in_folder)} files in {.pkg https://cscn.uai.cl/lab/public/instruments/protocols/{folder_to_delete}}? This CAN NOT be undone.")
                                 cli::cli_end()
                                 cli::cli_text("Files found: {.pkg {FILES_in_folder}}")
                                 }

                             )
                           )


    if (response_prompt == 1) {
      suppressWarnings(
        system(paste0('sshpass -p ', list_credentials$value$password, ' ssh ', list_credentials$value$user, '@', list_credentials$value$IP, ' rm ', list_credentials$value$main_FOLDER, folder_to_delete, '*'))
      )
      cli::cli_alert_success("{length(FILES_in_folder)} files in `{.pkg {folder_to_delete}}` DELETED")
    } else {
      cli::cli_alert_info("Nothing done")
    }

  }

}






#' CHECK_secrets_OK
#' Check .secrets_mysql.php file exists on CSCN server and writes a file in ~/Downloads
#'
#' @param path_to_secrets Location of the .secrets_mysql.php in the server
#' @param path_to_credentials Location of .vault/.credentials locally
#'
#' @return
#' @export
#'
#' @examples
CHECK_secrets_OK <- function(path_to_secrets = "../../../../../", path_to_credentials = "") {

  # CHECKS  ------------------------
  if (is.null(path_to_secrets)) cli::cli_abort("path_to_secrets needs a value")
  credentials_exist = file.exists(paste0(path_to_credentials, ".vault/.credentials"))
  SSHPASS = Sys.which("sshpass") # Check if sshpass is installed

  if (credentials_exist) {
    # sshpass installed
    if (SSHPASS != "") {
      # cli::cli_text(cli::col_green("{cli::symbol$tick} "), "`sshpass` and credentials exist")
    } else {
      cli::cli_abort("'sshpass' not installed")
    }
  } else {
    cli::cli_abort("Can't find server credentials in '.vault/.credentials'")
  }


  # CHECK ------------------------------------------------------------------

  list_credentials = source(paste0(path_to_credentials, ".vault/.credentials")) # Get server credentials
  file_to_check = paste0(path_to_secrets, '/.secrets_mysql.php')

  cli::cli_alert_info("Checking if Secrets file exists... This can take a while...")

  SECRET_response =
    suppressWarnings(
      system(
        paste0('sshpass -p ', list_credentials$value$password, ' ssh ', list_credentials$value$user, '@', list_credentials$value$IP, ' test -e ', list_credentials$value$main_FOLDER, file_to_check, ' && echo 1 || echo 0'),
        intern = TRUE)
    )

  if (SECRET_response == "0") {

    cli::cli_alert_danger("Secrets file NOT found")
    # system("notify-send 'Secrets file not found in CSCN server' 'A backup copy is in `jsPsychMaker/.vault/` For more information: https://gorkang.github.io/jsPsychR-manual/qmd/03-jsPsychMaker.html#online-offline-protocols'")
    system("printf 'A backup copy is in `jsPsychMaker/.vault/` For more information: https://gorkang.github.io/jsPsychR-manual/qmd/03-jsPsychMaker.html#online-offline-protocols'  >> ~/Downloads/Secrets_file_NOT_FOUND_in_CSCN_server.txt")

  } else {

    cli::cli_alert_success("Secrets file found")

    # system("notify-send 'Secrets file found in CSCN server' 'Daily script running fine'")
    system("printf 'Daily script running fine'  >> ~/Downloads/Secrets_file_found_in_CSCN_server.txt")
  }

}



#' rename_jsPsych_canonical
#'
#' @param canonical_protocol_helper
#'
#' @return renamed files
rename_jsPsych_canonical <- function(canonical_protocol_helper = "~/Downloads/jsPsychR_canonical") {

  # Rename all FILES so the filenames do not change
  FILES_IN = list.files(paste0(canonical_protocol_helper, "/data/999"), full.names = TRUE)
  FILES_OUT = gsub("[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{6}", "2222-02-22T222222", FILES_IN)
  file.rename(from = FILES_IN, FILES_OUT)


}





#' set_permissions_google_drive
#'
#' Changes permission in a google drive folder
#'
#' @param pid pid of project
#' @param email_IP email of Principal Researcher to give reading permissions to data in google drive
#'
#' @return NULL
#' @export
set_permissions_google_drive <- function(pid, email_IP) {

  googledrive::drive_auth("gorkang@gmail.com")

  ADMIN_emails = c("gorkang@gmail.com", "herman.valencia.13@sansano.usm.cl")

  # If email_IP is not that of an admin
  if (!email_IP %in% ADMIN_emails) {

    # Get all folders in SHARED-data
    SHARED_data_folder = googledrive::drive_ls(googledrive::as_id("1ZNiCILmpq_ZvjX0mkyhXM0M3IHJijJdL"), recursive = FALSE, type = "folder")

    # Get id of folder == pid
    ID = SHARED_data_folder |> dplyr::filter(name == pid) |> dplyr::pull(id)

    # Present permissions
    permissions_ID = ID |> googledrive::drive_reveal("permissions")
    list_permissions = permissions_ID$drive_resource[[1]]$permissions
    DF_permissions = 1:length(list_permissions) |>
      purrr::map_df(~{
        tibble::tibble(email = list_permissions[[.x]]$emailAddress,
                       role = list_permissions[[.x]]$role)
      })

    # IF email_IP does not already have permissions
    if (!email_IP %in% DF_permissions$email) {

      # Change permissions for email_IP
      ID |>
        googledrive::drive_share(
          role = "reader",
          type = "user",
          emailAddress = email_IP,
          emailMessage = paste0("La carpeta de datos del proyecto ", pid, " ha sido compartida contigo. Si es un error o tienes alguna duda, avisa a gorkang@gmail.com")
        )
      cli::cli_alert_success("Granted View permissions to {email_IP}")

      # email_IP already has permissions
    } else {
      cli::cli_alert_info("{email_IP} already has permissions")
    }

    # Admins
  } else {
    cli::cli_alert_info("{email_IP} is an ADMIN and already has permissions")
  }

}

