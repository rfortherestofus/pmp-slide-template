# Load packages -----------------------------------------------------------

library(tidyverse)
library(gmailr)
library(here)
library(janitor)
library(fs)
library(readxl)
library(writexl)
library(googlesheets4)

# Get business and email data ---------------------------------------------

source(here("R/setup.R"))

businesses_with_reports <-
  pmp_data |>
  distinct(business) |>
  rename(business_name = business) |>
  mutate(business_name = str_trim(business_name)) |>
  arrange(business_name) |>
  drop_na(business_name) |>
  mutate(report_file = str_glue("reports/pdf/2023/{make_clean_names(business_name)}.pdf"))

business_info <-
  read_excel(
    "data-raw/2023 PMP Contacts_clean.xlsx",
    sheet = "Active Businesses"
  ) |>
  clean_names() |>
  mutate(business_name = str_trim(business_name)) |>
  left_join(businesses_with_reports, by = "business_name") |>
  filter(submittal_status == "Submitted") |>
  mutate(report_exists = file_exists(report_file)) |>
  select(business_name, primary_contact_email, cc_email_s, report_file) |>
  # This is for testing so I can send a fake report to myself
  add_row(
    primary_contact_email = "david@rfortherestofus.com;",
    cc_email_s = NA,
    business_name = "R for the Rest of Us",
    report_file = "reports/pdf/2023/a_k_designs_inc.pdf"
  )


# Send email function -----------------------------------------------------

send_pmp_email <- function(business_name_to_filter) {
  business_info_filtered <- business_info |>
    filter(business_name == business_name_to_filter)

  email_content <-
    gm_mime() |>
    gm_to(business_info_filtered$primary_contact_email) |>
    gm_from("R for the Rest of Us on Behalf of Prosper Portland <info@rfortherestofus.com>") |>
    gm_subject(str_glue("2023 Portland Means Progress Company Dashboard for {business_info_filtered$business_name}")) |>
    gm_html_body("Hello Portland Means Progress business!
                 <br><br>
This Company Dashboard includes data you’ve provided in Portland Means Progress annual reporting since you joined the initiative. Each year, we’ll provide your company an Annual Company Dashboard to provide information for you to reflect on your progress, celebrate movement, and consider your future actions to advance racial equity within your organization as well as in our community. The annual reporting has informed our collective Impact Report, and now your organizations’ specific information is available to you for individual reflection. This information remains confidential to your business and is held by a third party company. If anything in the report appears inconsistent with your information, please let R for the Rest of Us know.
                 <br><br>
The data are displayed in several different graph styles to better help you visualize what you reported:

<ul>
<li>Circle plots help you see what commitments you’ve made over the years – each dot corresponds with the commitment and the circle represents each year.</li>
<li>Waffle plots are used to visualize the demographics you’ve reported. You’ll see your staff disaggregated by race and represented with different colors. (Note: if you did not report your staff demographics, you won’t have these graphs.)</li>
</ul>
Our intention is to provide another way for your organization to be intentional in your DEI work. Please feel free to reach out with any questions and we’re excited to continue our partnership.
<br><br>
This is a good opportunity about half way through the year to pause and reflect on your progress and goals! 2024 Annual Reporting will open in January 2024.
<br><br>
Best,
<br><br>
The Portland Means Progress Team") |>
    gm_attach_file(business_info_filtered$report_file)

  if (!is.na(business_info_filtered$cc_email_s)) {
    email_content <-
      email_content |>
      gm_cc(business_info_filtered$cc_email_s)
  }

  print(str_glue("Sending email to {business_info_filtered$business_name}"))

  gm_send_message(email_content)
}

# Send emails -------------------------------------------------------------

gm_auth_configure(path = "client_secret_310581603039-kimk3s3mustf9rnv3qh2h887gmp46gfv.apps.googleusercontent.com.json")

# walk(business_info$business_name, send_pmp_email)
# 
# beepr::beep()