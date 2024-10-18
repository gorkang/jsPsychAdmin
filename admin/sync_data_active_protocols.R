# Sync and zip data folder of active protocols

  # - syncs server content (minus data) to CSCN-server
  # - CHECKS active folders: https://docs.google.com/spreadsheets/d/13xX8aGhKmfz8zVvNuCMDnS6L6Dy6T1NlA6nTOqZuErA/edit#gid=0
  # - ZIPS to jsPsychR/SHARED-data/
  # - Processes and zips DF_raw and DF_clean
  # - Individual project folders will be shared with the IP for each project


# If we need Google Drive authentication, run googlesheets4::gs4_auth("gorkang@gmail.com") in this file and in set_permissions_google_drive() in helper_functions_extra.R

########################################################################
################# THIS DOCUMENT RUNS DAILY via anacron #################
########################################################################

# Can check result of running this usind `sudo mail`
# After reading it, stays in /root/mbox



# FILE: /etc/cron.daily/gorka-sync_data_jspsychAdmin -----------------------
# ---------------------------------------------------------------------------

# #!/bin/sh
#
# # If started as root, then re-start as user "emrys":
# if [ "$(id -u)" -eq 0 ]; then
# exec sudo -H -u emrys $0 "$@"
# echo "This is never reached.";
# fi
#
# cd /home/emrys/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/jsPsychAdmin/admin/ && Rscript sync_data_active_protocols.R
#
# exit 0;

# END FILE /etc/cron.daily/gorka-sync_data_jspsychAdmin --------------------
# ---------------------------------------------------------------------------


# TO TEST THIS WILL WORK WHEN RUN DAILY:

  # sudo su
  # run-parts --verbose /etc/cron.daily # Run all anacron daily jobs

  # system("cd /home/emrys/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/jsPsychAdmin/admin/ && Rscript sync_data_active_protocols.R")




# Libreria mensajes -------------------------------------------------------

# https://ntfy.sh/jsPsychAdminNotifications
# https://github.com/jonocarroll/ntfy
if (!require('ntfy')) remotes::install_github("jonocarroll/ntfy"); library('ntfy')

# usethis::edit_r_environ()
# Add NTFY_TOPIC='jsPsychAdminNotifications'
# ntfy::ntfy_topic(var = "NTFY_TOPIC")



# CHECK last day run ------------------------------------------------------

  # Check if DB backup, canonical clean backup and data of active protocols did run today
  CHECK = jsPsychAdmin::CheckLastRun_sync_data_active_protocols(abort_if_done = TRUE)


# CHECK Secrets exist -----------------------------------------------------

  cli::cli_h1("CHECK secrets")

  # Checks the .secrets_mysql.php exists on CSCN server. Writes a file in ~/Downloads
  jsPsychAdmin::CHECK_secrets_OK(credentials_file = ".vault/.credentials")




# Save table with participants per condition -------------------------------

cli::cli_h1("Save table_participants.png")

# Run safely
check_status_participants_protocol_safely = purrr::safely(jsPsychAdmin::check_status_participants_protocol, quiet = FALSE)

OUTPUT_participants_table = check_status_participants_protocol_safely()
# OUTPUT_participants_table = jsPsychAdmin::check_status_participants_protocol()
# OUTPUT_participants_table = callr::r(func = function() jsPsychAdmin::check_status_participants_protocol(), show = TRUE)

if (!is.null(OUTPUT_participants_table$error)) {
  OUTPUT_participants_table$error
  ntfy::ntfy_send(
    paste0(
      Sys.Date(),
      ": ERROR en sync_data_active_protocols -> check_status_participants_protocol. ERROR:",
      OUTPUT_participants_table$error$message
    )
    )
} else {
  OUTPUT_participants_table$result$TABLE_clean |> gt::gtsave(here::here(paste0("outputs/", Sys.Date(), "_table_participants.png")))
}



# Sync CSCN-server --------------------------------------------------------

  # Syncs all protocols (without data)

  cli::cli_h1("SYNC CSCN-server")

  # https://cscn.uai.cl/lab/protocols/ to  ../CSCN-server/protocols/
  jsPsychHelpeR::sync_server_local(server_folder = "",
                                   local_folder = here::here(paste0("..", "/CSCN-server/protocols/")),
                                   direction = "server_to_local",
                                   only_test = FALSE,
                                   exclude_csv = TRUE, # DO NOT INCLUDE DATA
                                   delete_nonexistent = TRUE,
                                   ignore_existing = FALSE, # Important to overwrite files that already existed and changed
                                   dont_ask = TRUE)

  # https://cscn.uai.cl/lab/protocols_DEV/ to  ../CSCN-server/protocols_DEV/
  jsPsychHelpeR::sync_server_local(server_folder = "protocols_DEV/",
                                   local_folder = here::here(paste0("..", "/CSCN-server/protocols_DEV/")),
                                   direction = "server_to_local",
                                   only_test = FALSE,
                                   exclude_csv = TRUE, # DO NOT INCLUDE DATA
                                   delete_nonexistent = TRUE,
                                   ignore_existing = FALSE, # Important to overwrite files that already existed and changed
                                   dont_ask = TRUE)



  # from OLD PATH https://cscn.uai.cl/lab/public/instruments/protocols/ to  ../CSCN-server/protocols_old_path/
  jsPsychHelpeR::sync_server_local(server_folder = "",
                                   local_folder = here::here(paste0("..", "/CSCN-server/protocols_old_path/")),
                                   direction = "server_to_local",
                                   only_test = FALSE,
                                   exclude_csv = TRUE, # DO NOT INCLUDE DATA
                                   delete_nonexistent = TRUE,
                                   ignore_existing = FALSE, # Important to overwrite files that already existed and changed
                                   dont_ask = TRUE,
                                   credentials_file = here::here(".vault/.credentials_old_path"))




# Backup MySQL DB ---------------------------------------------------------

cli::cli_h1("BACKUP MySQL")

# Creates full backup of MySQL DB in user-cscn/apps/uai-cscn/DB_dumps/
jsPsychAdmin:::backup_MySQL_DB()

# Give it some time to finish the backup
Sys.sleep(30)

# Copy server MySQL backups to local folder
jsPsychHelpeR::sync_server_local(server_folder = "../../../DB_dumps/",
                                 local_folder = here::here(paste0("..", "/CSCN-server/DB_backups/")),
                                 direction = "server_to_local",
                                 only_test = FALSE,
                                 exclude_csv = TRUE, # DO NOT INCLUDE DATA
                                 delete_nonexistent = TRUE,
                                 ignore_existing = FALSE, # Important to overwrite files that already existed and changed
                                 dont_ask = TRUE)



# Copy canonical_clean: Github -> SERVER ------------------------------

cli::cli_h1("BACKUP canonical_clean_6")

# Copies canonical_clean_6 Github to the server
# This SHOULD BE THE ONLY WAY WE UPDATE THE SERVER canonical_clean

jsPsychAdmin::copy_canonical_clean_from_Github_to_server(jsPsych_version = 6, silent = TRUE)




# Sources and parameters --------------------------------------------------

cli::cli_h1("PROCESS all active protocols")


output_formats = c("csv", "csv2") # csv2 for Spanish locale csv


# GET google sheet --------------------------------------------------------

google_sheet_ID = "1eE0xrk_DGIOShhWjqKaKhk0NIeb-7k0eoFG93822-Ho"
cli::cli_h1("Reading https://docs.google.com/spreadsheets/d/{google_sheet_ID}/edit#gid=0")
googlesheets4::gs4_auth("gorkang@gmail.com")
googlesheets4::local_gs4_quiet() # No googlesheets4::read_sheet messages

DF_resumen_ALL = googlesheets4::read_sheet(google_sheet_ID, sheet = 1, skip = 0)

DF_resumen_clean =
  DF_resumen_ALL |>
  # dplyr::filter(STATUS == "Running") |>
  dplyr::filter(grepl("Running", STATUS)) |>
  dplyr::select(ID, contacto) |>
  dplyr::mutate(ID = unlist(ID))

PIDs =
  DF_resumen_clean |>
  dplyr::pull(ID)


# Download and zip --------------------------------------------------------

1:length(PIDs) |>
  purrr::walk( ~ {

    # From pid 38 onward, use the credentials pointing to the new path in the folder
    if (PIDs[.x] > 37) {
      credentials_file = here::here(".vault/.credentials")
    } else {
      credentials_file = here::here(".vault/.credentials_old_path")
    }


    # .x = 1
    cli::cli_h1("Project {PIDs[.x]}")

    # SAVE PID.csv
    cli::cli_h2("Save project's details")
    destination = here::here(paste0("../SHARED-data/", PIDs[.x], "/"))
    if (!dir.exists(destination)) dir.create(destination)
    readr::write_csv2(OUTPUT_participants_table$result$STATUS_BY_CONDITION |> dplyr::filter(id_protocol == PIDs[.x]),
                     paste0(destination, PIDs[.x], "_progress.csv"))


    # Clean outputs/data/
    cli::cli_h2("Clean up outputs/data")

    # Make sure folder exists and extract jsPsychHelpeR.zip there
    if (!dir.exists("outputs/data/")) dir.create("outputs/data/", recursive = TRUE)
    FILES = list.files(here::here("outputs/data/"), full.names = TRUE, pattern = "DF_clean|DF_raw")
    file.remove(FILES)
    Sys.sleep(5) # Give some time to sync changes to google drive

    # Downloads data and ADDS to the zip data
    cli::cli_h2("Downloading data")

    # Tempdir to unzip and get files
    OUTPUT_folder = paste0(tempdir(), "/ZIP", PIDs[.x])

    # Try to get the zip name
    zip_name = here::here(paste0("../SHARED-data/", PIDs[.x], "/", PIDs[.x], ".zip"))

    # Check if it exists and unzip to tempdir
    if (file.exists(zip_name)) {
      utils::unzip(zip_name, overwrite = TRUE, exdir = OUTPUT_folder, setTimes = TRUE)
      zip_info_0 = file.info(zip_name)
    } else {
      zip_info_0 = NULL
    }

    # Sync files to tempdir. We use tempdir_location = OUTPUT_folder so only new files will be downloaded
    jsPsychHelpeR::get_zip(
      pid = PIDs[.x],
      what = "data",
      ignore_existing = TRUE,
      all_messages = FALSE,
      tempdir_location = OUTPUT_folder,
      credentials_file = credentials_file
    )

    # If case the zip did not exist before, now it should (if they were files)
    if (!file.exists(zip_name)) zip_name = here::here(paste0("../SHARED-data/", PIDs[.x], "/", PIDs[.x], ".zip"))

    # Get info of zip file after synching
    zip_info_1 = file.info(zip_name)


    # Read ZIP and process data
    if (file.exists(zip_name)) {

      # Only process data if there is new data
      if (!identical(zip_info_0$size, zip_info_1$size)) {

        # Process data (DF_raw and DF_clean)
        cli::cli_h2("Processing data for project {PIDs[.x]}")

        read_data_safely = purrr::quietly(purrr::safely(jsPsychHelpeR::read_data))

        DF_raw = read_data_safely(input_files = zip_name)

        # If there are WARNINGS, show alert and store in file
        if (length(DF_raw$warnings) > 0) {
          cli::cli_alert_danger("{length(DF_raw$warnings)} warnings in pid = {PIDs[.x]} \n\n {DF_raw$warnings}")
          clean_WARNING = gsub("\\'", "", DF_raw$warnings)
          WARNING_string = glue::glue("--------------- {Sys.Date()} ---------------\n\n{length(DF_raw$warnings)} warnings in pid = {PIDs[.x]} \n\n {clean_WARNING}\n\n\n")
          system(paste0("printf '%s\n' '", WARNING_string, "'  >> ~/Downloads/pid_", PIDs[.x], "_", length(DF_raw$warnings), "_warnings.txt"))
        }

        if (is.null(DF_raw$result$error)) {

          create_clean_data_safely = purrr::quietly(purrr::safely(jsPsychHelpeR::create_clean_data))

          DF_clean = create_clean_data_safely(DF_raw$result$result)

          if (is.null(DF_clean$result$error)){

            # Copy processed files to destination folder
            cli::cli_h2("Copy output processed files for project {PIDs[.x]}")

            destination = paste0(dirname(zip_name), "/processed/")
            if (!dir.exists(destination)) dir.create(destination)

            # No need to do this, we directly create the zip in the next step
            # FILES_processed = list.files(here::here("outputs/data/"), full.names = TRUE, pattern = "DF_clean|DF_raw")
            # file.copy(from = FILES_processed, to = paste0(destination, basename(FILES_processed)), overwrite = TRUE)
            # file.remove(FILES_processed)

            # Create zip with process data
            jsPsychHelpeR::zip_files(folder_files = here::here("outputs/data/"),
                      zip_name = paste0(destination, "", "processed.zip"),
                      remove_files = FALSE)
          } else {
            # If there are ERRORS, show alert and store in file
            cli::cli_alert_danger("{length(DF_clean$result$error$message)} ERRORS in pid = {PIDs[.x]} \n\n {DF_clean$result$error}")
            clean_ERROR = gsub("\\'", "", DF_clean$result$error$message)
            ERROR_string = glue::glue("--------------- {Sys.Date()} ---------------\n\n{length(DF_raw$warnings)} ERROR in pid = {PIDs[.x]} \n\n {clean_ERROR}\n\n\n")
            system(paste0("printf '%s\n' '", ERROR_string, "'  >> ~/Downloads/pid_", PIDs[.x], "_", length(DF_clean$result$error), "_ERRORS.txt"))

          }

        }
      }
    }

  })



# PERMISOS ----------------------------------------------------------------

# TODO: FOR NOW, do this manually. Make sure all emails are OK

# DF_resumen_clean
# EMAIL = "name-surname@university.edu.com"
# grepl(pattern = "\\b[-A-Za-z0-9_.%]+\\@[-A-Za-z0-9_.%]+\\.[A-Za-z]+", EMAIL)
# grepl(pattern = "^[[:alnum:].-_]+@[[:alnum:].-]+$", EMAIL)


cli::cli_h1("CHECK permissions")

set_permissions_google_drive_safely = purrr::quietly(purrr::safely(jsPsychAdmin::set_permissions_google_drive))

1:length(PIDs) |>
  purrr::walk( ~ {

    # cli::cli_h3("Check permissions for pid: {PIDs[.x]}")

    DF_permisos = DF_resumen_clean |> dplyr::filter(ID == PIDs[.x])

    IS_EMAIL_regex = "\\b[-A-Za-z0-9_.%]+\\@[-A-Za-z0-9_.%]+\\.[A-Za-z]+"

    # CHECK if contacto looks like a single well formed email
    if (grepl(pattern = IS_EMAIL_regex, DF_permisos$contacto)) {

      # TODO: Use safer/quieter version of functions and check if errors or warnings
      # Set permissions, only if not ADMIN and does not already have permissions
      # jsPsychAdmin::set_permissions_google_drive(pid = DF_permisos$ID, email_IP = trimws(DF_permisos$contacto))
      OUT = set_permissions_google_drive_safely(pid = DF_permisos$ID, email_IP = trimws(DF_permisos$contacto))

      if (!is.null(OUT$result$error)) {

        # If there are ERRORS, show alert and store in file
        cli::cli_alert_danger("ERROR in pid {DF_permisos$ID}: {DF_permisos$contacto} {OUT$result$error}")
        clean_ERROR = gsub("\\'", "", OUT$result$error)
        ERROR_string = glue::glue("--------------- {Sys.Date()} ---------------\n\n{length(OUT$warnings)} ERROR in pid {DF_permisos$ID}: {DF_permisos$contacto} \n\n {clean_ERROR}\n\n\n")
        system(paste0("printf '%s\n' '", ERROR_string, "'  >> ~/Downloads/pid_", PIDs[.x], "_", length(OUT$result$error), "_ERRORS_permissions.txt"))

      }
      if (length(OUT$warnings) != 0) cli::cli_alert_warning(OUT$warnings)
      if (!is.null(OUT$messages)) cli::cli_alert_info(OUT$messages)


    } else {
      cli::cli_alert_danger("pid {PIDs[.x]}: {DF_permisos$contacto} does NOT look like a proper email")
    }

  })


cli::cli_h1("END of sync_data_active_protocols.R")




# Mensaje end -------------------------------------------------------------


# system('curl -d "Message from R" ntfy.sh/jsPsychAdminNotifications')
ntfy::ntfy_send(paste0(Sys.Date(), ": Daily sync_data_active_protocols finished!"))

