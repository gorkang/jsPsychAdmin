
# CHECK participants all protocols ----------------------------------------

  # CHECKS number of completed, discarted and assigned participants for each protocol

  # Does NOT ask for password.
  # Uses the .credentials file + the public key to unlock the encrypted data_encrypted.rds
  jsPsychAdmin::check_status_participants_protocol()
    # TODO: should also check how many files from how many tasks???


# Clean up a DEV protocol -------------------------------------------------

  # DANGER: will clean up MySQL DB and DELETE csv files

  # Clean up DB and csv files for a test/protocols_DEV/ protocol # Useful when testing
  # rstudioapi::navigateToFile(".vault/.credentials")
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = "test/protocols_DEV/31") # Asks for server password
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = "999") # Asks for server password


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
  jsPsychHelpeR::sync_server_local(direction = "local_to_server", local_folder = "protocols_DEV/999/", server_folder = "test/protocols_DEV/999/", only_test = TRUE, delete_nonexistent = FALSE)

  # DOWNLOAD
  jsPsychHelpeR::sync_server_local(direction = "server_to_local", server_folder = "test/protocols_DEV/999/", local_folder = "protocols_DEV/999/", only_test = TRUE, delete_nonexistent = FALSE)

