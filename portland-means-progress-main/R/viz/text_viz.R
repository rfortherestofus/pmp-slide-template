text_viz <- function(data, variable, quote_color = pmp_palette$`Light purple`) {
  lines_colour <- pmp_palette$`Mid teal`
  
  quote_string <- data %>%
    filter(year == max(data$year)) %>%
    pull({{variable}}) %>%
    # break lines
    str_replace_all("\n", "<br>") %>%
    # comma at the end
    str_replace("[ ,]+$", ".")  %>%
    # removed unordered and ordered list (ggtext doesn't know what to do with them)
    gsub(" - ", "<br>", .) %>%
    gsub("^- ", "<br>", .) %>%
    gsub("\n ", "<br>", .) %>%
    gsub(" ?\\+ ", "<br>", .) %>%
    # the space avoids chopping of the end of strings like 2021.
    # using ^\\d doesn't work, because you end up with 2. and 3. later
    # in the string
    gsub(" \\d\\. ", "<br>", .) %>%
    gsub("\\d\\)", "<br>", .) %>%
    gsub("^\\d\\. ", "", .) %>%
    gsub("\\|\\|", "<br>", .) %>%
    gsub("\\|", "<br>", .)
  
  if (is.na(quote_string[1])|quote_string[1] == "") {
    quote_string <- paste0("No statement provided in ", max(data$year))
  }
  
  text_size <- case_when(
    nchar(quote_string) < 100 ~ 10,
    between(nchar(quote_string), 100, 150) ~ 8,
    between(nchar(quote_string), 150, 250) ~ 6,
    TRUE ~ 3.5
  )
  
  ggplot(NULL, aes(0, 0)) +
    ggtext::geom_textbox(
      aes(label = quote_string),
      color = pmp_palette$`Light blue`,
      size = text_size,
      family = "Gilroy ExtraBold",
      minwidth = unit(5, "in"),
      maxwidth = unit(8, "in"),
      box.size = 1.2,
      box.colour = lines_colour,
      fill = NA,
      box.padding = unit(c(48, 12, 32, 12), "pt"),
      box.r = unit(0, "pt"),
      hjust = 0.5,
      halign = 0.5,
      vjust = 1,
      valign = 1
    ) +
    # This is just to get rid of the rest of the original text box outline
    ggtext::geom_textbox(
      aes(label = paste0(quote_string, "<br><br>")),
      # We want to keep the text so it's the right size box, but make it transparent
      color = NA,
      size = text_size,
      family = "Gilroy ExtraBold",
      box.colour = pmp_palette$`Dark teal`,
      minwidth = unit(5, "in"),
      maxwidth = unit(8, "in"),
      box.size = 3,
      fill = NA,
      box.padding = unit(c(100, 12, 66, 12), "pt"),
      box.r = unit(0, "pt"),
      hjust = 0.5,
      halign = 0.5,
      vjust = 0.85,
      valign = 1
    ) +
    ggtext::geom_textbox(
      aes(label = "quote-left"),
      color = quote_color,
      size = 30,
      family = "Font Awesome Solid",
      box.colour = NA,
      minwidth = unit(1.5, "in"),
      maxwidth = unit(1.5, "in"),
      fill = pmp_palette$`Dark teal`,
      hjust = 0.5,
      halign = 0.5,
      vjust = 0.4,
      valign = 0.4
    ) +
    scale_y_continuous(limits = c(-0.1, text_size * 0.005)) +
    theme_void() +
    theme(panel.background = element_rect(fill = pmp_palette$`Dark teal`, colour = pmp_palette$`Dark teal`))
}