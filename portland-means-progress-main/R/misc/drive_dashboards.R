# -------------------- #
# Google drive links #
# -------------------- #

library(googledrive)
library(tidyverse)

# # Find files --------------------------------------------------------------
# # need to login my account
# df_list_pmp_dashboards <- drive_get("PMP dashboards") |>
#   drive_ls()
# 
# # Share files -------------------------------------------------------------
# df_list_pmp_dashboards_shared <- df_list_pmp_dashboards |>
#   drive_share_anyone()

# get again
df_list_pmp_dashboards_new <- drive_get("PMP dashboards/2024") |>
  drive_ls()

# Link to participants ----------------------------------------------------
# clean link
df_list_pmp_clean <- df_list_pmp_dashboards_new |>
  unnest_wider(drive_resource, names_sep = "_") |>
  select(name, link = drive_resource_webContentLink) |>
  mutate(
    name = str_remove_all(name, ".pdf")
  )

# get participants
df_participants_info_link <- read_csv("data/participants_info.csv") |>
  select(business = firstname, email) |>
  mutate(business_clean = janitor::make_clean_names(business)) |>
  full_join(df_list_pmp_clean, by = join_by(business_clean == name))

# Export ------------------------------------------------------------------
writexl::write_xlsx(df_participants_info_link, "data/drive_links.xlsx")
