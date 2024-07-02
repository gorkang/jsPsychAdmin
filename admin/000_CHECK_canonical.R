# CHECK canonical_protocol ------------------------------------------------

# Help checks all tasks in canonical_protocol work as expected

  # 1. Creates a config.js file with all the tasks in ../jsPsychMaker/canonical_protocol/
  # 2. Uploads ../jsPsychMaker/canonical_protocol/ to the 999 protocol in the server
  # 3. Deletes the contents of .data/
  # 4. Open MySQL-workbech to delete all 999 tables
  # 5. Opens jsPsychMonkeys to simulate the 5 standard participants
  # 6. Opens jsPsychHelpeR to prepare data (deletes data/999, downloads, renames...)
  # 7. TODO: Compare new RUN with old RUN

# REMEMBER to:
  # test NEW TASKS with admin/create_protocol_with_NEW_tasks.R before moving them to canonical_protocol
  # MOVE SHARED-FONDECYT-Faridy/jsPsychR/NEW_scales-docs to jsPsychR/SHARED-docs/docs/ and to jsPsychR/jsPsychmaker/docs


### TODO --
  # - Unzip snapshots to 'tests/testthat/_snaps/snapshots' before running the pipeline
  # - Are we using tests/manual_correction?
  # STEP 0 SHOULD BE TO CREATE A BACKUP

  # CHECK TWO RUNS ARE IDENTICAL



# prepare config.js -------------------------------------------------------

  # Use all available tasks in canonical_protocol to create a new config.js

  tasks_canonical = jsPsychMaker::extract_tasks_from_protocol(folder_protocol = "../jsPsychMaker/canonical_protocol/")

  # jsPsychMaker::update_config_js(folder_protocol = "../jsPsychMaker/canonical_protocol/",
  #                                tasks = tasks_canonical,
  #                                block_tasks = "randomly_ordered_tasks_1")
  # rstudioapi::navigateToFile("../jsPsychMaker/canonical_protocol/config.js")

  jsPsychMaker::create_protocol(canonical_tasks = tasks_canonical$tasks, force_download_media = TRUE)

  jsPsychMonkeys::release_the_monkeys(uid = 1,
                                      local_folder_tasks = here::here("~/Downloads/new_protocol_999/"),
                                      number_of_cores = 1,
                                      disable_web_security = TRUE,
                                      open_VNC = TRUE)



# Sync canonical_protocol to 999 and test ------------------------------

  # 1) UPLOAD jsPsychMaker/canonical_protocol/ to http://cscn.uai.cl/lab/public/instruments/protocols/999 ----------------------------

    # Upload LOCAL canonical_protocol to SERVER as 999
    jsPsychHelpeR::sync_server_local(direction = "local_to_server",
                      local_folder = "../jsPsychMaker/canonical_protocol",
                      server_folder = "999",
                      only_test = FALSE)

    # DELETE SERVER 999/.data/ files and the 999 protocol rows in all the MYSQL tables
    # rstudioapi::navigateToFile(".vault/.credentials")
    jsPsychAdmin::clean_up_dev_protocol(protocol_id = 999)



  # 2) jPsychMonkeys: Run 5 monkeys... same ID's, same responses per task (only if no randomization in jsPsych) ----------------------
    jsPsychMonkeys::release_the_monkeys(uid = "1:5",
                                        server_folder_tasks = "999",
                                        sequential_parallel = "parallel",
                                        number_of_cores = 5,
                                        credentials_folder = ".vault/",
                                        open_VNC = FALSE)

    # Kill all docker containers
    # jsPsychAdmin:::kill_all_monkeys()



  # 3) jsPsychHelpeR: prepare data. CHECK differences --------------------------------------------------------------------------------

    # || THIS WILL take a while, as all the renv packages need to update
    # Create NEW jsPsychHelpeR 999 project, downloading the files from the server
    jsPsychHelpeR::run_initial_setup(pid = 999,
                                     download_files = TRUE,
                                     folder = "~/Downloads/jsPsychR_canonical")


    # Rename all FILES so the filenames do not change
    rename_jsPsych_canonical(canonical_protocol_helper = "~/Downloads/jsPsychR_canonical/")


    # CHECK we have results files for all tasks
    jsPsychHelpeR::check_project_and_results(participants = 5,
                                             folder_protocol = "../jsPsychMaker/canonical_protocol/tasks",
                                             folder_results = "~/Downloads/jsPsychR_canonical/data/999/")


    # Run project ~/Downloads/jsPsychR_canonical
    # targets::tar_destroy(ask = FALSE)
    # targets::tar_make()

    # Check test file
    # rstudioapi::navigateToFile("outputs/tests_outputs/test-DF_clean.csv")



# CHECK TWO RUNS ARE IDENTICAL --------------------------------------------

    # THIS IS A WIP!!!!

  folder1 = "/home/emrys/Downloads/JSPSYCH/jsPsychHelpeR_test-survey/TEST/data999/"
  folder2 = "/home/emrys/Downloads/JSPSYCH/jsPsychHelpeR_test-survey/TEST/data999/"

  DF_joined1 = readr::read_csv(paste0(folder1, "/DF_joined.csv"))
  DF_joined2 = readr::read_csv(paste0(folder2, "/DF_joined.csv"))
  DF_clean1 = readr::read_csv(paste0(folder1, "/DF_clean.csv"))
  DF_clean2 = readr::read_csv(paste0(folder2, "/DF_clean.csv"))

  waldo::compare(DF_joined1, DF_joined2)
  waldo::compare(DF_clean1, DF_clean2)
