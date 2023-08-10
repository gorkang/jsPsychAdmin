
#' Clean up server protocol
#'
#' @param protocol_id Id for dev protocol (e.g. 'test/protocols_DEV/999')
#'
#' @return
#' @export
#'
#' @examples
clean_up_dev_protocol <- function(protocol_id, override_DEV_limitation = FALSE) {

  # protocol_id = "test/protocols_DEV/999"
  # protocol_id = 999


  # CHECK IT IS A DEV PROTOCOL
  is_dev_protocol = grepl("test/protocols_DEV/|999", protocol_id)

  if (!is_dev_protocol) {
    if (override_DEV_limitation == FALSE) {
      cli::cli_abort("[protocol_id = {protocol_id}] Can only clean up DEV protocols or protocol 999: e.g. 'test/protocols_DEV/999'")
    } else {
      response_prompt = utils::menu(choices = c("Yes, I want to DELETE EVERYTHING!", "NO, thanks for asking"),
                                    title =
                                      cli::cli(
                                        {
                                          cli::cli_par()
                                          cli::cli_alert_info("protocol {protocol_id} is NOT a DEV protocol but `override_DEV_limitation = {override_DEV_limitation}`\n\n {cli::style_bold((cli::col_red('DELETE')))} protocol {protocol_id} MySQL databases and files? This CAN NOT be undone.")
                                          cli::cli_end()
                                          cli::cli_text("Are you SURE? ALL the participant data and MySQL information will be lost")
                                        }

                                      )
                                    )
      if (response_prompt != 1) cli::cli_abort("[protocol_id = {protocol_id}] ABORTED: Nothing will be done")
    }
  }



  # Sources and credentials
  pid = gsub("test/protocols_DEV/", "", protocol_id)
  cli::cli_h1("PROTOCOL {pid}")

  # 1) Limpiar la base de datos --------------------------------------------

  # Delete the XYZ protocol rows in all the MYSQL tables
  delete_MySQL_tables_pid(pid)


  # 2) Limpiar los archivos de resultados de Monkeys -----------------------

  # Delete csv files in .data/
  # rstudioapi::navigateToFile(".vault/.credentials")
  DELETE_data_server(pid = protocol_id)


}
