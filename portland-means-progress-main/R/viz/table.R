#' @title GT table theme for Portland Means Progress
#' @name pmp_table_theme
#' @param gt_tbl a GT table
#' @return a GT table with a custom theme
#' @export
pmp_table_theme <- function(gt_tbl) {
  gt_tbl |>
    sub_missing(missing_text = "No data") |>
    opt_all_caps() |>
    opt_table_font(
      font = list(
        google_font("Inter"),
        google_font("Lato"),
        default_fonts()
      )
    ) |>
    opt_row_striping() |>
    tab_options(
      table.width = pct(100),
      row.striping.background_color = "#fafafa",
      table_body.hlines.color = "#f6f7f7",
      source_notes.font.size = 12,
      table.font.size = 16,
      heading.align = "left",
      heading.title.font.size = 24,
      table.border.top.color = "white",
      table.border.top.width = px(3),
      data_row.padding = px(7),
    )
}

#' @title Summary table for Yes/No questions
#' @name summary_table
#' @export
summary_table <- function(summary_cols, data, group_cols = NULL) {
  # Store the original data for reference
  df <- data

  if (!is.null(group_cols)) {
    # Calculate the count of each group
    group_counts <- data |>
      group_by(across(all_of(group_cols))) |>
      summarise(group_total = n(), .groups = "drop")

    # Calculate yes percentages by group
    tbl <- data |>
      group_by(across(all_of(group_cols))) |>
      summarise(
        across(
          all_of(summary_cols),
          ~ sum(. == "Yes", na.rm = TRUE) / nrow(df) * 100,
          .names = "{.col}_pct"
        ),
        across(
          all_of(summary_cols),
          ~ sum(. == "Yes", na.rm = TRUE),
          .names = "{.col}_count"
        ),
        n_valid = n(),
        .groups = "drop"
      ) |>
      left_join(group_counts, by = group_cols)

    # Transform to wide format
    tbl_t <- tbl |>
      pivot_longer(
        cols = -c(all_of(group_cols), n_valid, group_total),
        names_to = c("Metric", ".value"),
        names_pattern = "(.+)_(.+)"
      ) |>
      mutate(
        formatted = paste0(round(pct, 1), "% (", count, " businesses)"),
        Metric = map_chr(Metric, column_to_description)
      ) |>
      select(all_of(c(group_cols, "Metric", "formatted"))) |>
      pivot_wider(
        names_from = all_of(group_cols),
        values_from = "formatted"
      ) |>
      filter(Metric != "None")
  } else {
    # Calculate overall percentages
    n_answers <- data |>
      filter(if_any(all_of(summary_cols), ~ !is.na(.))) |>
      nrow()
    n_answers_percent <- round(n_answers / nrow(data) * 100, 1)

    tbl <- data |>
      summarise(
        across(
          all_of(summary_cols),
          ~ sum(. == "Yes", na.rm = TRUE) / nrow(df) * 100,
          .names = "{.col}_pct"
        ),
        across(
          all_of(summary_cols),
          ~ sum(. == "Yes", na.rm = TRUE),
          .names = "{.col}_count"
        )
      )

    # Transform to long format
    tbl_t <- tbl |>
      pivot_longer(
        cols = everything(),
        names_to = c("Metric", ".value"),
        names_pattern = "(.+)_(.+)"
      ) |>
      mutate(
        Percentage = paste0(round(pct, 1), "% (", count, " businesses)"),
        Metric = map_chr(Metric, column_to_description)
      ) |>
      select(Metric, Percentage) |>
      filter(Metric != "None")
  }

  # Generate the final GT table
  if (!is.null(group_cols)) {
    gt_table <- tbl_t |>
      gt() |>
      pmp_table_theme()

    # Get total responses per group for source note
    group_responses <- data |>
      filter(if_any(all_of(summary_cols), ~ !is.na(.))) |>
      count(across(all_of(group_cols))) |>
      mutate(pct = round(n / nrow(data) * 100, 1))

    # Create source note with response counts by group
    source_text <- paste0(
      "Responses from ",
      paste(
        sapply(1:nrow(group_responses), function(i) {
          paste0(
            group_responses[[group_cols]][i],
            ": ",
            group_responses$n[i],
            " (",
            group_responses$pct[i],
            "%)"
          )
        }),
        collapse = "; "
      ),
      " businesses as of ",
      current_date,
      "."
    )

    gt_table <- gt_table |>
      tab_source_note(source_note = source_text)
  } else {
    gt_table <- tbl_t |>
      gt() |>
      pmp_table_theme() |>
      tab_source_note(
        source_note = glue::glue(
          "Responses from {n_answers} ({n_answers_percent}%) businesses as of {current_date}."
        )
      )
  }

  return(gt_table)
}

#' @title Format table with quantitative data
#' @name format_numerics
#' @export
format_numerics <- function(tbl) {
  tbl <- tbl |>
    fmt_number(decimals = 1, suffixing = TRUE)

  return(tbl)
}

#' @title Format table with qualitative data
#' @name format_qualitative
#' @export
format_qualitative <- function(tbl, page_size_default = 5) {
  tbl <- tbl |>
    opt_interactive(
      page_size_default = page_size_default,
      page_size_values = c(5, 10, 50),
      use_search = TRUE,
      use_resizers = TRUE,
      use_highlight = TRUE,
      use_compact_mode = TRUE,
      use_text_wrapping = TRUE,
      use_page_size_select = TRUE
    ) |>
    pmp_table_theme()

  return(tbl)
}

column_to_description <- function(column) {
  mapping <- c(
    progress_culture = "Culture",
    progress_none = "None",
    progress_purchasing = "Purchasing",
    progress_work = "Work",
    practices_onboarding_work = "Onboarding",
    practices_hiring_work = "Hiring",
    practices_mentor_work = "Mentoring",
    practices_none_work = "None",
    practices_interviews_work = "Interviews",
    practices_training_work = "Training",
    practices_support_work = "Support",
    practices_retention_work = "Retention",
    practices_cobid_purchasing = "COBID",
    practices_dollar_purchasing = "Dollar",
    practices_mercatus_purchasing = "Mercatus",
    practices_none_purchasing = "None",
    practices_preference_purchasing = "Preference",
    practices_relations_purchasing = "Relations",
    practices_targets_purchasing = "Targets",
    track_dollars_spent = "Track dollars spent",
    dollars_spent_purchases = "Dollars spent purchases",
    percentage_purchase = "Percentage purchase",
    practices_accountability_culture = "Accountability",
    practices_affinity_culture = "Affinity",
    practices_analysisexp_culture = "Analysis of pay",
    practices_analysispay_culture = "Analysis of workplace experience",
    practices_budget_culture = "Budget",
    practices_designated_culture = "People responsible of DEI efforts",
    practices_feedback_culture = "Feedback",
    practices_growth_culture = "Growth",
    practices_none_culture = "None",
    practices_supportive_culture = "Supportive",
    practices_tracking_culture = "Tracking",
    practices_training_culture = "Training",
    steps_fund_ezone = "Fund",
    steps_groups_ezone = "Groups",
    steps_highed_ezone = "Highed",
    steps_hire_ezone = "Hire",
    steps_industry_ezone = "Participation in industry",
    steps_initiative_ezone = "Initiative",
    steps_jobs_ezone = "Jobs",
    steps_none_ezone = "None",
    steps_nonprof_ezone = "Sponsorships non profits",
    steps_other_ezone = "Other",
    steps_pay_ezone = "Pay",
    steps_school_ezone = "School",
    steps_smallbus_ezone = "Support small businesses",
    connect = "Connect",
    # Q18
    recommit = "Recommit to PMP",
    # Q19
    action_culture = "Culture",
    action_purchasing = "Purchasing",
    action_work = "Work",
    # Q20
    work_intern_other = "Other",
    work_intern_unsure = "Unsure",
    work_leaders = "Emerging Leaders/The Script",
    work_summer = "SummerWorks/Youth WEX",
    # Q21
    continue_mercatus_purchasing = "Mercatus",
    continue_cobid_purchasing = "COBID",
    continue_targets_purchasing = "Targets",
    continue_tracking_purchasing = "Tracking",
    continue_none_purchasing = "None",
    continue_relations_purchasing = "Relations",
    continue_preference_purchasing = "Preference",
    continue_dollar_purchasing = "Dollar",
    # Q23
    continue_priority_culture = "Priority"
  )
  return(mapping[column])
}
