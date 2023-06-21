# PARAMETERS --------------------------------
# Debe estar en test/protocols_DEV/!!!
PROTOCOLID = "test/protocols_DEV/31"
# PROTOCOLID = "999"
pid = gsub("test/protocols_DEV/", "", PROTOCOLID)
cli::cli_h1("PROTOCOL {pid}")
# -------------------------------------------


# 1) Clean data and MySQL DB
  # rstudioapi::navigateToFile(".vault/.credentials")
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = PROTOCOLID)


# 2) LAUNCH MONKEYS
  jsPsychMonkeys::release_the_monkeys(uid = "1:10",
                                      server_folder_tasks = PROTOCOLID,
                                      sequential_parallel = "parallel",
                                      number_of_cores = 10,
                                      big_container = TRUE,
                                      keep_alive = FALSE, open_VNC = FALSE, screenshot = FALSE,
                                      credentials_folder = here::here(".vault/"))
