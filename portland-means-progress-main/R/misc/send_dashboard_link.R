# -------------------- #
# Send Google drive links #
# -------------------- #

library(gmailr)
library(tidyverse)
library(googledrive)

# Mail text ---------------------------------------------------------------
text_mail <-
  
  "Hello Portland Means Progress business!

This company dashboard includes data you’ve provided in Portland Means Progress annual reporting since you joined the initiative. Each year, we’ll provide your company an Annual Company Dashboard to provide information for you to reflect on your progress, celebrate movement, and consider your future actions to advance racial equity within your organization as well as in our community. The annual reporting has informed our collective Impact Report, and now your organizations’ specific information is available to you for individual reflection. This information remains confidential to your business and is held by a third party company. If anything in the report appears inconsistent with your information, please let R for the Rest of Us know.  This dashboard is automatically created from your annual reporting submission; the Portland Means Progress team will be working in the coming weeks to connect with you 1-1 about any individual challenges you faced and/or support you requested in your reporting.

The data are displayed in several different graph styles to better help you visualize what you reported, which includes circle plots help you see what commitments you’ve made over the years – each dot corresponds with the commitment and the circle represents each year.

Our intention is to provide another way for your organization to be intentional in your racial equity work. Please feel free to reach out with any questions and we’re excited to continue our partnership.

Dashboards are available here : {link}

Best,

The Portland Means Progress Team "

# Load info ---------------------------------------------------------------
df_participants_info_link <- readxl::read_xlsx("data/drive_links.xlsx") |>
  filter(!is.na(link) & !is.na(email)) |>
  add_row(
    business = "TEST",
    email = "thomas@rfortherestofus.com",
    link  = "https://drive.google.com/uc?id=1X0VCRQj6G8pbhwmC3e_kFTp-G18vHclc&export=download"
  ) |>
  mutate(mail_text = glue::glue(text_mail))

# Send mail ---------------------------------------------------------------
gm_auth_configure(path = "token.json")
gm_oauth_client()

send_mail_function <- function(email, body) {
  gm_mime() |>
    gm_to(email) |>
    gm_from("R for the Rest of us on behalf of Prosper Portland <info@rfortherestofus.com>") |>
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
