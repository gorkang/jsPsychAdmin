
# CHECK participants all protocols ----------------------------------------

  # Does NOT ask for password.
  # Uses the .credentials file + the public key to unlock the encrypted data_encrypted.rds
  jsPsychAdmin::check_status_participants_protocol()


# Clean up a DEV protocol -------------------------------------------------

  # Clean up DB and csv files for a test/protocols_DEV/ protocol # Useful when testing
  # rstudioapi::navigateToFile(".vault/.credentials")
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = "test/protocols_DEV/31") # Asks for server password
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = "999") # Asks for server password


# Check missing scripts ---------------------------------------------------

# TODO: Lots of overlap between check_missing_prepare_TASK() and download_check_all_protocols()

  #  Downloads all the protocols to CSCN-server
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
