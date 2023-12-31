#' SYNC ALL protocols to folder CSCN-server and check
#'
#' Will sync all protocols on server to the LOCAL folder ../CSCN-server
#' Then, will CHECK:
#' - Tasks with no prepare_TASK() script!
#' - Tasks NOT in Google Doc
#' - Check trialid's are OK
#' - Check no missing info in Google doc of NEW tasks
#'
#' @param gmail_account Gmail account to connect to google sheets
#' @param ignore_existing If TRUE, does not overwrite existing files even if they are newer. Good for .data/, Bad for rest
#' @param show_all_messages TRUE / FALSE
#'
#' @return
#' @export
#'
#' @examples
download_check_all_protocols <- function(gmail_account, ignore_existing = TRUE, dont_ask = FALSE, show_all_messages = FALSE) {

# DOWNLOAD AND CHECK -----------------------------------------------------

  # Download protocols WITHOUT data
  # invisible(lapply(list.files("./R", full.names = TRUE, pattern = ".R$"), source))

  DF_missing =
    check_missing_prepare_TASK(
      sync_protocols = TRUE,
      check_trialids = TRUE,
      check_new_task_tabs = TRUE,
      delete_nonexistent = TRUE,
      ignore_existing = ignore_existing,
      dont_ask = dont_ask,
      show_all_messages = show_all_messages,
      gmail_account = gmail_account
    )


# SHOW results ------------------------------------------------------------

  # SHOW tasks with something missing
  DF_missing$DF_FINAL |>
    dplyr::filter(!is.na(missing_script) | !is.na(missing_gdoc) | !is.na(missing_task)) |>
    DT::datatable()

  # Tasks ready to create prepare_*.R script
  DF_missing$DF_FINAL |> dplyr::filter(!is.na(missing_script) & is.na(missing_gdoc))

  # Tasks, protocols and emails for tasks with missing components
  DF_missing$DF_FINAL |> dplyr::filter(!is.na(missing_script) | !is.na(missing_gdoc)) |>
    dplyr::filter(!task %in% c("DEMOGR24", "DEMOGRfondecyt2022E1", "ITC", "fauxPasEv")) |>   # "MDDF_respaldo", "mic_test", "faux_pas",
    dplyr::select(-matches("missing"), -Nombre, -Descripcion) |>  View()

}
