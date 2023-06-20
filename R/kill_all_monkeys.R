kill_all_monkeys <- function() {

  active_containers = system('docker ps -q', intern = TRUE)
  active_containers |> purrr::walk(~system(paste0('docker stop ', .x)))
  system("docker system prune -f") # Cleans up system (stopped containers, etc.)

}
