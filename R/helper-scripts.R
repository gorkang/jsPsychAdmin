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

  # CHECKS  ---
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


  # DELETE ---

  list_credentials = source(".vault/.credentials") # Get server credentials
  folder_to_delete = paste0(pid, '/.data/')
  FOLDER_server = gsub("/srv/users/user-cscn/apps/uai-cscn/public/", "", list_credentials$value$main_FOLDER)

  cli::cli_alert_info("Checking files in {.pkg https://cscn.uai.cl/{FOLDER_server}{folder_to_delete}}. This can take a while...")

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

  # CHECKS  ---
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


  # CHECK ---

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

    # CHECK
    if (!is.list(permissions_ID$drive_resource) | !length(permissions_ID$drive_resource) >= 1) {
      cli::cli_alert_danger("permissions_ID$drive_resource is not a list OR not length >=1. SAVED file to DEBUG: DEBUG_permissions_ID.rds")
      str(permissions_ID$drive_resource)
      saveRDS(permissions_ID, "DEBUG_permissions_ID.rds")
      # permissions_ID$permissions_resource # MAYBE SHOULD USE THIS? INSTEAD OF: permissions_ID$drive_resource[[1]]$permissions
      # list_permissions = permissions_ID$permissions_resource
      # list_permissions[[1]]$permissions[[1]]$emailAddress
      # list_permissions[[1]]$permissions[[1]]$role
    }

    list_permissions = permissions_ID$drive_resource[[1]]$permissions

    DF_permissions = 1:length(list_permissions) |>
      purrr::map_df(~{
        tibble::tibble(email = list_permissions[[.x]]$emailAddress,
                       role = list_permissions[[.x]]$role)
      })

    # IF email_IP does not already have permissions
    if (!email_IP %in% DF_permissions$email) {

      # Change permissions for email_IP
      googledrive::drive_share(
        file = ID,
        role = "reader",
        type = "user",
        emailAddress = email_IP,
        emailMessage = paste0("La carpeta de datos del proyecto ", pid, " ha sido compartida contigo. Si es un error o tienes alguna duda, puedes escribir a gorkang@gmail.com")
        )
      cli::cli_alert_success("pid {pid}: {.email {email_IP}} | Granted View permissions")

      # email_IP already has permissions
    } else {
      cli::cli_alert_info("pid {pid}: {.email {email_IP}} | Already has View permissions")
    }

    # Admins
  } else {
    cli::cli_alert_info("pid {pid}: {.email {email_IP}} | Already has View permissions (ADMIN)")
  }

}


#' simulate_prepare_template
#' Simulate and prepare data for a jsPsychMaker folder protocol (or just create the code)
#'
#' @param folder_protocol jsPsychMaker folder protocol
#' @param n_participants Number of participants to simulate
#' @param print_watch_run print or run the code
#' @param sleep_before_running number of seconds to sleep before running the code
#'
#' @return Will print the jsPsychMonkeys and jsPsychHelpeR commands
#' @export
simulate_prepare <- function(folder_protocol = NULL, n_participants = 100, print_watch_run = "print", sleep_before_running = 3) {

  # folder_protocol = "~/Downloads/new_protocol_999/"
  # n_participants = 100

  pid = stringi::stri_extract_all(basename(folder_protocol), regex = "[0-9]{1,5}")[[1]]

  if (length(pid) > 1) cli::cli_abort("Multiple numbers found in folder {.code {basename(folder_protocol)}/}: {pid}")
  if (is.na(pid)) cli::cli_abort("No number found in folder {.code {basename(folder_protocol)}/}")

  # disable_web_security = TRUE is needed for local protocols with audio files, etc.
  if (print_watch_run == "watch") {
    monkeys_string = paste0('jsPsychMonkeys::release_the_monkeys(uid = 1, local_folder_tasks = "', normalizePath(folder_protocol), '", open_VNC = TRUE, disable_web_security = TRUE)')
  } else {
    monkeys_string = paste0('jsPsychMonkeys::release_the_monkeys(uid = 1:', n_participants, ', sequential_parallel = "parallel", number_of_cores = 15, local_folder_tasks = "', normalizePath(folder_protocol), '", disable_web_security = TRUE)')
  }


  helper_string = paste0('jsPsychHelpeR::run_initial_setup(pid = ', pid, ', data_location = "', folder_protocol, '/.data", folder = "~/Downloads/jsPsychHelpeR', pid, '")')

  final_string = c(paste0("Simulate, prepare protocol in `", folder_protocol, "`: \n\n"), monkeys_string, "\n\n", helper_string, "\n\n")


  if (print_watch_run == "watch") {

    cli::cli_h1("Release a monkey")
    cli::cli_alert_info(monkeys_string)
    Sys.sleep(sleep_before_running)
    eval(str2lang(monkeys_string))

  } else if (print_watch_run == "run") {

    cli::cli_h1("Release the monkeys")
    cli::cli_alert_info(monkeys_string)
    Sys.sleep(sleep_before_running)
    eval(str2lang(monkeys_string))

    cli::cli_h1("Data preparation with jsPsychHelpeR")
    cli::cli_alert_info(helper_string)
    Sys.sleep(sleep_before_running)
    eval(str2lang(helper_string))

  } else {
    cli::cli_alert_info(final_string)
    cli::cli_alert_info("Copy, pase and run the previous strings to a script")
  }


}



#' get_parameters_of_function
#' Prints usage and examples, shows help, and loads usage parameters to Global environment.
#'
#' @param name_function Name of the function
#' @param load_parameters Load default parameters and their values to the Global Environment
#'
#' @return prints the parameters and examples in the console, shows help, loads the parameters to the Global environment
#' @export
#' @importFrom rlang new_environment
#' @importFrom pkgload inst
#' @importFrom purrr map
#' @importFrom cli cli_h1
#'
#' @examples
#' \dontrun{
#' get_parameters_of_function(name_function = "jsPsychMaker::create_protocol()", load_parameters = TRUE)
#' }
get_parameters_of_function <- function(name_function, load_parameters = TRUE) {

  # Splits name_function to c(package, function)
  name_function_split = strsplit(gsub("(.*)\\(\\)", "\\1", name_function), "::") |> unlist()

  # Create new environment where to load the help files
  temp_env <- rlang::new_environment()

  # Loads rdb/rdx files in PackageName/help/PackageName[.rdb/.rdx]
  X = lazyLoad(
    file.path(
      paste0(pkgload::inst(name_function_split[1]), "/help/", name_function_split[1])
      ), envir = temp_env
    )

  # Load everything in function_help
  function_help = get(name_function_split[2], envir = temp_env)

  # Get names for each element of the list
  names_elements_list = purrr::map(function_help, attr , which = "Rd_tag") |> unlist()

  # Where do we have usage and examples
  which_usage = which(names_elements_list == "\\usage")
  which_examples = which(names_elements_list == "\\examples")

  if (length(which_usage) != 0) {

    # Load usage
    function_parameters = function_help[[which_usage]]

    # Parameters in usage go from 3 to length-1
    start_parameters = 3
    end_parameters = length(function_parameters) - 1
    function_parameters_clean = gsub(",$", "", trimws(function_parameters[start_parameters:end_parameters]))

    # Load parameters and their values to the global environment
    if (load_parameters == TRUE) {

      parameters_function_separated = strsplit(function_parameters_clean, " = ")
      parameters_function_separated |>
        purrr::map(~ { assign(.x[1], eval(parse(text = .x[2])), inherits = TRUE)})

    }


  } else {

    function_parameters_clean = "Parameters NOT FOUND"

  }

  if (length(which_examples) != 0) {

  function_examples = function_help[[which_examples]][[2]] |> unlist()

  } else {
    function_examples = "Examples NOT FOUND"
  }




  # OUTPUTS ---

  # Show help for function
  help(package = name_function_split[1], topic = name_function_split[2]) |> print()

  # Print examples
  cli::cli_h1("Examples")
  function_examples |>  cat()

  # Print parameters
  cli::cli_h1("Parameters")
  function_parameters_clean |> cat(sep = "\n")


}


#' check_tasks_source
#'
#' Checks the different sources of tasks (r package, google sheets with canonical
#' tasks and google sheets with new tasks), and creates a matrix with all the tasks
#'
#' @param gmail_account Gmail account to download the google sheets
#'
#' @return
#' @export
#'
#' @examples
check_tasks_source <- function(gmail_account) {

  googlesheets4::gs4_auth(gmail_account)


  # Docs --------------------------------------------------------------------

  DF_missing_docs =
    tibble::tibble(tasks = jsPsychAdmin::tasks_missing_docs()) |>
    dplyr::mutate(source = "docs") |>
    dplyr::mutate(exists = "missing")


  # Google sheets -----------------------------------------------------------

  DF_raw =
    googlesheets4::read_sheet("1Eo0F4GcmqWZ1cghTpQlA4aHsc8kTABss-HAeimE2IqA", sheet = 2, skip = 0) |>
    dplyr::transmute(tasks = `Codigo Test`) |>
    dplyr::filter(!grepl("short_name", tasks)) |>
    tidyr::drop_na(tasks) |>
    dplyr::mutate(source = "Gsheet",
                  exists = "canonical")

  example_tasks = c("BART", "CAS", "GHQ12")
  DF_raw_NEW =
    googlesheets4::read_sheet("1LAsyTZ2ZRP_xLiUBkqmawwnKWgy8OCwq4mmWrrc_rpQ", sheet = 2, skip = 0) |>
    dplyr::transmute(tasks = `Codigo Test`) |>
    dplyr::filter(!grepl("SIN espacios", tasks)) |>
    dplyr::mutate(source = "Gsheet",
                  exists = "| New") |>
    dplyr::filter(!tasks %in% example_tasks)

  DF_gdocs_all =
    DF_raw |> dplyr::full_join(DF_raw_NEW, by = dplyr::join_by(tasks, source)) |>
    tidyr::replace_na(list(exists.x = "", exists.y = "")) |>
    dplyr::mutate(exists = paste0(exists.x, " ", exists.y)) |>
    dplyr::select(-exists.x, -exists.y)


  # jsPsychMaker ---------------------------------------------------------

  # Translations available. Avoid showing a row for each translation
  DICC_equivalent_tasks =
    tibble::tibble(tasks = c("BNT"),
                   translation = c("BNTen"))

  DF_raw_Rpackage_v6 =
    jsPsychMaker::list_available_tasks(jsPsych_version = 6) |>
    tibble::as_tibble() |>
    dplyr::select(tasks) |>
    dplyr::mutate(source = "jsPsychMaker") |>
    dplyr::mutate(exists = "v6")

  DF_raw_Rpackage_v7 =
    jsPsychMaker::list_available_tasks(jsPsych_version = 7) |>
    tibble::as_tibble() |>
    dplyr::select(tasks) |>
    dplyr::mutate(source = "jsPsychMaker") |>
    dplyr::mutate(exists = "v7")

  DF_maker =
    DF_raw_Rpackage_v6 |>
    dplyr::full_join(DF_raw_Rpackage_v7, by = dplyr::join_by(tasks, source)) |>
    tidyr::replace_na(list(exists.x = "", exists.y = "")) |>
    dplyr::mutate(exists = paste0(exists.x, " ", exists.y)) |>
    dplyr::select(-exists.x, -exists.y) |>

    # Filter out translations
    dplyr::filter(!tasks %in% DICC_equivalent_tasks$translation)


  # jsPsychHelpeR ---------------------------------------------------------

  local_prepare_tasks = here::here(paste0("../jsPsychHelpeR/R_tasks/"))
  ALL_prepare = unique(gsub("prepare_|\\.R", "", list.files(local_prepare_tasks, pattern = "\\.R$")))
  BLACKLIST = "TEMPLATE|AIM[0-9]{1,3}|DEMOGR[0-9]{1,3}|FORM[0-9]{1,3}|FONDECYT.*"

  DF_helper =
    tibble::tibble(tasks = ALL_prepare[!grepl(BLACKLIST, ALL_prepare)]) |>
    dplyr::mutate(source = "jsPsychHelpeR")



# Join all ----------------------------------------------------------------

  DF_output =
    DF_maker |>
    dplyr::bind_rows(DF_helper) |>
    dplyr::bind_rows(DF_gdocs_all) |>
    dplyr::bind_rows(DF_missing_docs) |>
    dplyr::mutate(exists =
                    dplyr::case_when(
                      source == "docs" ~ exists,
                      source == "jsPsychMaker" ~ exists,
                      source == "Gsheet" ~ exists,
                      TRUE ~ "available")) |>
    tidyr::pivot_wider(names_from = source, values_from = exists) |>
    dplyr::mutate(notes =
                    dplyr::case_when(
                      tasks == "CMA" ~ "CMApre and CMApost",
                      tasks == "BNT" ~ "translation: BNTen"
                    )) |>
    dplyr::arrange(tolower(tasks)) # tolower() to ignore case

  return(DF_output)

}


#' tasks_missing_docs
#' Show list of tasks missing docs/
#'
#' @param FOLDER
#'
#' @return
#' @export
#'
#' @examples
tasks_missing_docs <- function(FOLDER = "~/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/SHARED-docs/docs") {

  # TODO: process_docs in jsPsychMaker can be simplified further improving this function

  # Initial files in jsPsychR/SHARED-docs/docs"
  INITIAL = tibble::tibble(path_to_file = list.files(FOLDER, recursive = TRUE, full.names = TRUE),
                           file_short = paste0(basename(dirname(path_to_file)), "/", basename(path_to_file)))


  tasks_with_docs = unique(gsub("(.?)_.*", "\\1", tools::file_path_sans_ext(basename(INITIAL$file_short))))

  all_prepare_scripts = gsub("pre|post", "", gsub("^prepare_(.*)\\.R", "\\1", list.files("../jsPsychHelpeR/R_tasks/", pattern = "R$")))


  MISSING_raw = unique(all_prepare_scripts[!all_prepare_scripts %in% tasks_with_docs])

  BLACKLIST = "Bank|Consent|ConsentHTML|DEBRIEF|Goodbye|Report|SDG|TEMPLATE|AIM[0-9]{1,3}|DEMOGR[0-9]{0,3}|FORM[0-9]{1,3}|FONDECYT.*"

  MISSING = MISSING_raw[!grepl(BLACKLIST, MISSING_raw)]

  cli::cli_alert_info("{length(MISSING)} tasks missing docs: ")

  return(MISSING)
}




#' download_canonical_clean
#' Clones from https://github.com/gorkang/jsPsychMaker the canonical_clean folder
#'
#' @param destination_folder Where to download the canonical_clean folder
#' @param jsPsych_version jsPsych version (6 or 7)
#' @param silent Do not show messages TRUE/FALSE
#'
#' @return
#' @export
#'
#' @examples
download_canonical_clean <- function(destination_folder, jsPsych_version = 6, silent = TRUE) {

  # Prepare temp folder paths
  temp_folder = paste0(tempdir(check = TRUE), "/", basename(destination_folder), "/")
  temp_folder_maker = paste0(temp_folder, "/jsPsychMaker")
  canonical_version = paste0("canonical_clean_", jsPsych_version)

  if (silent == FALSE) cli::cli_alert_info("Downloading {.code {canonical_version}} from Github...")

  # Create temp folder
  if (!dir.exists(temp_folder)) dir.create(temp_folder, recursive = TRUE)

  # Check destination folder exists and does not contain canonical_version
  if (!dir.exists(destination_folder)) {
    dir.create(destination_folder, recursive = TRUE)
  } else {
    folders_destination = basename(list.dirs(destination_folder, recursive = FALSE))
    if (canonical_version %in% folders_destination) {
      cli::cli_abort("{.code {destination_folder}/{canonical_version}/} already exists. Not sure if it is up to date. Delete it or change destination_folder before trying again")
    }
  }


  # Set wd in temp folder. Clone the canonical_clean folder. Clean up
  # https://stackoverflow.com/a/52269934/1873521
  WD = getwd()
  setwd(temp_folder)
  system2(command = "git", args = c("clone", "-n", "--depth=1", "--filter=tree:0", "https://github.com/gorkang/jsPsychMaker"), stdout = FALSE, stderr = FALSE)
  setwd(temp_folder_maker)
  system(paste0("git sparse-checkout set --no-cone ", canonical_version))
  system2(command = "git", args = "checkout", stdout = FALSE, stderr = FALSE)
  fs::dir_copy(path = ".", new_path = destination_folder)
  unlink(temp_folder_maker, recursive = TRUE)
  unlink(paste0(destination_folder, "/.git"), recursive = TRUE)
  setwd(WD)

  if (silent == FALSE) cli::cli_alert_success("{.code {canonical_version}} created in {.code {destination_folder}}")
}



#' copy_canonical_clean_from_Github_to_server
#'
#' @param jsPsych_version 6 or 7
#' @param silent do not show messages FALSE/TRUE
#'
#' @return
#' @export
#'
#' @examples
copy_canonical_clean_from_Github_to_server <- function(jsPsych_version = 6, silent = FALSE) {

  canonical_clean_version = paste0("canonical_clean_", jsPsych_version)

  # Download Github canonical_clean
  OUT_canonical = paste0(tempdir(check = TRUE), "/Github/")
  jsPsychAdmin::download_canonical_clean(destination_folder = OUT_canonical, jsPsych_version = jsPsych_version, silent = silent)

  # Prepare folder
  server_folder = paste0("test/", canonical_clean_version, "/")

  # CS of server canonical_clean
  jsPsychHelpeR::get_zip(pid = server_folder,
                         what = "protocol",
                         where = "/home/emrys/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/CSCN-server/canonical_clean_backups/",
                         file_name =  paste0(Sys.Date(), "_SERVER_", canonical_clean_version, ".zip"),
                         ignore_existing = FALSE, all_messages = !silent, dont_ask = TRUE)

  cli::cli_alert_success("CS of SERVER {canonical_clean_version} copied to `CSCN-server/canonical_clean_backups`")




  # Sync to server
  OUT_canonical_final = paste0(OUT_canonical, "/", canonical_clean_version, "/")

  jsPsychHelpeR::sync_server_local(
    direction = "local_to_server",
    local_folder = OUT_canonical_final,
    server_folder = server_folder,
    only_test = FALSE,
    exclude_csv = TRUE,
    ignore_existing = FALSE,
    delete_nonexistent = TRUE,
    dont_ask = TRUE,
    all_messages = FALSE
  )

  cli::cli_alert_success("Github {canonical_clean_version} copied to server")

}
