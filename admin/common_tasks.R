
# New protocols -----------------------------------------------------------

  # We develop locally, uploading via Pull request to GITHUB protocol_DEV/N

  # 1) Once a GITHUB protocol_DEV/N is ready to test online, we need to do:

    # - GITHUB protocol_DEV/N -> SERVER protocol_DEV/N

  # 2) And once that is ready:

    # - clean up dev protocol:   jsPsychAdmin::clean_up_dev_protocol(protocol_id = "protocols_DEV/999")

    # - SERVER protocol_DEV/N -> SERVER protocol/N


# See also 000_PREPARE_protocol_for_production.R



# Install packages --------------------------------------------------------

pak::pkg_install(
  pkg = c(
    "gorkang/jsPsychHelpeR",
    "gorkang/jsPsychMonkeys",
    "gorkang/jsPsychMaker",
    "gorkang/jsPsychAdmin"
    )
  )


# Check available tasks sources -------------------------------------------

#### IMPORTANT TO KEEP EVERYTHING IN SYNC ####

# CHECK missing:
# - tasks in v6 or v7
# - prepare_scripts
# - Info in google docs
# - docs/
DF_tasks = jsPsychAdmin::check_tasks_source("gorkang@gmail.com")
DT::datatable(DF_tasks, filter = 'top', options = list(dom = "tip", pageLength = -1, paging = FALSE))


# WHAT TO DO:
# Copy NA's in jsPsychMaker to jsPsychMaker/canonical_protocol/tasks
# Search missing jsPsychHelpeR prepare_scripts and copy to jsPsychHelpeR/R_tasks
# Delete tasks from New Google sheet if they are in both New and canonical
# Move New to canonical Google sheet when tasks are ready
# Ask for docs/




# DEBUG ---------------------------------------------------------------------

# Get all parameters of a function (to help DEBUG)
jsPsychAdmin::get_parameters_of_function("jsPsychHelpeR::run_initial_setup()")


# Sync and check all protocols --------------------------------------------

  jsPsychAdmin::download_check_all_protocols(gmail_account = "gorkang@gmail.com",
                                             ignore_existing = FALSE, # Overwrites existing files that changed
                                             dont_ask = TRUE,
                                             show_all_messages = TRUE)


  jsPsychHelpeR::sync_server_local(server_folder = "",
                                   local_folder = here::here(paste0("..", "/CSCN-server/protocols/")),
                                   direction = "server_to_local",
                                   only_test = FALSE,
                                   exclude_csv = TRUE, # DO NOT INCLUDE DATA
                                   delete_nonexistent = TRUE,
                                   ignore_existing = FALSE, # If a file already exists, ignore it. Good for data, bad for protocols.
                                   dont_ask = TRUE
                                   )

# CHECK MySQL participants all protocols ----------------------------------------

  # CHECKS MySQL database for number of completed, discarded and assigned participants for each protocol

  # Does NOT ask for password.
  # Uses the .credentials file + the public key to unlock the encrypted data_encrypted.rds
  OUTPUT = jsPsychAdmin::check_status_participants_protocol()
  OUTPUT$STATUS_BY_CONDITION
  OUTPUT$TABLE_clean # This does not include Discarded

  OUTPUT$TABLE_clean |> gt::gtsave("outputs/table_participan")

  OUTPUT$TOTAL_participants
  # TODO: should also check how many files from how many tasks???


# Clean up a DEV protocol -------------------------------------------------

  # DANGER: will clean up MySQL DB and DELETE csv files

  # Clean up DB and csv files for a test/protocols_DEV/ protocol # Useful when testing
  rstudioapi::navigateToFile(".vault/.credentials")

  jsPsychAdmin::clean_up_dev_protocol(protocol_id = "protocols_DEV/44") # Asks for server password

  # Old protocols test/protocols_DEV/999
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = "999") # Asks for server password

  # CAREFUL WITH THIS ---
  # For protocols in production after pilots. TO DISCARD EVERYTHING.
  # Creates a zip backup of files, just in case, but the DB is not backed up here. For daily DB backups see jsPsychR/CSCN-server/DB_backups/
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = "999", override_DEV_limitation = TRUE) # Asks for server password



# Check missing scripts ---------------------------------------------------

# TODO: Lots of overlap between check_missing_prepare_TASK() and download_check_all_protocols()

  #  Downloads all the protocols to CSCN-server folder
  #  Then checks:
  # - for which ones we do not have preparation scripts
  # - for which ones we do not have googledoc details in
  # + https://docs.google.com/spreadsheets/d/1Eo0F4GcmqWZ1cghTpQlA4aHsc8kTABss-HAeimE2IqA/edit#gid=0
  # + https://docs.google.com/spreadsheets/d/1LAsyTZ2ZRP_xLiUBkqmawwnKWgy8OCwq4mmWrrc_rpQ/edit#gid=0

  jsPsychAdmin::check_missing_prepare_TASK(sync_protocols = TRUE, check_trialids = TRUE, check_new_task_tabs = TRUE, delete_nonexistent = FALSE,
                                           gmail_account = "gorkang@gmail.com")

  # Will sync all protocols on server to the LOCAL folder ../CSCN-server
  # Then, will CHECK:
  # - Tasks with no prepare_TASK() script!
  # - Tasks NOT in Google Doc
  # - Check trialid's are OK
  # - Check no missing info in Google doc of NEW tasks
  jsPsychAdmin::download_check_all_protocols(gmail_account = "gorkang@gmail.com")



# Download/Upload specific protocol ---------------------------------------

  # UPLOAD
  jsPsychHelpeR::sync_server_local(
    direction = "local_to_server",
    local_folder = "../jsPsychMaker/protocols_DEV/999/",
    server_folder = "test/protocols_DEV/999/",
    only_test = FALSE,
    delete_nonexistent = TRUE
  )

  # DOWNLOAD
  jsPsychHelpeR::sync_server_local(
    direction = "server_to_local",
    server_folder = "test/protocols_DEV/999/",
    local_folder = "../jsPsychMaker/protocols_DEV/999/",
    only_test = TRUE,
    delete_nonexistent = FALSE
  )



# MONKEYS -----------------------------------------------------------------


# Clean all monkey's containers -------------------------------------------

  jsPsychMonkeys::clean_monkeys_containers()


## Connect to a running monkey -------------------------------------------

  # jsPsychMonkeys::reconnect_to_VNC()
  jsPsychMonkeys::reconnect_to_VNC(container_name = "monkey_2")


## Run single monkey ------------------------------------------------------

  # Locally
  jsPsychMonkeys::release_the_monkeys(uid = "1",
                                      sequential_parallel =  "sequential",
                                      open_VNC = TRUE,
                                      local_folder_tasks = "~/Downloads/canonical_protocol/",
                                      keep_alive = TRUE,
                                      disable_web_security = TRUE,
                                      debug_file = TRUE,
                                      console_logs = TRUE)

  # Server
  jsPsychMonkeys::release_the_monkeys(uid = "1223",
                                      credentials_folder = ".vault/",
                                      sequential_parallel =  "sequential",
                                      initial_wait = 1, wait_retry = 5,
                                      open_VNC = TRUE,
                                      server_folder_tasks = "protocols_DEV/999",
                                      keep_alive = TRUE,
                                      disable_web_security = FALSE,
                                      screenshot = TRUE,
                                      debug_file = TRUE,
                                      console_logs = TRUE)

## Run multiple monkeys ------------------------------------------------------

  # Locally
  jsPsychMonkeys::release_the_monkeys(uid = "1:10",
                                      number_of_cores = 10,
                                      sequential_parallel =  "parallel",
                                      open_VNC = FALSE,
                                      local_folder_tasks = "~/Downloads/canonical_protocol/",
                                      keep_alive = FALSE,
                                      disable_web_security = TRUE,
                                      screenshot = TRUE,
                                      debug_file = TRUE,
                                      console_logs = TRUE)

  # Server
  jsPsychMonkeys::release_the_monkeys(uid = "1:200",
                                      number_of_cores = 14,
                                      initial_wait = 0.1, wait_retry = 1, #5
                                      credentials_folder = ".vault/",
                                      sequential_parallel =  "parallel",
                                      open_VNC = FALSE,
                                      server_folder_tasks = "protocols_DEV/46",
                                      keep_alive = FALSE,
                                      disable_web_security = FALSE,
                                      screenshot = FALSE,
                                      debug_file = TRUE,
                                      console_logs = TRUE)

# HELPER ------------------------------------------------------------------


## Create new project ----------------------------------------

  jsPsychHelpeR::run_initial_setup(pid = "test/protocols_DEV/999",
                                   download_files = TRUE,
                                   folder = "~/Downloads/jsPsychHelpeR999",
                                   credentials_file = ".vault/.credentials"
                                   )




## Get data ----------------------------------------------------------------

  # file.remove("~/Downloads/jsPsychHelpeR-999/data/999.zip")

  jsPsychHelpeR::get_zip(pid = "999",
                         what = "data",
                         where = "~/Downloads/jsPsychHelpeR-999/data/")






# COMBOS ------------------------------------------------------------------


## Create & Simulate & Prepare ---------------------------------------------

  jsPsychMaker::create_protocol(
    folder_tasks = "~/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/jsPsychMaker/admin/example_tasks/example_tasks/",
    folder_output = "~/Downloads/protocolALL999",
    launch_browser = FALSE,
    options_separator = ";"
  )

  # AUTOMATICALLY

  # Only prints in console the code
  jsPsychAdmin::simulate_prepare(folder_protocol = "~/Downloads/protocolALL999", n_participants = 3, print_watch_run = "print")

  # Runs everything
  jsPsychAdmin::simulate_prepare(folder_protocol = "~/Downloads/protocolALL999", n_participants = 3, print_watch_run = "run")

  # Run a single Monkey and open VNC to see how it goes
  jsPsychAdmin::simulate_prepare(folder_protocol = "~/Downloads/protocolALL999", print_watch_run = "watch")


  # MANUALLY
  # jsPsychMonkeys::release_the_monkeys(uid = "1",
  #                                     sequential_parallel =  "sequential",
  #                                     number_of_cores = 1,
  #                                     local_folder_tasks = "~/Downloads/protocolALL999/")
  #
  # jsPsychHelpeR::run_initial_setup(pid = 999, data_location = "~/Downloads/protocolALL999/.data/")



## Clean server & Launch Monkeys -------------------------------------------

  PROTOCOLID = "test/protocols_DEV/320" # Debe estar en test/protocols_DEV/!!! o ser 999
  pid = gsub("test/protocols_DEV/", "", PROTOCOLID)
  cli::cli_h1("PROTOCOL {pid}")

  # 1) Clean data and MySQL DB
  rstudioapi::navigateToFile(".vault/.credentials")
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = PROTOCOLID)


  # 2) LAUNCH LOCAL MONKEYS
  jsPsychMonkeys::release_the_monkeys(uid = 15555,
                                      local_folder_tasks = "/home/emrys/Downloads/999/",
                                      open_VNC = TRUE, disable_web_security = TRUE)


  # 2) LAUNCH ONLINE PARALLEL MONKEYS
  jsPsychMonkeys::release_the_monkeys(uid = "205",
                                      server_folder_tasks = PROTOCOLID,
                                      sequential_parallel = "sequential",
                                      number_of_cores = 20,
                                      big_container = TRUE,
                                      keep_alive = FALSE, open_VNC = FALSE, screenshot = FALSE,
                                      credentials_folder = here::here(".vault/"))

  # Check DB
  OUTPUT = jsPsychAdmin::check_status_participants_protocol(pid = 320)
  OUTPUT$STATUS_BY_CONDITION |> dplyr::filter(id_protocol == 320)




# INSTALL MySQL drivers ---------------------------------------------------

  # Check available Drivers:
  odbc::odbcListDrivers()$name |> unique()

  # data_encrypted.rds stores the MySQL Driver used


  # 1. Download drivers ---

  # A) From https://dev.mysql.com/downloads/mysql/
    # Select Operating System: Ubuntu Linux
    # Select OS Version: Ubuntu Linux 22.04 (x86, 64-bit)
    # Download 1 file:
      # mysql-community-client-plugins_... # e.g. mysql-community-client-plugins_8.1.0-1ubuntu22.04_amd64.deb

  # B) From:  https://dev.mysql.com/downloads/connector/odbc/
    # Select Operating System: Ubuntu Linux
    # Select OS Version: Ubuntu Linux 22.04 (x86, 64-bit)
    # Download 4 files:
      # mysql-connector-odbc_...
      # mysql-connector-odbc-dbgsym_...
      # mysql-connector-odbc-setup_...
      # mysql-connector-odbc-setup-dbgsym_...



  # Copy the 5 files to a folder ---

  # For example to ~/Downloads/FOLDER/:
    # mysql-community-client-plugins_8.0.33-1ubuntu22.04_amd64.deb
    # mysql-connector-odbc_8.0.33-1ubuntu22.04_amd64.deb
    # mysql-connector-odbc-dbgsym_8.0.33-1ubuntu22.04_amd64.deb
    # mysql-connector-odbc-setup_8.0.33-1ubuntu22.04_amd64.deb
    # mysql-connector-odbc-setup-dbgsym_8.0.33-1ubuntu22.04_amd64.deb


  # 2. Install drivers: ---

  # sudo dpkg -i ~/Downloads/FOLDER/mysql-*

  ## Remove
  ## sudo apt remove mysql-community-client-plugins mysql-connector-odbc mysql-connector-odbc-dbgsym mysql-connector-odbc-setup mysql-connector-odbc-setup-dbgsym


  # CHANGES ---

  # data_encrypted.rds has $value$Driver = "MySQL ODBC 8.1 Unicode Driver"
  # If the MySQL version installed is bigger, change the number



