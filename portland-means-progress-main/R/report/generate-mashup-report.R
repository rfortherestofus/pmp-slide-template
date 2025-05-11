
# Load Packages -----------------------------------------------------------

library(tidyverse)
library(pdftools)
library(fs)


# Get info on all reports -------------------------------------------------

all_reports <- dir_ls("reports/pdf/2021/")

all_reports_pages <- map_dfc(all_reports, pdf_length) %>% 
  pivot_longer(cols = everything(),
               names_to = "report_file",
               values_to = "pages")


# Function to get single page from random report --------------------------

get_single_page <- function(page_number) {
  
  report_to_use <- all_reports_pages %>% 
    filter(pages >= page_number) %>% 
    sample_n(1) %>% 
    pull(report_file)
  
  report_to_use %>% 
    pdf_subset(pages = page_number,
               output = str_glue("reports/mashup/sample-report-page-{page_number}.pdf"))
  
}

# Figure out which report is longest

longest_report <- max(all_reports_pages$pages)

# Use this to create one page for each possible page in reports

walk(2:longest_report, get_single_page)


# Combine into one mashup report ------------------------------------------

single_pages <- dir_ls("reports/mashup",
                       regexp = "sample")

pdf_combine(single_pages,
            output = "reports/mashup/mashup-report.pdf")


# Delete single pages -----------------------------------------------------

file_delete(single_pages)

pdf_text(all_reports[1])
