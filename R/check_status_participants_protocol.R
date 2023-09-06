#' check_status_participants_protocol
#' CHECKS the mysql database and extracts the number of participants completed, discarded and assigned per protocol
#'
#' @return
#' @export
#'
#' @examples
check_status_participants_protocol <- function() {

  list_credentials = source(here::here(".vault/.credentials"))
  PASSWORD = list_credentials$value$password

  #Load encrypted data
  data_encrypted <- readRDS(here::here(".vault/data_encrypted.rds"))

  #Public key (its okay to hardcode it here, public keys are designed for sharing)
  key_public = readLines(here::here(".vault/data_public_key.txt"))

  #Private key
  key_private <- sodium::sha256(charToRaw(PASSWORD))

  #Check if private key provided is correct
  if(paste(sodium::pubkey(key_private), collapse = " ") == key_public) {

    #Unencrypt data and make it available elsewhere
    data_unencrypted <- unserialize(sodium::simple_decrypt(data_encrypted, key_private))

    # Extract tables using data_unencrypted
    LIST_tables = jsPsychAdmin:::extract_tables(list_credentials = data_unencrypted, serial_parallel = "parallel") # ~7s

    DF_user = LIST_tables$user

    table_conditions = LIST_tables$experimental_condition |>
      dplyr::select(id_protocol, assigned_task, completed_protocol, task_name, condition_key, condition_name) |>
      dplyr::filter(condition_name != "survey") |>
      dplyr::group_by(id_protocol, task_name, condition_key) |>
      dplyr::reframe(
        conditions = paste(paste0(condition_name, ": ", completed_protocol, "/", assigned_task, ""), collapse = ", ")
      ) |>
      dplyr::mutate(conditions = paste0(condition_key, " {", conditions, "}")) |>
      dplyr::group_by(id_protocol, task_name) |>
      dplyr::reframe(conditions = paste(conditions, collapse = "; ")) |>
      dplyr::mutate(conditions = paste0(task_name, " | ", conditions, "")) |>
      dplyr::select(-task_name)

    # TODO: experimental_condition DONT have discarded. Can get there joining user_condition, DF_user and experimental_condition

    STATUS_BY_CONDITION = DF_user |> dplyr::select(id_protocol, id_user, status) |>
      dplyr::left_join(
        LIST_tables$user_condition |> dplyr::select(id_protocol, id_user, id_condition),
        by = c("id_protocol", "id_user")) |>
      dplyr::left_join(
        LIST_tables$experimental_condition |> dplyr::select(id_condition, id_protocol, condition_key, condition_name),
        by = c("id_protocol", "id_condition")) |>
      dplyr::group_by(id_protocol) |>
      dplyr::count(condition_key, status, condition_name) |>
      tidyr::pivot_wider(names_from = status, values_from = n) |>
      tidyr::replace_na(replace = list(completed = 0,
                                       discarded = 0,
                                       assigned = 0))

    DF_table_clean = DF_user |>
      dplyr::group_by(id_protocol) |>
      dplyr::count(status) |>
      tidyr::pivot_wider(names_from = status, values_from = n) |>
      tidyr::replace_na(replace = list(completed = 0,
                                       discarded = 0,
                                       assigned = 0)) |>
      dplyr::left_join(table_conditions, by = "id_protocol")

  }


  TABLE_clean = DF_table_clean |> gt::gt(groupname_col = NA) |>
    gt::sub_missing(columns = 1:5,
      missing_text = "survey")

  # Total online participants in MySQL DB
  TOTAL_participants =
    DF_table_clean |>
    dplyr::ungroup() |>
    dplyr::summarise(TOTAL_completed = sum(completed, na.rm = TRUE))

  cli::cli_alert_warning("STATUS_BY_CONDITION and TABLE_clean numbers are not 100% in agreement. See for example pid 2 or pid 28")

  OUTPUT = list(TABLE_clean = TABLE_clean,
                STATUS_BY_CONDITION = STATUS_BY_CONDITION,
                TOTAL_participants = TOTAL_participants)

  return(OUTPUT)

}
