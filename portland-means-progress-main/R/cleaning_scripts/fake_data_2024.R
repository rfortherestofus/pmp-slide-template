# -------------------- #
# Fake data 2024 #
# -------------------- #

library(tidyverse)

# Import ------------------------------------------------------------------
# 2023 data
df_data_2023 <- read_rds("data/pp_2019-2023_clean.rds") |>
  filter(year == 2023)

# 2024 contact file
df_contact_2024 <- read_csv("data-raw/contact_files/2024 PMP Businesses and Commitments(Sheet1).csv") |>
  select(`Business Name`, `BIPOC Owned`, Woman_Owned, Cluster, `Primary Contact Email`) |>
  janitor::clean_names() |>
  rename(business = business_name) |>
  distinct()

# 2024 data dictionary
df_data_dict_2024 <- readxl::read_xlsx("assets/data-dictionary/2024_data-dictionary.xlsx")

# raw responses 2024
df_responses_raw_2024 <- read_rds("data-raw/data_files/responses_raw_2024.rds")

# Clean -------------------------------------------------------------------
df_data_2023_cleaned <- df_data_2023 |>
  select(business, any_of(df_data_dict_2024$final_name)) |>
  mutate(across(everything(), as.character)) |>
  pivot_longer(-business) |>
  right_join(
    df_data_dict_2024 |>
      select(final_name),
    by = join_by(name == final_name)
  ) |>
  complete(business, name) |>
  pivot_wider(names_from = name, values_from = value) |>
  mutate(across(
    c(
      dollars_spent_purchases,
      percentage_purchase,
      interns_eli,
      interns_wsi,
      interns_noneli,
      spend_locally_portland_ezone
    ),
    as.numeric
  )) |>
  # adding infos from 2024
  left_join(df_contact_2024, by = join_by(business)) |>
  mutate(
    bipoc_owned = case_when(bipoc_owned == 1 ~ "Yes",
      .default = "No"
    ),
    woman_owned = case_when(woman_owned == 1 ~ "Yes",
      .default = "No"
    ),
    n_employees = sample(1:100, size = 135, replace = TRUE)
  )

nrows <- nrow(df_data_2023_cleaned)
df_fake_completion_rates <- df_data_2023_cleaned |>
  select(c(business, ezone, primary_contact_email)) |>
  mutate(
    has_opened = c(rep("No", 10), rep("Yes", nrows - 10)),
    has_started = c(rep("No", 40), rep("Yes", nrows - 40)),
    has_finished = c(rep("No", 90), rep("Yes", nrows - 90)),
  )

# Clean 2024 data ---------------------------------------------------------
df_responses_cleaned_2024 <- df_responses_raw_2024 |>
  mutate(across(everything(), as.character)) |>
  pivot_longer(-id) |>
  mutate(value = case_when(!value %in% c("", "No", "N/A") ~ value)) |>
  inner_join(
    df_data_dict_2024 |>
      select(raw_name, final_name) |>
      add_row(raw_name = "id", final_name = "id") |>
      add_row(raw_name = "firstname", final_name = "firstname"),
    by = join_by(name == raw_name)
  ) |>
  select(-name) |>
  pivot_wider(names_from = final_name, values_from = value) |>
  # intentional to replace character
  mutate(across(
    c(
      dollars_spent_purchases,
      percentage_purchase,
      interns_eli,
      interns_wsi,
      interns_noneli,
      spend_locally_portland_ezone,
      pmpemployees
    ),
    as.numeric
  )) |>
  rename(business = firstname)

# Export ------------------------------------------------------------------
write_rds(df_data_2023_cleaned, "data/fake_data_2024.rds")
write_rds(df_fake_completion_rates, "data/fake_completion_data_2024.rds")
