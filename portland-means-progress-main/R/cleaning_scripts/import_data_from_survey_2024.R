# -------------------- #
# Import data from LimeSurvey #
# -------------------- #

library(limer)
library(tidyverse)

# Connect to API ----------------------------------------------------------
options(lime_api = 'https://rfortherestofus.limesurvey.net/admin/remotecontrol')
options(lime_username = Sys.getenv("LIMESURVEY_USER"))
options(lime_password = Sys.getenv("LIMESURVEY_PASSWORD"))

# Log in
invisible(get_session_key())

# Get survey responses ----------------------------------------------------

# get survey ID
# call_limer(method = "list_surveys")
survey_id <- 179359

# get responses once
df_responses_init <- get_responses(survey_id, sCompletionStatus = "all")

# get participants responses -> could also be taken from participants data
df_responses_fields <- get_responses(
  survey_id,
  aFields = c(
    "id",
    "token",
    "firstname" ,
    "lastname",
    "email",
    "attribute_1",
    "attribute_2",
    "attribute_3",
    "attribute_4"
  ),
  sCompletionStatus = "all"
)

# merge
df_responses_raw <- df_responses_fields |>
  left_join(df_responses_init, by = join_by(id, token)) |>
  as_tibble() |>
  janitor::clean_names() |>
  # swap business between Plum Deluxe and Culture Revision
  # case_when exclude treated cases so it's ok
  mutate(
    firstname = case_when(
      firstname == "Plum Deluxe Tea" ~ "Culture Revision",
      firstname == "Culture Revision" ~ "Plum Deluxe Tea",
      .default = firstname
    )
  )

# Clean responses ---------------------------------------------------------
# goal is to have the same format as last year fake data for the dashboard

# data dictionary
data_dict_2024 <-
  readxl::read_xlsx("assets/data-dictionary/2024_data-dictionary.xlsx")

# clean answers
df_responses_clean <- df_responses_raw |>
  mutate(across(everything(), as.character)) |>
  pivot_longer(-id) |>
  left_join(data_dict_2024, by = join_by(name == raw_name)) |>
  mutate(final_name = coalesce(final_name, name)) |>
  select(id, final_name, value) |>
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
      n_employees
    ),
    as.numeric
  )) |>
  rename(business = firstname)

# Add participants info ---------------------------------------------------
# load
df_participants_info <- read_csv("data/participants_info.csv") |>
  select(business = firstname,
         bipoc_owned,
         woman_owned,
         cluster,
         email,
         ezone = attribute_4) |>
  separate_longer_delim(email, delim = ";") |>
  group_by(business) |>
  slice(1) |>
  ungroup() |>
  rename(primary_contact_email = email)

# join
df_responses_clean_info <- df_responses_clean |>
  select(-ezone) |>
  inner_join(df_participants_info, by = join_by(business)) |>
  mutate(
    bipoc_owned = case_when(bipoc_owned == 1 ~ "Yes", .default = "No"),
    woman_owned = case_when(woman_owned == 1 ~ "Yes", .default = "No")
  )

# Completion rates --------------------------------------------------------
df_completion_rates <- df_responses_clean  |>
  select(-ezone) |>
  full_join(df_participants_info, by = join_by(business)) |>
  mutate(
    has_started =  if_else(!is.na(startdate), "Yes", "No"),
    has_finished = if_else(submitdate != "", "Yes", "No"),
  ) |>
  select(business,
         ezone,
         primary_contact_email,
         has_started,
         has_finished)

# Export raw survey data --------------------------------------------------
write_rds(df_responses_raw,
          "data-raw/data_files/responses_raw_2024.rds")

# Export cleaned survey data ----------------------------------------------
write_rds(df_responses_clean_info, "data/responses_2024.rds")

write_rds(df_completion_rates, "data/completion_rates_2024.rds")
