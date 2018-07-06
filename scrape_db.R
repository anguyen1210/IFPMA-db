#The IPFMA partnership database has a different page for each project; each project page has a description and a side bar with different category content
#The project pages are not always exactly the same, mostly in terms of the side bar categories
#Scanning through I've identified what categories I'm interested in, and we will extract those directly, along with the main description

#load libraries

library(rvest)
library(stringr)
library(xml2)

#There's already a page with names and links all of the projects listed by alphabetical order, which can use to make an index

url <- "http://partnerships.ifpma.org/partnerships/by-letter/all"

index_page <- read_html(url)

#Use CSS selectors to create a list of all the URLs for each project page that we will scrape

prog_url <- html_nodes(index_page,"#results-list a") %>%
  html_attr("href") %>%
  url_absolute(url)

#Create a list of the program names.
prog_name <- html_nodes(index_page,"#results-list a") %>%
  html_text()

#The first 8 programs are not company-led initiatives, so let's filter those out
#Through trial and error I know that the WIPO RE:Search project (#422) page isn't loading correctly, so let's take that one out as well

prog_url <- prog_url[c(9:421, 423:425)]
prog_name <- prog_name[c(9:421, 423:425)]

#Clean up the program names
prog_name <- str_trim(prog_name, side = "both")

#Next, create two new arrays to help us extract the sidebar information we want
#First array will have the column names we want for our new table
#Second array will have the XPATH selectors to search for in the sidebar of each project page

col_name <- c("Prog_dscr", "Company", "Partner", "Partner_type", "Therapeutic_focus", "Disease", "Prog_type", "Target_pop", "Region", "Country", "Date_start", "Date_end")
col_selector <- c("//*[(@id = 'article-details')]", "//a[contains(@href, '/search?page=1&co[]')]/text()", "//a[contains(@href, '/search?page=1&pa[]')]/text()", "//a[contains(@href, '/search?page=1&ptf[]')]/text()", "//a[contains(@href, '/search?page=1&t[]')]/text()", "//a[contains(@href, '/search?page=1&d[]')]/text()", "//a[contains(@href, '/search?page=1&pr[]')]/text()", "//a[contains(@href, '/search?page=1&tp[]')]/text()", "//a[contains(@href, '/search?page=1&re[]')]/text()", "//a[contains(@href, '/search?page=1&c[]')]/text()", "//a[contains(@href, '/search?page=1&y[]')]/text()", "//a[contains(@href, '/search?page=1&ey[]')]/text()")

#Create function to iterate over all the urls on our list, extracting the column info we want from each page. Watch for NAs!

col_extract <- function(col_selector){
  
  xxx <- 0
  data.frame(xxx)
  m <- 0
  
  for (i in 1:length(prog_url)) {
    entry <- read_html(prog_url[i]) %>%
      html_nodes(xpath = col_selector) %>%
      html_text() %>%
      ifelse(identical(., character(0)), NA, .) %>% 
      str_c(collapse = "; ")
    
    m = m + 1
    
    xxx[m] <- entry
    
  } 
  return(xxx)
}

#Create a table to store all of the scraped text using the `prog_name` entries for the different rows

alltext <- data.frame(prog_name)

#Extract all the columns we're interested in and then bind them together

sidebar_cols <- sapply(col_selector, col_extract)
alltext <- cbind(alltext, sidebar_cols)
colnames(alltext)[2:ncol(alltext)] <- col_name

#Finally, add a column with all of the URLs for each page as a reference

alltext$URL <- prog_url

#Save the .rda object

save(url, index_page, prog_url, prog_name, col_selector, col_name, col_extract, alltext, file = "rda/IFPMA_db.rda")

#Save as .csv file

write.csv(alltext, file = "data/IFPMA_db.csv")

#save as Excel file (requires `writexl` package)
writexl::write_xlsx(alltext, "data/IFPMA_db.xlsx")
