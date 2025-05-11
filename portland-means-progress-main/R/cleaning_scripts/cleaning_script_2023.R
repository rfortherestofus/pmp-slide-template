# --------------------- #
# Cleaning script 2023 #
# --------------------- #

library(tidyverse)
library(unpivotr)

# Import data -------------------------------------------------------------
# import with tidyxl
df_data_cells_2023 <-
  tidyxl::xlsx_cells("data-raw/RfortheRestofUs_PMPSurveyData_Clean_3.6.24.xlsx")

# Clean data --------------------------------------------------------------
df_data_cleaned_2023 <- df_data_cells_2023 |>
  # filter(!is_blank) |>
  behead("up-left", "group_name") |>
  behead("up-left", "col_name") |>
  behead("up", "var_type") |>
  behead("left", "business_name")  |>
  mutate(content = coalesce(character, as.character(numeric))) |>
  select(group_name,
         col_name,
         var_type,
         business_name,
         content)

# Export to build data dictionary -----------------------------------------
df_data_cleaned_2023 |>
  distinct(group_name, col_name, var_type) |>
  writexl::write_xlsx("data-dictionary/2023_data-dictionary_raw.xlsx")

# Apply data dictionary ---------------------------------------------------
# load data dict
data_dict_2023 <-
  readxl::read_xlsx("data-dictionary/2023_data-dictionary.xlsx") |>
  mutate(
    col_name_join = str_remove_all(str_to_lower(col_name), "\\s"),
    var_type_join = str_remove_all(str_to_lower(var_type), "\\s")
  ) |>
  select(group_name, col_name_join, var_type_join, final_name)

# join to data
df_data_cleaned_2023_named <- df_data_cleaned_2023 |>
  mutate(
    col_name_join = str_remove_all(str_to_lower(col_name), "\\s"),
    var_type_join = str_remove_all(str_to_lower(var_type), "\\s")
  ) |>
  left_join(data_dict_2023, by = join_by(group_name, col_name_join, var_type_join))

# check join
df_data_cleaned_2023_named |>
  filter(is.na(final_name)) |>
  distinct(col_name, var_type) |>
  print(n = Inf)

# list of menu variables
list_menu_vars <- c(
  "progress_culture",
  "progress_none",
  "progress_purchasing",
  "progress_work",
  "practices_cobid_purchasing",
  "practices_dollar_purchasing",
  "practices_mercatus_purchasing",
  "practices_preference_purchasing",
  "practices_relations_purchasing",
  "practices_targets_purchasing",
  "practices_tracking_purchasing",
  "practices_accountability_culture",
  "practices_tracking_culture",
  "practices_budget_culture",
  "practices_training_culture",
  "practices_designated_culture",
  "practices_supportive_culture",
  "practices_analysispay_culture",
  "practices_analysisexp_culture",
  "practices_growth_culture",
  "practices_feedback_culture",
  "practices_affinity_culture",
  "practices_corrective_culture",
  "practices_roadmap_culture",
  "practices_flexible_culture",
  "practices_equity_culture",
  "experience_leaders",
  "experience_summer",
  "experience_internal",
  "experience_else",
  "experience_noparticipate",
  "experience_notsure",
  "experience_else_text",
  "practices_onboarding_work",
  "practices_hiring_work",
  "practices_support_work",
  "practices_training_work",
  "practices_mentor_work",
  "practices_retention_work",
  "practices_interviews_work",
  "steps_pay_ezone",
  "steps_hire_ezone",
  "steps_school_ezone",
  "steps_highed_ezone",
  "steps_industry_ezone",
  "steps_groups_ezone",
  "steps_jobs_ezone",
  "steps_nonprof_ezone",
  "steps_initiative_ezone",
  "steps_public_ezone",
  "steps_smallbus_ezone",
  "steps_other_ezone",
  "steps_none_ezone",
  "steps_other_text_ezone",
  "continue_accountability_culture",
  "continue_tracking_culture",
  "continue_budget_culture",
  "continue_training_culture",
  "continue_designated_culture",
  "continue_supportive_culture",
  "continue_analysispay_culture",
  "continue_analysisexp_culture",
  "continue_growth_culture",
  "continue_feedback_culture",
  "continue_affinity_culture",
  "continue_corrective_culture",
  "continue_roadmap_culture",
  "continue_flexible_culture",
  "continue_equity_culture",
  "continue_mercatus_purchasing",
  "continue_cobid_purchasing",
  "continue_targets_purchasing",
  "continue_tracking_purchasing",
  "continue_dollar_purchasing",
  "continue_preference_purchasing",
  "continue_relations_purchasing",
  "work_leaders",
  "work_summer",
  "work_intern",
  "work_else",
  "work_notsure",
  "continue_onboarding_work",
  "continue_hiring_work",
  "continue_support_work",
  "continue_training_work",
  "continue_mentor_work",
  "continue_retention_work",
  "continue_interviews_work",
  "commit_work",
  "commit_purchasing",
  "commit_culture",
  "commit_notsure"
)

# clean + pivot
df_data_cleaned_2023_named_pivot <- df_data_cleaned_2023_named |>
  select(business_name, content, final_name) |>
  mutate(content = case_match(content, "yes" ~ "Yes",
                              "no" ~ "No",
                              .default = content)) |>
  filter(!is.na(final_name)) |>
  pivot_wider(names_from = final_name, values_from = content) |>
  mutate(across(
    any_of(list_menu_vars),
    \(x)case_when(!is.na(x) ~ "Yes", .default = "No")
  ))

# check
df_data_cleaned_2023_named_pivot |>
  count(business_name)

# Combine with previous years ---------------------------------------------
# load data
df_all_years_init <- read_rds("data/pp_2019-2022_clean.rds")

# get type
list_numeric_vars <- df_all_years_init |>
  mutate(across(everything(), typeof)) |>
  slice(1) |>
  pivot_longer(everything()) |>
  filter(value == "double") |>
  pull(name)

# recode
df_data_cleaned_2023_recode <- df_data_cleaned_2023_named_pivot |>
  mutate(across(any_of(list_numeric_vars),
                as.numeric)) |>
  rename(business = business_name) |>
  mutate(year = "2023")

# combine + clean business names that are different from other years
# --> always use the latest name
df_all_years_full <- df_all_years_init |>
  bind_rows(df_data_cleaned_2023_recode) |>
  mutate(
    business = case_match(
      business,
      "A&K Designs" ~ "A & K Designs, Inc." ,
      "Adpearance" ~ "Adpearance & Foureyes",
      "Bridgecity Steel" ~ "Bridge City Steel",
      "Workforce SW Washington" ~ "Workforce Southwest Washington",
      "Wieden + Kennedy" ~ "Wieden & Kennedy",
      "Thesis Agency" ~ "Thesis",
      "Brown & Brown Northwest Insurance" ~ "Brown & Brown",
      "Cook Security Group" ~ "Cook Solutions Group",
      "Olympia Meats" ~ "Olympia Meats, LLC",
      "Nossa Familia" ~ "Nossa Familia Coffee",
      "Mental Health & Addiction Association of Oregon (M" ~ "Mental Health & Addiction Association of Oregon",
      "Mental Health & Addiction Association of Oregon (MHAAO)" ~ "Mental Health & Addiction Association of Oregon",
      "City of Roses Disposal" ~ "City of Roses Disposal & Recycling INC",
      "ECOnorthwest" ~ "ECONorthwest",
      "Oregon Bioscience Incubator (OBI) & OTRADI" ~ "Oregon Bioscience Incubator and OTRADI",
      "Studio Petretti Architecture" ~ "Studio Petretti Architecture, LLC",
      "Sumner Street Shea" ~ "Sumner Street Shea LLC",
      "The Portland Clinic" ~ "The Portland Clinic, LLP",
      .default = business
    )
  )

# Data check --------------------------------------------------------------
# # check if we have all years on business with start before 2023
# df_data_cleaned_2023_named_pivot |>
#   select(business_name, year_signed_up) |>
#   mutate(year_signed_up = as.numeric(year_signed_up),
#          n_waited = 2023 - year_signed_up + 1) |>
#   left_join(
#     df_all_years_full |>
#       distinct(year, business) |>
#       count(business, name = "n_real"),
#     by = join_by(business_name == business)
#   ) |>
#   filter(n_waited > n_real) |>
#   print(n = Inf)
#
# # to check all
# df_all_years_full |>
#   select(business, year) |>
#   arrange(business, year) |>
#   print(n = Inf)

# Export ------------------------------------------------------------------
write_rds(df_all_years_full, "data/pp_2019-2023_clean.rds")
