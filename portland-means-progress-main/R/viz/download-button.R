download_button <- function(df, filename) {
  write_xlsx(df, filename)

  htmltools::HTML(
    sprintf(
      '<p>
           <a href="%s" download="%s"
              style="display: inline-block; padding: 10px 20px; background-color: #f0f0f0;
                     color: #1c1c1c; text-decoration: none; border-radius: 5px; transition: all 0.3s ease;"
              onmouseover="this.style.backgroundColor=\'#e0e0e0\'; this.style.color=\'#000\'"
              onmouseout="this.style.backgroundColor=\'#f0f0f0\'; this.style.color=\'#1c1c1c\'">
              Download Table in Excel
           </a>
           <br><br>
         </p>',
      filename, filename
    )
  )
}
