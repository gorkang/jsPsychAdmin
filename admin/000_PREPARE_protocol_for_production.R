# Checklist para pasar protocolos de test/protocols_DEV/ a produccion


  # Update monkeys
  pak::pak("gorkang/jsPsychMonkeys")

  # PARAMETERS --------------------------------

  PROTOCOLID = "protocols_DEV/99955"
  # PROTOCOLID = "55"
  number_of_monkeys = "2:100"
  # number_of_monkeys = "101:150"
  jsPsychMonkeys::clean_monkeys_containers()

  # -------------------------------------------

  # Automatic parameters
  pid = gsub("protocols_DEV/", "", PROTOCOLID)


   cli::cli_h1("PROTOCOL {pid}")


  # 1) Pilotaje final on Monkeys! -------------------------------------------

  # Clean data and MySQL DB
  rstudioapi::navigateToFile(".vault/.credentials")
  jsPsychAdmin::clean_up_dev_protocol(protocol_id = PROTOCOLID) # Will ask for server password
  # First time using the computer: https://gorkang.github.io/jsPsychRmanual/qmd/20-Setup.html

  # TEST 1 monkey
   jsPsychMonkeys::release_the_monkeys(uid = 1,
                                       server_folder_tasks = PROTOCOLID,
                                       sequential_parallel = "sequential",
                                       number_of_cores = 1,
                                       big_container = TRUE,
                                       keep_alive = TRUE, open_VNC = TRUE, screenshot = FALSE,
                                       credentials_folder = here::here(".vault/"))


  # LAUNCH MONKEYS
  # options(future.work.enable = TRUE)
  jsPsychMonkeys::release_the_monkeys(uid = number_of_monkeys,
                                      server_folder_tasks = PROTOCOLID,
                                      sequential_parallel = "parallel",
                                      number_of_cores = 30,
                                      big_container = TRUE,
                                      keep_alive = FALSE, open_VNC = FALSE, screenshot = FALSE,
                                      credentials_folder = here::here(".vault/"))


  # CHECK jsPsychHelpeR runs OK

  # THIS WILL take a while, as all the renv packages need to update
  # Create NEW jsPsychHelpeR project, downloading the files from the server
  jsPsychHelpeR::run_initial_setup(pid = PROTOCOLID,
                                   download_files = TRUE,
                                   folder = "~/Downloads/jsPsychR_TESTING_for_PRODUCTION")

    # REMEMBER TO DO targets::tar_make() in jsPsychHelpeR project!


  # 2) Clean data and  MySQL DB --------------------------------------------

    # rstudioapi::navigateToFile(".vault/.credentials")
    jsPsychAdmin::clean_up_dev_protocol(protocol_id = PROTOCOLID) # Will ask for server password
    # jsPsychAdmin::clean_up_dev_protocol(protocol_id = pid) # Will ask for server password


  # 3) Revisar el config.js para pasar el experiment a produccion ----------

    # -[] online = true
    # -[] pid OK? (quitar 9999)
    # -[] debug_mode = false
    # - ETC...


  # 4) Copiar protocolo ZIPeado a test/protocols_DEV/OLD_TESTS/ -------------

    # TODO: automatico!

  # 5) Copiar protocols_DEV/ a protocols/ ----------------------------------------

    # TODO: automatico!

  # 6) BORRAR protocolo de test/protocols_DEV/OLD_TESTS/ --------------------

    # TODO: automatico!

