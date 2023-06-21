#' create_jsPsychMonkeys_zip
#' Create the jsPsychMonkeys_zip with a template of a full project, needed for the package to run
#'
#' @param add_renv_cache TRUE/FALSE
#'
#' @return
#' @export
#'
#' @examples
create_jsPsychMonkeys_zip <- function(add_renv_cache = FALSE) {

  # params
  output_file = "inst/templates/jsPsychMonkeys.zip"

  if (add_renv_cache == TRUE) cli::cli_alert_info("Creating jsPsychMonkeys.zip \n- `add_renv_cache = TRUE` will include the renv cache in jsPsychMonkeys.zip. \n- This will take ~ 30 seconds")

  # List of core files for ext/templates/jsPsychHelpeR.zip
  root_files = c("jsPsychMonkeys.Rproj", "renv.lock", "run.R", "_targets_options.R", ".Rprofile", "README.md", "NEWS.md", "DESCRIPTION")
  other_important = c("renv/activate.R", ".vault/README.md", "inst/templates/_targets_TEMPLATE.R")

  # tests folder in templates. Will be moved to tests/ in run_initial_setup()
  tests_templates = list.files("inst/templates/tests", full.names = TRUE, recursive = TRUE)


  # R folder
  R_folder = list.files("R", full.names = TRUE)

  # ALL test minus the ones testing the actual jsPsychHeleR package # Probably not needed, as non-package tests will be stored in inst/templates
  # tests_temp = c(list.files("R", pattern = "^test", full.names = TRUE), "tests/testthat.R", list.files("tests/testthat/", full.names = TRUE))
  # tests = tests_temp[-grepl("test-0run_initial_setup.R", tests_temp)]
  # tests = c(list.files("R", pattern = "^test", full.names = TRUE), "tests/testthat.R") #list.files("tests/testthat/", full.names = TRUE)


  # renv cache
  renv_cache = list.files("renv/cache", full.names = TRUE, recursive = TRUE)
  # renv_lib = list.files("renv/lib/", full.names = TRUE, recursive = TRUE) # TODO: This is recreated almost instantly with: renv::restore(prompt = FALSE). Maybe exclude?

  all_files = c(root_files, other_important, tests_templates, R_folder) # NO RENV CACHE

  # Add renv cache and lib
  if (add_renv_cache == TRUE) all_files = c(all_files, renv_cache) # renv_lib should be symlinks, but it becomes a full copy TOO big for Github :(max 100MB)


  # DELETE unnecesary files in the renv cache (doc, help, examples...). This saves a lot of space, but could be a source of issues
  DELETE_files_renv =
    tibble::tibble(name = all_files) |>
    dplyr::mutate(folder = dirname(name)) |>
    dplyr::filter(
      # In renv folder and ends in such and such, and avoid rmarkdown package, and not Meta/packages.rds or Meta/features.rds
      (grepl("^renv", folder) & grepl("/doc$|/examples$|/help$|/help/figures$|/html$|/Meta$", folder) & !grepl("rmarkdown", folder) & !grepl("Meta/package.rds$|Meta/features.rds$", name)) |
        # Delete also this individual files
        grepl("/NEWS.md$|/NEWS.Rd$|/NEWS$|LICENSE$|\\.pdf$", name)
    )


  all_files_clean = all_files[!all_files %in% DELETE_files_renv$name]


  # Create new jsPsychHelpeR.zip (~22 sec)
  file.remove(output_file)
  # utils::zip(zipfile = output_file, files = all_files, flags = "-q")
  utils::zip(zipfile = output_file, files = all_files_clean, flags = "-qrX9") #

  file_KB = round(file.info(output_file)$size/1000, 0)
  cli::cli_alert_success("`jsPsychMonkeys.zip` created in `inst/templates/`: {file_KB}KB")

}





#' create_jsPsychHelpeR_zip
#' Create the jsPsychHelpeR_zip with a template of a full project, needed for the package to run
#'
#' @param add_renv_cache Add the renv cache? Will add couple hundred MB. If TRUE, opening a new project is very fast: TRUE/FALSE
#'
#' @return
#' @export
#'
#' @examples
create_jsPsychHelpeR_zip <- function(add_renv_cache = FALSE) {

  # params
  output_file = "inst/templates/jsPsychHelpeR.zip"

  if (add_renv_cache == TRUE) cli::cli_alert_info("Creating jsPsychHelpeR.zip. \n- `add_renv_cache = TRUE` will include the renv cache in jsPsychHelpeR.zip. \n- This will take ~ 30 seconds")

  # List of core files for ext/templates/jsPsychHelpeR.zip
  root_files = c("jsPsychHelpeR.Rproj", "renv.lock", "run.R", "_targets_options.R", ".Rprofile", "README.md", "NEWS.md", "DESCRIPTION")
  other_important = c("renv/activate.R", ".vault/README.md", "inst/templates/_targets_TEMPLATE.R")

  # tests folder in templates. Will be moved to tests/ in run_initial_setup()
  tests_templates = list.files("inst/templates/tests", full.names = TRUE, recursive = TRUE)


  # R folder
  R_folder = c("R/list_input_files.R", "R/helper_functions_minimal.R", "R/helper_functions_extra.R", "R/run_initial_setup.R", "R/test_testthat.R")
  tasks = list.files("R_tasks", full.names = TRUE)
  analysis = list.files("R", pattern = "^analysis", full.names = TRUE)
  create = list.files("R", pattern = "^create", full.names = TRUE)
  read = list.files("R", pattern = "^read", full.names = TRUE)

  # ALL test minus the ones testing the actual jsPsychHeleR package # Probably not needed, as non-package tests will be stored in inst/templates
  # tests_temp = c(list.files("R", pattern = "^test", full.names = TRUE), "tests/testthat.R", list.files("tests/testthat/", full.names = TRUE))
  # tests = tests_temp[-grepl("test-0run_initial_setup.R", tests_temp)]
  # tests = c(list.files("R", pattern = "^test", full.names = TRUE), "tests/testthat.R") #list.files("tests/testthat/", full.names = TRUE)


  # Rmd
  reports = list.files("Rmd", full.names = TRUE)

  # renv cache
  renv_cache = list.files("renv/cache", full.names = TRUE, recursive = TRUE)
  # renv_lib = list.files("renv/lib/", full.names = TRUE, recursive = TRUE) # TODO: This is recreated almost instantly with: renv::restore(prompt = FALSE). Maybe exclude?

  all_files = c(root_files, other_important, tests_templates, R_folder, tasks, reports, analysis, create, read) # NO RENV CACHE

  # Add renv cache and lib
  if (add_renv_cache == TRUE) all_files = c(all_files, renv_cache) # renv_lib should be symlinks, but it becomes a full copy TOO big for Github :(max 100MB)


  # DELETE unnecesary files in the renv cache (doc, help, examples...). This saves a lot of space, but could be a source of issues
  DELETE_files_renv =
    tibble::tibble(name = all_files) |>
    dplyr::mutate(folder = dirname(name)) |>
    dplyr::filter(
      # In renv folder and ends in such and such, and avoid rmarkdown package, and not Meta/packages.rds or Meta/features.rds
      (grepl("^renv", folder) & grepl("/doc$|/examples$|/help$|/help/figures$|/html$|/Meta$", folder) & !grepl("rmarkdown", folder) & !grepl("Meta/package.rds$|Meta/features.rds$", name)) |
        # Delete also this individual files
        grepl("/NEWS.md$|/NEWS.Rd$|/NEWS$|LICENSE$|\\.pdf$", name)
    )


  all_files_clean = all_files[!all_files %in% DELETE_files_renv$name]


  # Create new jsPsychHelpeR.zip (~22 sec)
  file.remove(output_file)
  # utils::zip(zipfile = output_file, files = all_files, flags = "-q")
  utils::zip(zipfile = output_file, files = all_files_clean, flags = "-qrX9") #

  file_KB = round(file.info(output_file)$size/1000, 0)
  cli::cli_alert_success("`jsPsychHelpeR.zip` created in `inst/templates/`: {file_KB}KB")

}
