
library(tidyverse)
library(haven)
library(readxl)
library(janitor)
library(labelled) #to recode haven labelled vars
library(purrr)
library(here)
library(rio)


# 2022 data ---------------------------------------------------------------

d_22 <- read_sav(here("data-raw", "Portland Means Progress 2022 Annual Reporting.sav")) %>%
  remove_labels()

# Read in data dictionary ----

dict_22 <- read_excel("data-dictionary/2022_data-dictionary.xlsx")

# Drop unnecessary variables ----

d_22_drop <- dict_22 %>%
  filter(drop == "yes") %>%
  select(survey_var_name) %>%
  pull()

d_22 <- d_22 %>%
  select(-all_of(d_22_drop))

# Rename variables ----

dict_names_22 <- dict_22 %>%
  filter(!is.na(final_name)) %>%
  select(final_name, survey_var_name) %>%
  deframe()

d_22 <- d_22 %>%
  rename(all_of(dict_names_22))

names(d_22)

# Make 3 transformations requested by survey company ----

## Recode action_work for WE Communications and Leatherman

## Check variable

d_22 %>%
  tabyl(action_work)

## Recode

d_22 <- d_22 %>%
  mutate(action_work = 
           case_when(business %in% c("WE Communications", "Leatherman") ~ "no",
                     TRUE ~ action_work
           ))

## Check variable

d_22 %>%
  tabyl(action_work)

## Recode employees for NW Natural

## Check variable

d_22 %>%
  filter(business == "NW Natural") %>%
  select(employees)

## Recode

d_22 <- d_22 %>%
  mutate(employees = 
           case_when(
             business == "NW Natural" ~ "1288",
             TRUE ~ employees
           ))

## Check variable

d_22 %>%
  filter(business == "NW Natural") %>%
  select(employees)

## Recode action_purchasing for WE Communications

## Check variable

d_22 %>%
  tabyl(action_purchasing)

## Recode

d_22 <- d_22 %>%
  mutate(action_purchasing = 
           case_when(business == "WE Communications" ~ "no",
                     TRUE ~ action_purchasing
           ))

## Check variable

d_22 %>%
  tabyl(action_purchasing)

# Calculate combined variables for longitudinal comparability ----

## progress variables

## Check values

d_22 %>%
  select(contains("progress")) %>%
  view()

## Combine vars

d_22 <- d_22 %>%
  mutate(progress_none = coalesce(progress_none_a, progress_none_b),
         progress_work = coalesce(progress_work_a, progress_work_b),
         progress_purchasing = coalesce(progress_purchasing_a, progress_purchasing_b),
         progress_culture = coalesce(progress_culture_a, progress_culture_b),
         mutate(across(c(progress_none, progress_work, progress_purchasing,
                         progress_culture), 
                       ~ case_when(
                         is.na(.) ~ 0,
                         TRUE ~ .
                       ))))

## Check values

d_22 %>%
  select(progress_none, progress_none_a, progress_none_b,
         progress_work, progress_work_a, progress_work_b,
         progress_purchasing, progress_purchasing_a, progress_purchasing_b,
         progress_culture, progress_culture_a, progress_culture_b) %>%
  view()

## track_dollars_spent

## Check values

d_22 %>%
  tabyl(track_dollars_spent_2022)

## Collapse

d_22 <- d_22 %>%
  mutate(track_dollars_spent = 
           case_when(
             track_dollars_spent_2022 %in% c(1, 2, 3) ~ 1,
             track_dollars_spent_2022 == 4 ~ 2,
             track_dollars_spent_2022 == 5 ~ 98, 
             TRUE ~ track_dollars_spent_2022
           ))

## Check values

d_22 %>%
  tabyl(track_dollars_spent_2022, track_dollars_spent)

# Recode variables ----

## yes/no variables

## Check values

d_22 %>%
  select(action_work:new_business) %>%
  map(tabyl)

## Recode

d_22 <- d_22 %>%
  mutate(across(action_work:new_business, 
                ~case_when(
                  . == "yes" ~ 1,
                  . == "no" ~ 0,
                )))

## Check values

d_22 %>%
  select(action_work:new_business) %>%
  map(tabyl)

## Recode select all variables

## Grab select all variables

d_22_sa <- dict_22 %>%
  filter(notes2 == "select all") %>%
  select(final_name) %>%
  pull()

## Check values

d_22 %>%
  select(all_of(d_22_sa)) %>%
  map(tabyl)

## Recode

d_22 <- d_22 %>%
  mutate(across(all_of(d_22_sa),
                ~case_when(
                  is.na(.) ~ 0,
                  TRUE ~ .
                )))

## Check values

d_22 %>%
  select(all_of(d_22_sa)) %>%
  map(tabyl)

## Recode I'm not sure variables

## Check values

d_22 %>%
  select(track_demo_interns, connect, track_demo_emp,track_demo_lead) %>%
  map(tabyl)

## Recode

d_22 <- d_22 %>%
  mutate(across(c(track_demo_interns, connect, track_demo_emp, track_demo_lead),
                ~case_when(
                  . == 3 ~ 98,
                  TRUE ~ .
                )))

## Check values

d_22 %>%
  select(track_demo_interns, connect, track_demo_emp, track_demo_lead) %>%
  map(tabyl)

## Recode employees, interns_noneli, intern_bipoc, dollars_spent_purchases, leadership, spend_locally_portland_ezone, spend_locally_invest_ezone to numeric

## Check type

class(d_22$employees)
class(d_22$interns_noneli)
class(d_22$intern_bipoc)
class(d_22$dollars_spent_purchases)
class(d_22$leadership)
class(d_22$spend_locally_portland_ezone)
class(d_22$spend_locally_invest_ezone)

d_22 %>%
  select(employees, interns_noneli, intern_bipoc, dollars_spent_purchases, leadership,
         spend_locally_portland_ezone, spend_locally_invest_ezone) %>%
  map(tabyl)

## Recode

d_22 <- d_22 %>%
  mutate(across(c(employees, interns_noneli, intern_bipoc, dollars_spent_purchases,
                  leadership, spend_locally_portland_ezone,
                  spend_locally_invest_ezone), as.numeric))

## Check type

class(d_22$employees)
class(d_22$interns_noneli)
class(d_22$intern_bipoc)
class(d_22$dollars_spent_purchases)
class(d_22$leadership)
class(d_22$spend_locally_portland_ezone)
class(d_22$spend_locally_invest_ezone)

# Add year variable ----

d_22 <- d_22 %>%
  mutate(year = "2022")

# Narrow the sample down to just those who recommitted in 2022 ----

## Check values

d_22 %>%
  tabyl(recommit)

## Narrow sample

d_22 <- d_22 %>%
  filter(recommit == 1)

## Check values

d_22 %>%
  tabyl(recommit)

# Add labels ----

## Add value labels

d_22 <- d_22 %>%
  mutate(across(all_of(d_22_sa), 
                ~labelled(., labels = c(Yes=1, No =0))))

d_22 <- d_22 %>%
  mutate(across(c(action_work, action_purchasing, action_culture,
                  ezone, idg, new_business, progress_none,
                  progress_work, progress_purchasing, progress_culture),
                            ~labelled(., labels = c(Yes=1, No =0))))

d_22 <- d_22 %>%
  mutate(across(c(track_dollars_spent, track_demo_interns, connect, track_demo_emp, track_demo_lead),
                ~ labelled(., labels = c(yes =1, no =2, "I'm not sure"=98))))

d_22 <- d_22 %>%
  set_value_labels(recommit = c("yes" = 1,
                                        "no" = 2),
                   meaningful_idg = c("Strongly Agree" = 1,
                                      "Agree" = 2,
                                      "Neither agree nor disagree" = 3,
                                      "Disagree" = 4, 
                                      "Strongly Disagree" = 5,
                                      "I'm not sure" = 6),
                   track_dollars_spent_2022 = c("Yes - as a total sum" =1,
                                                "Yes - as a percentage of our total dollars spent" = 2,
                                                "Yes - as both a total sum and as a percentage of our total dollars spent" = 3,
                                                "No"= 4,
                                                "I'm not sure" = 5))

## Review labels

x <- look_for(d_22, details = TRUE) %>% 
  select(variable, label, class, value_labels, na_values)

# Convert values to labels ----

d_22 <- d_22 %>%
  rio::characterize()   

# Read in prior data and combine ----

prev_data <- read_rds(here("data", "pp_2019-2021_clean.rds"))

## Combine data

combined_data <- bind_rows(prev_data, d_22)


# Add variable labels ----

## Create a named character vector

dict_all <- read_excel("all-years_data-dictionaryv02.xlsx")

dict_labels <- dict_all %>%
  select(final_name , question_text) %>%
  deframe() %>%
  as.list()

## Add variable labels to variables

combined_data <- combined_data %>%
  set_variable_labels(.labels = dict_labels, .strict = FALSE)

## Review labels

var_label(combined_data)

# Reorder variables ----

var_order <- dict_all %>%
  select(final_name) %>%
  pull()

# Reorder variables + fix name

combined_data <- combined_data %>%
  relocate(all_of(var_order)) %>%
  mutate(business = case_when(business == "Opsis Architechture" ~ "Opsis Architecture",
                              TRUE ~ business))

# Export data ----

write_rds(combined_data, here("data", "pp_2019-2022_clean.rds"))

