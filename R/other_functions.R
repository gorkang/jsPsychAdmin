
#' get_github_stars
#'
#' Gets DF with who starred a Github project
#'
#' @param repo
#' @param Renviron
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' DF = get_github_stars(repo = "gorkang/BayesianReasoning",
#' Renviron = "~/gorkang@gmail.com/RESEARCH/PROYECTOS-Code/jsPsychR/jsPsychAdmin/.Renviron")
#' }
get_github_stars <- function(repo, Renviron) {

  github_token = gsub("GITHUB_PAT=", "", readLines(Renviron))

  # https://docs.github.com/en/rest/activity/starring?apiVersion=2022-11-28#list-stargazers--code-samples
  CURL_call = paste0('curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ', github_token, '" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/', repo, '/stargazers')
  JSON = system(CURL_call, intern = TRUE)
  DF = jsonlite::fromJSON(JSON) |> tibble::as_tibble()

  return(DF)

}





#' add_logo_text
#'
#' Add UAI CSCN logo to ggplots
#'
#' @param plot
#' @param align
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' plot = ggplot2::ggplot(diamonds, ggplot2::aes(price, carat)) + ggplot2::geom_point() +  ggplot2::labs(caption = "@gorkang") + ggplot2::theme_minimal()
#' add_logo_text(plot)
#' }
add_logo_text <- function(plot, align = 0) {
  #https://github.com/connorrothschild/tpltheme
  tpl_logo_text <- function(y_num = 1.3) {

    grid::grobTree(
      gp = grid::gpar(fontsize = 11, hjust = 1),

      grid::rectGrob(x = unit(1 + align/10, "npc") - grid::grobWidth("CSCN") + unit(1.5, "lines"),
                     y = unit(y_num, "npc"),
                     width =  grid::grobWidth("UAI") + unit(0.51, "lines"),
                     height =  unit(1, "lines"),
                     hjust = 3.9,
                     vjust = 0.2,
                     gp = grid::gpar(fill = "black")),

      grid::textGrob(label = " CSCN",
                     name = "CSCN",
                     x = unit(1 + align/10, "npc"),
                     y = unit(y_num, "npc"),
                     hjust = 2.6,
                     vjust = 0,
                     gp = grid::gpar(col = "#eb661b", fontface = "bold")),

      grid::textGrob(label = "UAI",
                     name = "UAI",
                     x = unit(1 + align/10, "npc") - grid::grobWidth("CSCN") - unit(0.001, "lines"),
                     y = unit(y_num, "npc"),
                     hjust = 4.1,
                     vjust = 0,
                     gp = grid::gpar(col = "white", fontface = "bold"))
    )
  }

  plot <- gridExtra::grid.arrange(plot, tpl_logo_text(), ncol = 1, heights = c(30, 1))
}

