# WIP: should launch monkeys and prepare data


# Create NEW_TASKS protocol -----------------------------------------------

# In this script we:
  # - Detect tasks for which we do not have CSV's in 999.zip (but have a prepare_TASK.R)
  # - Sync server protocols to local
  # - Create a NEW_TASKS protocol with all the new tasks


# SOME TASKS CAN GIVE ERRORS.
# - IMPORTANT TO CHECK EVERYTHING OK BEFORE MOVE TO CANONICAL



# LAST RUN ----------------------------------------------------------------

# 2022/07/29
  # OK: jsPsychHelpeR/data/NEW_TASKS.zip
  # NOT OK: "FORM6", "PATTI","DEMOGR3", "FORM4","CEL","MLQ"


# create_protocol_with_missing_in_999.zip ----------------------------------

  # Reads task results in 999.zip
  # Reads ANY tasks available in jsPsychMaker/protocols_DEV/
  # Read all prepare_TASK in jsPSychHelpeR/R_tasks/
  # DOWNLOADS ALL protocols from server to ../CSCN-server/
  # Modify config.js to adapt to new tasks


# Using the missing prepare_tasks()
# create_protocol_with_missing_in_999(search_where = "prepare_TASK")



# CREATE PROTOCOL ---------------------------------------------------------

  FOLDER_PROTOCOL = "../CSCN-server/protocols/test/protocols_DEV/NEW_TASKS/"
  jsPsychAdmin::create_protocol_with_missing_in_999(search_where = "prepare_TASK", destination_folder = FOLDER_PROTOCOL)



# CHECK CONFIG ------------------------------------------------------------

  # CHECK config.js
    # - online
    # - pid
  rstudioapi::navigateToFile("../CSCN-server/protocols/test/protocols_DEV/NEW_TASKS/config.js")

# TASKS protocolo Colombia-Chile
  # 'CTT', 'CIT', 'CRQ', 'ICvsID', 'LSNS', 'MDDF', 'PSC', 'UCLA'
  # //'SCGT', ESTA USA MICRO. CORRER MANUALMENTE (no funciona en Docker)






# Monkeys! ----------------------------------------------------------------

  jsPsychAdmin::clean_up_dev_protocol(protocol_id = 999)

  jsPsychMonkeys::release_the_monkeys(uid = 100, #100:105
                                      uid_URL = TRUE,
                                      forced_seed = 11, # Reproducible. Comment for random
                                      forced_random_wait = TRUE, forced_refresh = TRUE,
                                      initial_wait = 5,
                                      wait_retry = 5, # Increase if fails
                                      local_folder_tasks = here::here("../CSCN-server/protocols/test/protocols_DEV/NEW_TASKS/"),
                                      big_container = TRUE, debug_file = FALSE, console_logs = TRUE, DEBUG = TRUE,
                                      open_VNC = TRUE, keep_alive = TRUE,
                                      disable_web_security = FALSE)










# UPLOAD NEW_TASKS to server --------------------------------------------------

  # UPLOAD CSCN-server/.../NEW_TASKS to server
  jsPsychHelpeR::sync_server_local(direction = "local_to_server",
                    local_folder = FOLDER_PROTOCOL,
                    server_folder = "test/protocols_DEV/NEW_TASKS/", only_test = FALSE)




# DELETE .data in server --------------------------------------------------

  # DELETE SERVER "test/protocols_DEV/NEW_TASKS/" .data/ files
  jsPsychAdmin::DELETE_data_server(pid = "test/protocols_DEV/NEW_TASKS/")

  # list_credentials = source(".vault/.credentials") # Get server credentials
  # system(paste0('sshpass -p ', list_credentials$value$password, ' ssh ', list_credentials$value$user, '@', list_credentials$value$IP, ' rm ', list_credentials$value$main_FOLDER, "test/protocols_DEV/NEW_TASKS/", '/.data/*'))


# DOWNLOAD to protocols_DEV -----------------------------------------------

  # TODO: Can just copy instead of download
    # FROM: ../CSCN-server/protocols/test/protocols_DEV/NEW_TASKS/
    # TO: ../jsPsychMaker/protocols_DEV/NEW_TASKS/

  # DOWNLOAD to NEW_TASKS to ../jsPsychMaker/protocols_DEV/NEW_TASKS/
  # To make sure the Github jsPsychMaker/protocols_DEV/NEW_TASKS is up to date
  jsPsychHelpeR::sync_server_local(direction = "server_to_local",
                    server_folder = "test/protocols_DEV/NEW_TASKS/",
                    local_folder = "../jsPsychMaker/protocols_DEV/NEW_TASKS/",
                    only_test = FALSE)

  cli::cli_h1("REMEMBER")
  cli::cli_alert_info("Commit and PUSH NEW_TASKS changes in jsPsychMaker!!!")
  rstudioapi::openProject(path = "../jsPsychMaker/", newSession = TRUE)


# # MONKEYS -----------------------------------------------------------------
#
# # DELETE protocol 999 MYSQL rows
#   system("mysql-workbench")
#   # system("mysql-workbench-community")
#
# # Launch monkeys! # Go to jsPsychMonkeys and use the following in _targets.R
# rstudioapi::openProject(path = "../jsPsychMonkeys/", newSession = TRUE)
#
# parameters_monkeys_minimal = list(uid = 100:105, uid_URL = TRUE,
#                                   forced_seed = 11, # Reproducible. Comment for random
#                                   forced_random_wait = TRUE, forced_refresh = TRUE,
#                                   initial_wait = 5,
#                                   wait_retry = 5, # Increase if fails
#                                   server_folder_tasks = "test/protocols_DEV/NEW_TASKS/",
#                                   big_container = TRUE, debug_file = FALSE, console_logs = TRUE, debug = TRUE,
#                                   open_VNC = TRUE, keep_alive = TRUE,
#                                   disable_web_security = FALSE)
#
#
#
#
#
# # SETUP HELPER ------------------------------------------------------------
#
#   # Delete OLD data
#   OLD_data = list.files("data/test/protocols_DEV/NEW_TASKS/", full.names = TRUE)
#   file.remove(OLD_data)
#
#   # Download new data and setup Helper
#   run_initial_setup(pid = "test/protocols_DEV/NEW_TASKS/",
#                     download_files = TRUE,
#                     download_task_script = TRUE)
