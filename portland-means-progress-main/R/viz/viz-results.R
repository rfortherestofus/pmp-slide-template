barplot_pmp <- function(
  column,
  data = df,
  facet_column = NULL,
  is_percent = FALSE
) {
  data <- data |>
    filter(!is.na(.data[[column]]))

  column_mean <- data |>
    pull({{ column }}) |>
    mean(na.rm = TRUE)

  formatted_label <- if (is_percent) {
    glue("Mean\n{percent(column_mean, scale=1)}")
  } else {
    glue("Mean\n${label_number(scale_cut = cut_short_scale())(column_mean)}")
  }

  breaks <- quantile(data[[column]], probs = seq(0, 1, by = 0.25), na.rm = TRUE)
  data <- data %>%
    mutate(
      bins = cut(
        !!sym(column),
        breaks = breaks,
        include.lowest = TRUE
      )
    )

  bin_labels <-
    levels(data$bins) |>
    as_tibble() |>
    mutate(value = str_remove(value, "\\[")) |>
    mutate(value = str_remove(value, "\\]")) |>
    mutate(value = str_remove(value, "\\(")) |>
    mutate(value = str_remove(value, "\\)")) |>
    separate_wider_delim(
      value,
      delim = ",",
      names = c("low", "high")
    ) |>
    mutate(low = as.numeric(low)) |>
    mutate(high = as.numeric(high)) |>
    mutate(
      low = case_when(
        is_percent ~ scales::percent(low, scale = 1, accuracy = 0.1),
        .default = str_glue("${grkmisc::pretty_num(low, no_dot_zero = TRUE)}")
      )
    ) |>
    mutate(
      high = case_when(
        is_percent ~ scales::percent(high, scale = 1, accuracy = 0.1),
        .default = str_glue("${grkmisc::pretty_num(high, no_dot_zero = TRUE)}")
      )
    ) |>
    mutate(label = str_glue("{low}-{high}")) |>
    pull(label)

  levels(data$bins) <- bin_labels

  p <- ggplot(data, aes(x = bins)) +
    geom_bar_interactive(
      aes(
        tooltip = ifelse(
          ..count.. == 1,
          "1 business",
          paste(..count.., "businesses")
        )
      ),
      fill = "#2a9d8f",
      alpha = 0.9
    ) +
    labs(title = "", x = "", y = "Number of Businesses") +
    theme_minimal(
      base_size = 12
      # , base_family = "Inter Tight"
    ) +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 10),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      axis.title.y = element_text(
        size = 12,
        color = "grey30",
        face = "plain"
        # , family = "Inter Tight"
      ),
      axis.text.x = element_text(
        face = "plain"
        # , family = "Inter Tight"
      ),
      ,
      axis.text.y = element_text(
        face = "plain"
        # , family = "Inter Tight"
      ),
      ,
      plot.caption = element_text(size = 8, color = "gray50", hjust = 0)
    ) +
    scale_y_continuous(labels = scales::label_number(scale = 1, accuracy = 1))

  if (!is.null(facet_column)) {
    p <- p +
      facet_wrap(facet_column, ncol = 1)
  }

  girafe(ggobj = p)
}


beeswarm_pmp <- function(df, facet_col = NULL) {
  if (!is.null(facet_col) && facet_col %in% names(df)) {
    df <- df %>% filter(!is.na(.data[[facet_col]]))
  }

  df <- df %>%
    group_by(Value) %>%
    mutate(n = n()) %>%
    ungroup() %>%
    mutate(
      # Tooltip = str_glue("{n} {if_else(n == 1, "business", "businesses")} had {Value} {if_else(Value == 1, "intern", "interns")}")
      Tooltip = paste0(
        n,
        " ",
        ifelse(n != 1, "businesses", "business"),
        " had ",
        Value,
        " ",
        ifelse(Value != 1, "interns", "intern")
      )
    )

  p <- ggplot(df, aes(x = Category, y = Value, color = Category)) +
    geom_point_interactive(
      aes(tooltip = Tooltip, data_id = Value),
      position = position_jitter(width = 0.3, height = 0.2),
      size = 2.5
    ) +
    theme_minimal(base_size = 14) +
    scale_x_discrete(
      labels = c(
        "interns_eli" = "Emerging Leaders",
        "interns_noneli" = "Other",
        "interns_wsi" = "Summer Works"
      )
    ) +
    scale_color_brewer(palette = "Dark2") +
    theme(
      legend.position = "none",
      axis.title.x = element_blank(),
      axis.title.y = element_text(size = 12)
    ) +
    labs(y = "Number of interns")

  if (!is.null(facet_col)) {
    p <- p +
      facet_wrap(as.formula(paste("~", facet_col)), ncol = 1) + # Ensure 1 column
      theme(axis.text.x = element_text(size = 8))
  }

  girafe(ggobj = p)
}
