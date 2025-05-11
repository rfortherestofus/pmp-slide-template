# --------------------------- #
# Generate reports #
# --------------------------- #

library(here)
library(tidyverse)

# Setup -------------------------------------------------------------------
source(here("R/viz/setup.R"))

# Delete previous reports -------------------------------------------------
# walk(list.files("reports/pdf/2023", full.names = TRUE),
#      file.remove)

# List of businesses ------------------------------------------------------
df_list_business <- read_rds(here("data/pp_2019-2024_clean.rds")) |>
  filter(!is.na(business) & year == "2024") |>
  distinct(business, .keep_all = TRUE) |>
  # comment to get all reports
  mutate(business_to_lower = janitor::make_clean_names(business)) |>
  select(business_to_lower, business) |>
  filter(!business_to_lower %in% (list.files("reports/pdf/2024") |>
                                    str_remove_all(".pdf")))

list_business <- df_list_business |>
  pull(business)

# Render report -----------------------------------------------------------
# function
render_report_pmp <- function(business_name, year) {
  # render
  rmarkdown::render(
    input = here("R/report/pmp_report.Rmd"),
    output_dir = here("reports/html/", year),
    output_file = paste0(janitor::make_clean_names(business_name), ".html"),
    output_format = pagedown::html_paged(
      css = here("assets/layout/main.css"),
      number_sections = FALSE
    ),
    params = list(business = business_name, report_year = year)
  )
  
  # print
  pagedown::chrome_print(input = here(
    paste0(
      "reports/html/",
      year,
      "/",
      janitor::make_clean_names(business_name),
      ".html"
    )
  ), output = here(
    paste0(
      "reports/pdf/",
      year,
      "/",
      janitor::make_clean_names(business_name),
      ".pdf"
    )
  ))
}

# render
map(list_business,
    year = 2024,
    possibly(render_report_pmp, otherwise = NULL))

# beep

# beepr::beep()


# Remove all HTML ---------------------------------------------------------
walk(list.files("reports/html/2024", full.names = TRUE),
     file.remove)

# Check if all reports has been generated ---------------------------------
df_list_business |>
  mutate(
    business_clean_names = janitor::make_clean_names(business),
    ind_ok = if_else(business_clean_names %in% (
      list.files("reports/pdf/2024") |>
        str_remove_all(".pdf")
    )
    , 1, 0)
  ) |>
  select(business, ind_ok) |>
  print(n = Inf)
