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
# sudo run-parts --verbose /etc/cron.daily # Run all anacron daily jobs
# system("cd /home/emrys/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/jsPsychAdmin/admin/ && Rscript sync_data_active_protocols.R")



# CHECK Secrets exist -----------------------------------------------------

# Checks the .secrets_mysql.php exists on CSCN server. Writes a file in ~/Downloads
# source(here::here("admin/helper-scripts-admin.R"))
jsPsychAdmin::CHECK_secrets_OK(path_to_credentials = "/home/emrys/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/jsPsychHelpeR/")



# Sync CSCN-server --------------------------------------------------------

# Syncs all protocols without data from https://cscn.uai.cl/lab/public/instruments/protocols/ to  ../CSCN-server/
jsPsychHelpeR::sync_server_local(server_folder = "",
                                 local_folder = here::here(paste0("..", "/CSCN-server/protocols/")),
                                 direction = "server_to_local",
                                 only_test = FALSE,
                                 exclude_csv = TRUE, # DO NOT INCLUDE DATA
                                 delete_nonexistent = TRUE,
                                 dont_ask = TRUE)


# Sources and parameters --------------------------------------------------

output_formats = c("csv", "csv2") # csv2 for Spanish locale csv


# suppressPackageStartupMessages(source(here::here("_targets_packages.R")))
# invisible(lapply(list.files(here::here("./R"), full.names = TRUE, pattern = ".R$"), source))

# source(here::here("R/helper_functions.R"))
# source(here::here("R/sync_server_local.R"))

google_sheet_ID = "1eE0xrk_DGIOShhWjqKaKhk0NIeb-7k0eoFG93822-Ho"
cli::cli_h1("Reading https://docs.google.com/spreadsheets/d/{google_sheet_ID}/edit#gid=0")
googlesheets4::gs4_auth("gorkang@gmail.com")
googlesheets4::local_gs4_quiet() # No googlesheets4::read_sheet messages



# GET google sheet --------------------------------------------------------

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

    # .x=1
    cli::cli_h1("Project {PIDs[.x]}")

    # Clean outputs/data/
    cli::cli_h2("Clean up outputs/data")
    # Make sure folder exists and extract jsPsychHelpeR.zip there
    if (!dir.exists("outputs/data/")) dir.create("outputs/data/", recursive = TRUE)
    FILES = list.files(here::here("outputs/data/"), full.names = TRUE, pattern = "DF_clean|DF_raw")
    file.remove(FILES)
    Sys.sleep(5) # Give some time to sync changes to google drive

    # Download data and ADDS to the zip data
    cli::cli_h2("Downloading data for project {PIDs[.x]}")
    jsPsychHelpeR::get_zip(pid = PIDs[.x], what = "data")

    # Read ZIP and process data
    zip_name = here::here(paste0("../SHARED-data/", PIDs[.x], "/", PIDs[.x], ".zip"))


    if (file.exists(zip_name)) {

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
          FILES_processed = list.files(here::here("outputs/data/"), full.names = TRUE, pattern = "DF_clean|DF_raw")
          destination = paste0(dirname(zip_name), "/processed/")
          if (!dir.exists(destination)) dir.create(destination)
          file.copy(from = FILES_processed, to = paste0(destination, basename(FILES_processed)), overwrite = TRUE)
          file.remove(FILES_processed)

          # Create zip with process data
          jsPsychHelpeR::zip_files(folder_files = destination,
                    zip_name = paste0(destination, "", "processed.zip"),
                    remove_files = TRUE)
        } else {
          # If there are ERRORS, show alert and store in file
          cli::cli_alert_danger("{length(DF_clean$result$error$message)} ERRORS in pid = {PIDs[.x]} \n\n {DF_clean$result$error}")
          clean_ERROR = gsub("\\'", "", DF_clean$result$error$message)
          ERROR_string = glue::glue("--------------- {Sys.Date()} ---------------\n\n{length(DF_raw$warnings)} ERROR in pid = {PIDs[.x]} \n\n {clean_ERROR}\n\n\n")
          system(paste0("printf '%s\n' '", ERROR_string, "'  >> ~/Downloads/pid_", PIDs[.x], "_", length(DF_clean$result$error), "_ERRORS.txt"))

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

1:length(PIDs) |>
  purrr::walk( ~ {

    cli::cli_h3("Check permissions for pid: {PIDs[.x]}")

    DF_permisos = DF_resumen_clean |> dplyr::filter(ID == PIDs[.x])

    IS_EMAIL_regex = "\\b[-A-Za-z0-9_.%]+\\@[-A-Za-z0-9_.%]+\\.[A-Za-z]+"

    # CHECK if contacto looks like a single well formed email
    if (grepl(pattern = IS_EMAIL_regex, DF_permisos$contacto)) {

      # TODO: Use safer/quieter version of functions and check if errors or warnings
      # Set permissions, only if not ADMIN and does not already have permissions
      jsPsychAdmin::set_permissions_google_drive(pid = DF_permisos$ID, email_IP = DF_permisos$contacto)

    } else {
      cli::cli_alert_danger("pid {PIDs[.x]}: {DF_permisos$contacto} does NOT look like a proper email")
    }

  })
