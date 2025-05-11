# --------------------- #
# Cleaning script 2024 #
# --------------------- #

# this script create a new dataset which is cleaner that the one in previous years
# goal is to have a good basis to start

library(tidyverse)

# Import data -------------------------------------------------------------
# valid name is last year name
df_historical_data <- read_rds("data/pp_2019-2023_clean.rds") |>
  mutate(
    business = case_match(
      business,
      "A & K Designs, Inc." ~ "A&K Designs",
      "Accretech SBS, Inc." ~ "Accretech",
      "Brown & Brown" ~ "Brown & Brown Northwest Insurance",
      "City of Roses Disposal & Recycling INC" ~ "City of Roses Disposal & Recycling",
      "Adpearance & Foureyes"                          ~ "Adpearance",
      # "AshbeanPDX"                                     ~"",
      # "Aesthete Tea"~ "",
      "Community Energy Labs "                         ~
        "Community Energy Labs, Inc",
      # "Coy & Co."                                      ~"",
      "ECONorthwest"                                   ~
        "ECOnorthwest",
      "HAB Sauce LLC"                                  ~
        "Hab Sauce LLC",
      "HiFi Sound Cycling Components"                  ~
        "HIFI SOUND CYCLING COMPONENTS",
      "MAKE & MARY, LLC"                               ~
        "Make & Mary",
      "Mental Health & Addiction Association of Oregon" ~
        "Mental Health & Addiction Association of Oregon (MHAAO)",
      "Micropump"                                      ~
        "Micropump Inc. (IDEX)",
      "Nossa Familia Coffee"                           ~
        "Nossa Familia",
      "OKAPI Reusables, LLC"                           ~
        "okapi reusables",
      "Olympia Meats, LLC"                             ~ "Olympia Provisions",
      "OpConnect"                                      ~
        "OpConnect, Inc",
      "Oregon Bioscience Incubator and OTRADI"         ~
        "Oregon Bioscience Incubator (OBI) & OTRADI",
      "Peninsula Truck Lines, Inc"                     ~
        "Peninsula Truck Lines, Inc.",
      # "Portland Garment Factory"                       ~"",
      "Salt & Straw"                                   ~
        "Salt & Straw LLC",
      "Studio Petretti Architecture, LLC"              ~
        "Studio Petretti Architecture LLC",
      "Sumner Street Shea LLC"                         ~
        "Sumner Street Shea",
      "SurveyMonkey"                                   ~
        "Survey Monkey (previously Momentive)",
      "The Portland Clinic, LLP"                       ~
        "The Portland Clinic",
      # "underU4men"                                     ~"",
      "VisionGift"                                     ~ "Lions VisionGift",
      # "Weinstein PR"                                   ~"",
      "Wieden & Kennedy"                               ~
        "Wieden + Kennedy",
      "Workforce Southwest Washington"                 ~
        "Workforce SW Washington",
      # "ZGF" ~"",
      ,
      .default = business
    )
  )

# first
# source("R/cleaning_scripts/import_data_from_survey_2024.R")
df_data_2024 <- read_rds("data/responses_2024.rds") |>
  mutate(percentage_purchase = as.character(percentage_purchase),
         year = "2024") |>
  replace_na(list(
    action_work = "No",
    action_purchasing = "No",
    action_culture = "No"
  )) |>
  mutate(
    meaningful_action = str_replace_all(meaningful_action, ">", ""),
    meaningful_action = str_replace_all(meaningful_action, "\\*", ""),
    meaningful_action = str_replace_all(meaningful_action, '"' , ""),
    meaningful_action = str_replace_all(meaningful_action, "-" , ""),
    meaningful_action = if_else(
      business == "Mother Tree International LLC",
      "In 2024, our organization took meaningful action to address racial equity by collaborating on the training and mentoring of 25 BIPOC doulas, supporting them on the path to becoming State Registered Traditional Health Worker (THW) doulas in 2025. We also partnered with Black Futures and Senator Lisa Reynolds to advocate for the MOMNIBUS legislation, aimed at addressing maternal health disparities. Additionally, we produced a diverse and inclusive Benefits of a Doula video, specifically designed to reach BIPOC and underserved families on Medicaid, highlighting the critical role doulas play in improving birth outcomes.",
      meaningful_action
    )
  )

read_rds("data/responses_2024.rds") |> 
  filter(str_detect(business, "Brown & Brown")) |> 
  select(continue_priority_culture)

# Bind data ---------------------------------------------------------------
df_data_all_years <- bind_rows(df_historical_data, df_data_2024) |>
  arrange(business, year)

# Export ------------------------------------------------------------------
write_rds(df_data_all_years, "data/pp_2019-2024_clean.rds")
