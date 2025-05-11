
library(tidyverse)
library(haven)
library(readxl)
library(janitor)
library(labelled) #to recode haven labelled vars
library(purrr)
library(here)
library(rio)


# 2019 data ---------------------------------------------------------------

# Read in raw data

d_19 <- read_excel(here("data-raw", 
                            "Prosper Portland PMP Company Survey--00931--raw data--January 2020.xls")) 

# Read in data dictionary

dict_19 <- read_excel("data-dictionary/2019_data-dictionary.xlsx") 


# Rename variables

dict_names_19 <- dict_19 %>%
  select(final_name, survey_var_name) %>%
  deframe()

d_19 <- d_19 %>%
  rename(all_of(dict_names_19))

names(d_19)

# Drop unnecessary variables

d_19_drop <- dict_19 %>%
  filter(drop == "yes") %>%
  select(final_name) %>%
  pull()

d_19 <- d_19 %>%
  select(-all_of(d_19_drop))


# Check out of range variables

## dollars_spent_purchases_unknown (should be 0-1)
## percentage_purchase (should be 1-98)
## practices_accountability_culture (should be 0-1)
## practices_tracking_culture (should be 0-1)
## track_demo_emp (should be 1-98)
## track_demo_lead (should be 1-98)
## share_meaningful_action and recommit (should be 1-2)
## support_training and support_network (should be 0-1)

d_19 %>%
  select(dollars_spent_purchases_unknown, percentage_purchase, practices_accountability_culture,
         practices_tracking_culture, track_demo_emp, track_demo_lead, share_meaningful_action,
         recommit, support_training, support_network) %>%
  map(tabyl)

# Add 2019 to variables

d_19 <- d_19 %>%
  rename_with(~ base::paste0(., "_2019"), -business)


# 2020 data ---------------------------------------------------------------

# Read in raw data

d_20 <- read_sav(here("data-raw", "Prosper Portland PMP Company Survey--00958--Data ALL--January 2021.sav"), encoding="latin1") 

# Read in data dictionary

dict_20 <- read_excel("2020_data-dictionary.xlsx") 

# Rename variables

dict_names_20 <- dict_20 %>%
  select(final_name, survey_var_name) %>%
  deframe()

d_20 <- d_20 %>%
  rename(all_of(dict_names_20))

names(d_20)

# Recode

## Check ezone and connect and percentage_purchase

d_20 %>%
  tabyl(ezone)

d_20 %>%
  tabyl(connect)

d_20 %>%
  tabyl(percentage_purchase)

## Recode

d_20 <- d_20 %>%
  mutate(ezone = recode(ezone, `2` = 0),
         connect = recode(connect, `4` = 98),
         percentage_purchase = recode(percentage_purchase, `8` = 98))

# Drop unnecessary variables

d_20_drop <- dict_20 %>%
  filter(drop == "yes") %>%
  select(final_name) %>%
  pull()

d_20 <- d_20 %>%
  select(-all_of(d_20_drop))

# Add 2020 to variables

d_20 <- d_20 %>%
  rename_with(~ base::paste0(., "_2020"), -business)


# 2021 data ---------------------------------------------------------------

d_21 <- read_sav(here("data-raw", "Prosper Portland PMP Company Survey--01061--Modified data--2022.sav"))

# Read in data dictionary

dict_21 <- read_excel("2021_data-dictionary.xlsx")

# Rename variables

dict_names_21 <- dict_21 %>%
  select(final_name, dhm_rename) %>%
  deframe()

d_21 <- d_21 %>%
  rename(all_of(dict_names_21))

names(d_21)

# Recode

## Check bipoc_owned, woman_owned, techtown_numtext and ezone_numtext

d_21 %>%
  select(bipoc_owned, woman_owned, techtown_numtext, ezone_numtext) %>%
  map(tabyl)


## Recode

d_21 <- d_21 %>%
  mutate(across(c(bipoc_owned, woman_owned, 
                  techtown_numtext, ezone_numtext),
                ~case_when(. == "" ~ "0",
                           TRUE ~ .))) %>%
  mutate(across(c(bipoc_owned, woman_owned), as.numeric))

# Drop unnecessary variables

d_21_drop <- dict_21 %>%
  filter(drop == "yes") %>%
  select(final_name) %>%
  pull()

d_21 <- d_21 %>%
  select(-all_of(d_21_drop))

# Add 2021 to variables

d_21 <- d_21 %>%
  rename_with(~ base::paste0(., "_2021"), -business) 

# Narrow the sample down to just those who recommitted in 2021

d_21 <- d_21 %>%
  filter(recommit_techtown_2021 %in% c(1,98) | recommit_pmp_2021 %in% c(1,98))


# Merge years -------------------------------------------------------------

combined <- d_21 %>%
  left_join(d_20, by = "business") %>%
  left_join(d_19, by = "business")


# Merge in internship data ------------------------------------------------

# Read in internship data (recode ?? to NA)

intern <- read_excel(here("data-raw", "Work Experience Tracking v2.xlsx"), sheet = "Compiled - Only Current Biz", na = "??") %>%
  select(`Business Name`, interns_eli_2021 = `2021 ELI`, interns_eli_2020 = `2020 ELI`, interns_eli_2019 = `2019 ELI`, interns_wsi_2021 = `2021 WSI`, interns_wsi_2020 = `2020 WSI`, interns_wsi_2019 = `2019 WSI`)


# Join internship data with combined data

combined_intern <- combined %>%
  left_join(intern, by = c("business" = "Business Name"))


# Restructure data to long format -----------------------------------------

combined_long <- combined_intern %>%
  pivot_longer(
  cols = -business,
  names_to = c(".value", "year"),
  names_pattern = "^(.*)_([0-9]{4})$")

# 2019 connect variable did not have a 3 option compared to other years (you will get a warning)
# 2020 percentage purchase has differing value labels from other years (you will get a warning)
# 2020 and 2021 ezone have differing value labels (you will get a warning)
# Will fix all of this in combined data


# Reorder data ------------------------------------------------------------

# Read in data dictionary

dict_all <- read_excel("all-years_data-dictionary.xlsx")

var_order <- dict_all %>%
  select(final_name) %>%
  pull()

# Reorder variables

combined_long <- combined_long %>%
  relocate(all_of(var_order))


# Fix labels --------------------------------------------------------------


## Check current value labels

x <- labelled::look_for(combined_long, details = TRUE) %>% 
               select(variable, label, class, value_labels, na_values)

## Add value labels

combined_long <- combined_long %>%
  mutate(across(c(techtown_numtext, athletic_text:tech_text), 
                       ~labelled(., labels = c(yes=1, no = ""))))

combined_long <- combined_long %>%
  set_value_labels(pmp_numtext_2021 = c("2019 Early Adopter" = "1",
                                        "2020 PMP Biz" = "2",
                                        "2021 PMP Biz" = "3",
                                        "Not PMP" = "0"),
                   ezone_numtext = c("EZone" = "1", "Not EZone" = "2"),
                   pmp_2020 = c("PMP Early Adopter" = 1, "PMP" = 2, "Not PMP" = 3),
                   ezone = c("Yes"=1, "No"=0), 
                   techtown = c("Yes" = 1, "No"= 0),
                   pmp_2021 = c("Not PMP" = 0, 
                                "2019 Early Adopter" =1, 
                                "2020 PMP Biz" = 2, 
                                "2021 PMP Biz" =3),
                   percentage_purchase = c("0-5" =1, 
                                           "6-10" =2, 
                                           "11-20" =3,
                                           "21-30"= 4, 
                                           "31-40" = 5, 
                                           "41-50" = 6,
                                           "51 or higher"= 7,
                                           "I'm not sure" = 98),
                   connect = c("Yes" = 1,
                               "No" = 2,
                               "My business did not commit to PMP" = 3, 
                               "I'm not sure" = 98),
                   recommit = c("Yes" = 1,
                                "No" = 2),
                   share_meaningful_action = c("Yes" = 1,
                                               "No" = 2))


combined_long <- combined_long %>%
  mutate(across(c(bipoc_owned:woman_owned), 
                ~labelled(., labels = c(yes=1, no = 0))))


## Review labels again

x <- labelled::look_for(combined_long, details = TRUE) %>% 
  select(variable, label, class, value_labels, na_values)


## Convert values to labels

combined_long <- combined_long %>%
  rio::characterize()

# Add variable labels

## Create a named character vector

dict_labels <- dict_all %>%
  select(final_name , question_text) %>%
  deframe() %>%
  as.list()

## Add variable labels to variables

combined_long <- combined_long %>%
  set_variable_labels(.labels = dict_labels, .strict = FALSE) %>%
  mutate(business = case_when(business == "Opsis Architechture" ~ "Opsis Architecture",
                              TRUE ~ business))

## Review labels

var_label(combined_long)


# Export data -------------------------------------------------------------

write_rds(combined_long, here("data", "pp_2019-2021_clean.rds"))
