#' run_remote_HelpeR
#'
#' @param protocol
#'
#' @returns
#' @export
#'
#' @examples
run_remote_HelpeR <- function(protocol) {
  # Used in sync_data_active_protocols.R

  cli::cli_h2(paste0("RUNNING jsPsychHelpeR", protocol, " (via callr)"))

  PROJECT_folder = paste0("~/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/SHARED-DEV/jsPsychHelpeR", protocol, "/")
  zip_name = here::here(paste0("../SHARED-data/", protocol, "/", protocol, ".zip"))

  # 1. Copy the input zip file
  file.copy(from = zip_name,
            to = paste0(PROJECT_folder, "data/", protocol, "/", basename(zip_name)),
            overwrite = TRUE)

  # 2. Run the script securely and synchronously (No setwd() or Sys.sleep() needed!)
  safe_run = purrr::safely(callr::rscript)(
    script = "run_remote.R", # In Josefina/jsPsychHelpeR[PID], is a tar_make()
    wd = PROJECT_folder,     # This handles the directory safely for just this process
    show = TRUE,             # Will print stdout/stderr to your cron log
    fail_on_status = TRUE
  )

  # 3. Check for execution errors
  if (!is.null(safe_run$error)) {
    cli::cli_alert_danger(paste0("Project ", protocol, " run_remote.R FAILED: {safe_run$error$message}"))

    # Log the error safely using cat() instead of system()
    cat(paste0("--------------- ", Sys.Date(), " ---------------\n",
               "Project ", protocol, " script failed.\n",
               safe_run$error$message, "\n\n"),
        file = paste0("~/Downloads/pid_", protocol, "_ERRORS.txt"),
        append = TRUE)

  } else {
    # 4. Copying output files ONLY if the script succeeded
    cli::cli_h1("COPYing output files")

    FILES = c("outputs/data/DF_analysis.csv",
              "outputs/data/DF_analysis_sp.csv",
              "outputs/data/DF_joined.csv",
              "outputs/data/DF_joined_sp.csv",
              paste0("outputs/reports/report_PROGRESS_", protocol, ".html"),
              "outputs/reports/report_DF_clean.html")

    DESTINATION = paste0("/home/emrys/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/SHARED-data/", protocol, "/")

    fs::dir_create(dirname(paste0(DESTINATION, FILES)))

    # Because we did NOT change the global working directory, we must add
    # PROJECT_folder to the files we want to copy FROM.
    FILES_FULL_PATH = paste0(PROJECT_folder, FILES)

    file.copy(from = FILES_FULL_PATH,
              to = paste0(DESTINATION, FILES),
              overwrite = TRUE)

    cli::cli_alert_success(paste0("Project ", protocol, " processed and files copied successfully."))
  }
}
