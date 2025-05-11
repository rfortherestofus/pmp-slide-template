# -------------------- #
# Send Google drive links #
# -------------------- #

library(gmailr)
library(tidyverse)

# Mail text ---------------------------------------------------------------
text_mail <-

"Hello, 

Today is the deadline to complete your Portland Means Progress Annual Reporting! 

Your company’s Annual Report form is available here: {unique_link} 

Please contact Andrea Gall (GallA@prosperportland.us) if you have questions about your Portland Means Progress annual reporting. 

Thank you, 

The Portland Means Progress Team "

# Load info ---------------------------------------------------------------
df_completion_rates <- read_rds("data/completion_rates_2024.rds")

df_participants_info_link <- readxl::read_xlsx("data/drive_links.xlsx") |>
  full_join(df_completion_rates, by =
              join_by(business)) |>
  filter(has_finished == "No" | is.na(has_finished)) |>
  add_row(
    business = "TEST",
    email = "thomas@rfortherestofus.com",
    unique_link = "https://rfortherestofus.limesurvey.net/179359?token=YQdWfFJzca5IQcf&lang=en",
    link  = "https://drive.google.com/uc?id=1X0VCRQj6G8pbhwmC3e_kFTp-G18vHclc&export=download"
  ) |>
  mutate(mail_text = glue::glue(text_mail)) |>
  filter(
    !business %in% c(
      "Woonwinkel",
      "Nike",
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

# Send mail ---------------------------------------------------------------
gm_auth_configure(path = "token.json")
gm_oauth_client()

send_mail_function <- function(email, body) {
  gm_mime() |>
    gm_to(email) |>
    gm_from("R for the Rest of us on behalf of Prosper Portland < info@rfortherestofus.com >
        ") |>
    gm_subject("Portland Means Progress 2024 Annual Reporting") |>
    gm_text_body(body) |>
    gm_send_message()
}

# apply
map2(
  df_participants_info_link$email,
  df_participants_info_link$mail_text,
  send_mail_function
)
