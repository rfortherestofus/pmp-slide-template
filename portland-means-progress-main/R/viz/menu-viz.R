# Menu-type visualisations

# Across several years ----
menu_across_years <- function(data,
                              questions,
                              question_block,
                              point_color = pmp_palette$Yellow,
                              text_size_theme = 18) {
  # get survey item labels ---
  df_questions_label_filtered <-
    questions |>
    filter(word_doc_q == question_block) |>
    select(survey_item, item_label = answer)
  
  # compute coordinates ---
  length_labels <- nrow(df_questions_label_filtered)
  
  if (length_labels > 7) {
    coord_polar_start <- 0.4
    year_x_coord <- length_labels / 2
  }  else{
    year_x_coord <- length_labels / 2 + 0.5
    coord_polar_start <- 0
  }
  
  # fallback if we have a lot of labels or is uneven
  # we add a dummy item in the middle of the labels to have a nice display
  if (length_labels > 7 |
      length_labels %% 2 != 0) {
    df_questions_label_filtered <- bind_rows(
      # first part
      df_questions_label_filtered[1:floor(length_labels / 2), ],
      # dummy item
      tibble(survey_item = "dummy_item", item_label = ""),
      # second part
      df_questions_label_filtered[ceiling(length_labels / 2):length_labels, ]
    )
  }
  
  # select data + add questions label
  data_menu <- data |>
    select(year, any_of(df_questions_label_filtered$survey_item)) |>
    pivot_longer(-c(year), names_to = "survey_item", values_drop_na = TRUE) |>
    # this adds the dummy item if needed
    inner_join(df_questions_label_filtered, by = join_by(survey_item)) |>
    complete(year, survey_item) |>
    replace_na(list(value = "No", item_label = "")) |>
    mutate(
      text_size = rank(year, ties.method = "min"),
      item_label = factor(
        item_label,
        levels = unique(df_questions_label_filtered$item_label)
      ),
      year_label = as.character(year)
    )
  
  # For the "Recommitting section", keep only the latest year
  if (question_block > "q37") {
    data_menu <- filter(data_menu, year == max(year)) |>
      mutate(year_label = "Recommitting")
  }
  
  # compute graph
  menu_plot <- ggplot(data_menu) +
    geom_hline(aes(yintercept = year),
               colour = pmp_palette$Teal,
               linetype = 3) +
    # just to get space behind the curved text
    ggtext::geom_textbox(
      aes(y = year, label = "<br>"),
      x = year_x_coord,
      fill = pmp_palette$`Dark teal`,
      colour = NA,
      width = unit(2.5, "lines")
    ) +
    geomtextpath::geom_textpath(
      aes(x = year_x_coord, y = year, label = year_label),
      color = pmp_palette$Teal,
      family = "Gilroy ExtraBold",
      size = 6
    ) +
    geom_point(
      data = data_menu |>
        filter(value == "Yes"),
      aes(x = item_label, y = year, #   alpha = year,
          size = year),
      colour = point_color
    ) +
    # To keep point sizes consistent across plots for the same year
    scale_size(
      limits = c(
        Sys.Date() |> lubridate::year() - 5,
        Sys.Date() |> lubridate::year()
      ),
      range = c(3, 12)
    ) +
    scale_fill_manual(values = c("Yes" = point_color, "No" = pmp_palette$`Dark teal`)) +
    scale_y_continuous(limits = c(
      # To have some space in the middle of the circles
      min(data_menu$year, na.rm = TRUE) - 1,
      # To make space between axis labels (possible answers) and the plot:
      # 0.25 so that even if there is one year, there is still a bit of space
      # 0.5 * n year so that it scales nicely across plots with different numbers of years
      max(data_menu$year, na.rm = TRUE) + 0.25 + 0.5 * length(unique(data_menu$year))
    )) +
    scale_x_discrete(
      limits = levels(data_menu$item_label),
      breaks = levels(data_menu$item_label),
      labels = str_wrap(levels(data_menu$item_label), 20)
    ) +
    coord_polar(clip = "off", start = coord_polar_start)  +
    # themes part
    theme_void() +
    theme(
      panel.background = element_rect(fill = pmp_palette$`Dark teal`, color = pmp_palette$`Dark teal`),
      plot.background = element_rect(colour = pmp_palette$`Dark teal`, fill = pmp_palette$`Dark teal`),
      panel.margin = NULL,
      axis.text.x = element_text(
        colour = "#FFFFFF",
        family = "Gilroy ExtraBold",
        size = text_size_theme
      ),
      legend.position = "none",
      plot.margin = unit(c(25, 80, 25, 80), "pt")
    )
  
  # to have the complete background
  cowplot::plot_grid(menu_plot) +
    theme(plot.background = element_rect(colour = pmp_palette$`Dark teal`, fill = pmp_palette$`Dark teal`))
}
