# ----------------- #
# Participants data #
# ----------------- #

library(tidyverse)

# Import ------------------------------------------------------------------
# participant's data
df_participants_data_init <- readxl::read_xlsx("data-raw/contact_files/2024 PMP Businesses and Commitments.xlsx") |>
  janitor::clean_names() |>
  filter(!is.na(business_name) & !is.na(primary_contact_email))

# last year data
df_data_2023 <- read_rds("data/pp_2019-2023_clean.rds") |>
  filter(year == 2023) |>
  select(business, commit_work, commit_purchasing, commit_culture) |>
  mutate(
    across(starts_with("commit"), \(x)case_when(x == "Yes" ~ "Yes")),
    business = case_match(
      business,
      "A & K Designs, Inc." ~ "A&K Designs",
      "Accretech SBS, Inc." ~ "Accretech",
      "Brown & Brown" ~ "Brown & Brown Northwest Insurance",
      "City of Roses Disposal & Recycling INC" ~ "City of Roses Disposal & Recycling",
      "Adpearance & Foureyes"                          ~"Adpearance",
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
      "VisionGift"                                     ~"Lions VisionGift",
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

# --> to continue with final list

# Clean -------------------------------------------------------------------
# put the same token for multiples participants in the same compagny
# + add language about this being the same survey
df_participants_data_clean <- df_participants_data_init |>
  pivot_longer(
    c(primary_contact_email, cc_email, cc_extra_emails),
    names_to = "type_email",
    values_to = "mail"
  ) |>
  separate_longer_delim(mail, delim = ";") |>
  filter(!is.na(mail) & mail != "") |>
  select(
    firstname = business_name,
    lastname = mail_merge_names,
    email = mail,
    attribute_1 = x2024_work_experience,
    attribute_2 = x2024_intentional_purchasing,
    attribute_3 = x2024_culture_change,
    attribute_4 = ezone,
    bipoc_owned,
    woman_owned,
    cluster
  ) |>
  mutate(across(starts_with("attribute"), \(x)case_when(x == 1 ~ "Yes")),
         email = str_trim(email)) |>
  distinct() |> 
  group_by(
    firstname,
    lastname,
    attribute_1,
    attribute_2,
    attribute_3,
    attribute_4,
    bipoc_owned,
    woman_owned,
    cluster
  ) |>
  summarise(email = paste(email, collapse = ";", sep = ""),
            .groups = "drop")

# add last year data
df_participants_data_full <- df_participants_data_clean |>
  # full_join(df_data_2023, by = join_by(firstname == business)) |>
  left_join(df_data_2023, by = join_by(firstname == business)) |>
  mutate(
    attribute_1 = coalesce(attribute_1, commit_work),
    attribute_2 = coalesce(attribute_2, commit_purchasing),
    attribute_3 = coalesce(attribute_3, commit_culture)
  ) |>
  select(-starts_with("commit")) |> 
  # remove business that aren't in it
  filter(
    !firstname %in% c(
      "Woonwinkel",
      # "Nike",
      "The Good Group",
      "Abbott & Associates, Inc.",
      "Miss'ipi Chef",
      "JJT Studios",
      "Mazarine treyz dba wild woman fundraising",
      "WE Communications",
      "Gladstone Street Pizza",
      "Not Your Average American, LLC",
      "okapi reusables",
      "North"
    )
  ) 

# check matching
# df_participants_data_full |>
#   filter(is.na(lastname)) |>
#   pull(firstname)
# 
# df_participants_data_clean |>
#   arrange(firstname) |>
#   pull(firstname) |>
#   unique()

# Export ------------------------------------------------------------------
write_csv(df_participants_data_full, "data/participants_info.csv")
