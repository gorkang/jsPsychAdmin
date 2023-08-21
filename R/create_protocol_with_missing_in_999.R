#' create_protocol_with_missing_in_999
#'
#' @param search_where One of prepare_TASK or js: looks for tasks without results in 999.zip in jsPsychHelpeR/R_tasks/ or in /jsPsychMaker/protocols_DEV/
#' @param destination_folder Location of new protocol
#'
#' @return creates a protocol
#' @export
create_protocol_with_missing_in_999 <- function(search_where = "prepare_TASK", destination_folder = paste0(tempdir(check = TRUE), "/Missing999")) {

  # destination_folder = "~/Downloads/XXX"

  cli::cli_alert_info("Loading necessary packages")
  # suppressPackageStartupMessages(targets::tar_load_globals())

  # We can find csv missing when we have the prepare_TASK.R script or
  # csv missing when we have the tasks/TASK.js script
  if (!search_where %in% c("prepare_TASK", "js")) cli::cli_abort('ONE OF "prepare_TASK", "js"')




  # READ all files ----------------------------------------------------------

  cli::cli_alert_info("Read all `999.zip`, `jsPsychMaker/protocols_DEV/.js` and `R_tasks/prepare_*.R` files")

  # Read csv's in 999.zip
  input_files = system.file("extdata", "999.zip", package = "jsPsychHelpeR")
  files = jsPsychHelpeR::read_zips(input_files) |> dplyr::distinct(procedure) |> dplyr::pull(procedure)

  # Read all .js tasks in jsPsychMaker/protocols_DEV/
  JS_missing_CSV =
    list.files("../jsPsychMaker/protocols_DEV/", pattern = "js$", recursive = TRUE) |> tibble::as_tibble() |>
    dplyr::filter(grepl("*tasks/.*\\.js", value)) |>
    dplyr::mutate(task = gsub("\\.js", "", basename(value))) |>
    dplyr::filter(!task %in% files) |>
    dplyr::filter(!task %in% c("TEMPLATE", "TEMPLATE_OLD")) |> dplyr::pull(task)

  # Read all prepare_TASK in jsPSychHelpeR/R_tasks/
  TASKS_missing_CSV =
    list.files("../jsPsychHelpeR/R_tasks/") |> tibble::as_tibble() |>
    dplyr::mutate(task = gsub("prepare_(.*)\\.R", "\\1", value)) |>
    dplyr::filter(!task %in% files & !grepl("\\.csv", value)) |>
    dplyr::filter(!task %in% c("TEMPLATE", "TEMPLATE_OLD")) |> dplyr::pull(task)

  if (search_where == "prepare_TASK") {
    NEW_TASKS = paste0(TASKS_missing_CSV, ".js")
  } else {
    NEW_TASKS = paste0(JS_missing_CSV, ".js")
  }


  # Remove TASKS ***
  # DEMOGR[N] and FORM[N] # Idiosyncratic tasks
  # SCGT uses mic (mic not available in docker container browser)
  blacklist_tasks = "^DEMOGR|^FORM[0-9]{1,3}|^SCGT|^PPD"
  cli::cli_alert_info("Not including tasks (e.g. SCGT uses mic): {blacklist_tasks}")
  NEW_TASKS = NEW_TASKS[!grepl(blacklist_tasks, NEW_TASKS)]


  # Get last version from SERVER --------------------------------------------

  # Download to ../CSCN-server/
  DF_missing = jsPsychAdmin::check_missing_prepare_TASK(sync_protocols = TRUE, gmail_account = "gorkang@gmail.com", dont_ask = TRUE)
  # DF_missing


  # COPY a clean protocol and the new tasks to NEW_TASKS --------------------

  cli::cli_alert_info("Create new protocol in /CSCN-server/")

  ALL_js =
    list.files("../CSCN-server/", recursive = TRUE, pattern = "\\.js") |> tibble::as_tibble() |>
    dplyr::filter(!grepl("NEW_TASKS", value)) |> # Do not look into NEW_TASKS to avoid circularity
    dplyr::filter(grepl("*tasks/.*\\.js", value)) |>
    dplyr::mutate(task_name = basename(value)) |>
    dplyr::mutate(mtime = file.info(paste0("../CSCN-server/", value))$mtime,
                  size = file.info(paste0("../CSCN-server/", value))$size)

  # DT::datatable(ALL_js)

  # Select newer versions of tasks
  PATHS_NEW_TASKS =
    ALL_js |>
    dplyr::filter(task_name %in% NEW_TASKS) |>
    dplyr::group_by(task_name) |> dplyr::filter(mtime == max(mtime)) |>
    dplyr::distinct(task_name, .keep_all = TRUE) |>
    dplyr::arrange(task_name) |>
    dplyr::pull(value)



  # DELETE OLD NEW_TASKS
  unlink(destination_folder, recursive = TRUE)
  cli::cli_alert_info("Deleted {destination_folder}")

  # copy_canonical_clean/
  jsPsychMaker::list_unzip(location = "jsPsychMaker", zip_file = "canonical_protocol_clean.zip",
                           action = "unzip", destination_folder = destination_folder, silent = TRUE)

  # Remove non essential tasks from canonical_clean
  TASKS_CLEAN = list.files(paste0(destination_folder, "/tasks/"))
  file.remove(paste0(destination_folder, "/tasks/", TASKS_CLEAN[!TASKS_CLEAN %in% c("Consent.js", "Goodbye.js")]))

  # Copy NEW tasks
  # dir.create(paste0(destination_folder, "tasks/"), recursive = TRUE)
  file.copy(paste0("../CSCN-server/", PATHS_NEW_TASKS), paste0(destination_folder, "/tasks/", basename(PATHS_NEW_TASKS)), overwrite = TRUE)


  # INCLUDE NEW TASKS IN config.js -----------------------------------

  TASKS_NEW_PROTOCOL = jsPsychMaker::extract_tasks_from_protocol(destination_folder)

  jsPsychMaker::update_config_js(folder_protocol = destination_folder,
                                 tasks = TASKS_NEW_PROTOCOL,
                                 block_tasks = "randomly_ordered_tasks_1")

  cli::cli_alert_success("ALL DONE \nProtocol in `{destination_folder}` \nRemember to CHECK config.js")

}
