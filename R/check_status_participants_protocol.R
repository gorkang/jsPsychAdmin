#' check_status_participants_protocol
#' CHECKS the mysql database and extracts the number of participants completed, discarded and assigned per protocol
#'
#' @param pid If you want to see a single protocol, enter the protocol id
#'
#' @return
#' @export
#'
#' @examples
check_status_participants_protocol <- function(pid = NULL) {

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
    DB_credentials <- unserialize(sodium::simple_decrypt(data_encrypted, key_private))

    # Extract tables using data_unencrypted
    LIST_tables = jsPsychAdmin:::extract_tables(list_credentials = list_credentials, DB_credentials = DB_credentials, serial_parallel = "parallel") # ~7s

    DF_user_raw = LIST_tables$user
    DF_experimental_condition_raw = LIST_tables$experimental_condition
    DF_combination_between_raw = LIST_tables$combination_between

    if (!is.null(pid)) {
      DF_user = DF_user_raw |> dplyr::filter(id_protocol == pid)
      DF_experimental_condition = DF_experimental_condition_raw |> dplyr::filter(id_protocol == pid)
      DF_combination_between = DF_combination_between_raw |> dplyr::filter(id_protocol == pid)
    } else {
      DF_user = DF_user_raw
      DF_experimental_condition = DF_experimental_condition_raw
      DF_combination_between = DF_combination_between_raw
    }


    # df_Bayesian31 |> separate(condition_between, sep = "_", into = c("condition_between1", "condition_between2")) |> count(condition_between1, condition_between2, id) |> count(condition_between1, condition_between2)

    # DF_experimental_condition |> dplyr::filter(id_protocol == 320)
    # DF_user |> dplyr::filter(id_protocol == 320) |> dplyr::count(status)
    # DF_combination_between |> dplyr::filter(id_protocol == 320) |> dplyr::count(combination, assigned)

    # DF_combination_between |>
    #   dplyr::left_join(LIST_tables$user, by = dplyr::join_by(id_user, id_protocol)) |>
    #   dplyr::count(id_protocol, combination, status) |>
    #   tidyr::pivot_wider(names_from = status, values_from = n) |>
    #   tidyr::replace_na(list(completed = 0, discarded = 0, assigned = 0)) |>
    #   dplyr::group_by(id_protocol) |>
    #   dplyr::reframe(conditions = paste(paste0(combination, ": ", unique(completed), "/" , unique(assigned),  "/", unique(discarded), ""), collapse = ", ")) |>
    #   dplyr::mutate(conditions = paste0(" | ", conditions, "")) |>
    #   dplyr::rename(user_condition = conditions)

    table_conditions_user_condition =
      LIST_tables$user_condition |>
      # dplyr::filter(id_protocol == 320) |>
      dplyr::arrange(id_user, id_protocol, id_condition) |>
      dplyr::select(id_condition, id_user) |>
      dplyr::left_join(LIST_tables$user |> dplyr::select(id_user, id_protocol, status), by = dplyr::join_by(id_user)) |>
      dplyr::left_join(LIST_tables$experimental_condition |> dplyr::select(id_condition, task_name, condition_key, condition_name), by = dplyr::join_by(id_condition)) |>
      dplyr::filter(condition_name != "survey") |>
      dplyr::group_by(id_protocol, task_name, id_user, status) |> # condition_key, THIS one destroys the combinations
      dplyr::arrange(condition_name) |> # Avoid repetitions because of different order
      dplyr::reframe(condition_name = paste(condition_name, collapse = ", "), .groups = "drop") |>
      dplyr::count(id_protocol, task_name, status, condition_name) |>
      tidyr::pivot_wider(names_from = status, values_from = n) |>
      tidyr::replace_na(list(completed = 0, discarded = 0, assigned = 0)) |>
      dplyr::group_by(id_protocol, task_name) |>
      dplyr::reframe(conditions = paste(paste0(condition_name, ": ", completed, "/", assigned, "/", discarded, ""), collapse = ", ")) |>
      dplyr::mutate(conditions = paste0(task_name, " | ", conditions, "")) |>
      dplyr::select(-task_name) |>
      dplyr::rename(user_condition = conditions)



    # Using table experimental_condition CAN'T KNOW the specific combinations of between variables
    table_conditions_experimental_condition =
      DF_experimental_condition |>
      dplyr::select(id_protocol, assigned_task, completed_protocol, task_name, condition_key, condition_name) |>
      dplyr::filter(condition_name != "survey") |>
      dplyr::group_by(id_protocol, task_name, condition_key) |>
      dplyr::reframe(conditions = paste(paste0(condition_name, ": ", completed_protocol, "/", assigned_task, ""), collapse = ", ")) |>
      dplyr::mutate(conditions = paste0(condition_key, " {", conditions, "}")) |>
      dplyr::group_by(id_protocol, task_name) |>
      dplyr::reframe(conditions = paste(conditions, collapse = "; ")) |>
      dplyr::mutate(conditions = paste0(task_name, " | ", conditions, "")) |>
      dplyr::select(-task_name) |>
      dplyr::rename(experimental_condition = conditions)

    # TODO: experimental_condition DONT have discarded. Can get there joining user_condition, DF_user and experimental_condition

    STATUS_BY_CONDITION =
      DF_user |>
      dplyr::select(id_protocol, id_user, status) |>
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

    DF_template = tibble::tibble(id_protocol = NA_integer_, completed = NA_integer_, discarded = NA_integer_, assigned = NA_integer_)
    DF_table_clean =
      DF_user |>
      dplyr::group_by(id_protocol) |>
      dplyr::count(status) |>
      tidyr::pivot_wider(names_from = status, values_from = n) |>
      dplyr::bind_rows(DF_template) |>
      tidyr::replace_na(replace = list(completed = 0,
                                       discarded = 0,
                                       assigned = 0)) |>
      # dplyr::left_join(table_conditions, by = "id_protocol") |>
      dplyr::left_join(table_conditions_user_condition, by = "id_protocol") |>
      dplyr::left_join(table_conditions_experimental_condition, by = "id_protocol") |>
      tidyr::drop_na(id_protocol)

  }


  TABLE_clean = DF_table_clean |>
    gt::gt(groupname_col = NA) |>
    gt::sub_missing(columns = 1:5,
      missing_text = "survey") |>
    gt::tab_caption(caption = gt::md("Columns **user_condition** and **experimental_condition** are created using those MySQL tables. With experimental_condition number of completed do not match and can´t get discarded." ))

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
