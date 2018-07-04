#My inelegant solution to scraping the IFPMA partnership directory, using rvest, and alot of xpath
#The IPFMA database has a different page for each project, each project page has a description and a side bar with different category values
#The project pages are not always exactly the same, mostly in terms of the side bar categories
#Scanning through I've identified what categories I'm interested in, and we will extract those directly, along with the main description

#load libraries

library(rvest)
library(stringr)
library(xml2)

#There's already a page with all of the projects listed by alphabetical order, with links to each page.

url <- "http://partnerships.ifpma.org/partnerships/by-letter/all"

dir_page <- read_html(url)

#Use CSS selectors to create list of all the URLs for each project page that we will scrape.

dir_urls <- html_nodes(dir_page,"#results-list a") %>%
  html_attr("href") %>%
  url_absolute(url)

#Now create a list of the program names
dir_names <- html_nodes(dir_page,"#results-list a") %>%
  html_text()

#The first 8 programs are not company-led initiatives, so let's filter those out.  
#I also happen to know that the WIPO RE:Search project page isn't loading correctly, so let's take that one out as well.

prog_url <- dir_urls[c(9:421, 423:425)]
prog_name <- dir_names[c(9:421, 423:425)]

#Finally, clean up the program names:
prog_name <- str_trim(prog_name, side = "both")

###here we will make a shorter test version of both of these objects
prog_url <- prog_url[1:5]
prog_name <- prog_name[1:5]

#Next we will create and join two separate arrays
#First array will have the column names we will extract to
#Second array will have the CSS or XPATH selectors to search for
#Just to keep it neat for later, we'll combine them into a paired list(or table?)

col_name <- c("Prog_dscr", "Company", "Partner", "PArtner_type", "Therapeutic_focus", "Disease", "Prog_type", "Target_pop", "Region", "Country", "Date_start", "Date_end")
col_selector <- c("//*[(@id = 'article-details')]", "//a[contains(@href, '/search?page=1&co[]')]/text()", "//a[contains(@href, '/search?page=1&pa[]')]/text()", "//a[contains(@href, '/search?page=1&ptf[]')]/text()", "//a[contains(@href, '/search?page=1&t[]')]/text()", "//a[contains(@href, '/search?page=1&d[]')]/text()", "//a[contains(@href, '/search?page=1&pr[]')]/text()", "//a[contains(@href, '/search?page=1&tp[]')]/text()", "//a[contains(@href, '/search?page=1&re[]')]/text()", "//a[contains(@href, '/search?page=1&c[]')]/text()", "//a[contains(@href, '/search?page=1&y[]')]/text()", "//a[contains(@href, '/search?page=1&ey[]')]/text()")

###short test version of the `col_name` and `col_selector`

col_name <- c("Prog_dscr", "Company", "Partner")
col_selector <- c("//*[(@id = 'article-details')]", "//a[contains(@href, '/search?page=1&co[]')]/text()", "//a[contains(@href, '/search?page=1&pa[]')]/text()")

#Last part in setting this up, is to create to iterate over all the urls on our list, extracting by each category we want

###function v.2, 

col_extract <- function(col_selector){
  
  xxx <- 0
  tibble(xxx)
  m <- 0
  
  for (i in 1:length(prog_url)) {
    entry <- read_html(prog_url[i]) %>%
      html_nodes(xpath = col_selector) %>%
      html_text() %>%
      str_c(collapse = "; ")
    
    m = m + 1
    
    xxx[m] <- entry
    
  } 
  return(xxx)
}


#Now, we can create a table to store all of the scraped text using the `prog_name` entries for the different rows. 

alltext <- data.frame(prog_name)

###Now, we extract all the columns we're interested in and then bind them together.

sidebar_cols <- sapply(col_selector, col_extract)
alltext <- cbind(alltext, sidebar_cols)
colnames(alltext)[2:ncol(alltext)] <- col_name

#Finally, let's add a column with all of the URLs for each page as a reference

alltext$URL <- prog_url

#Save the .rda object
save(url, prog_url, prog_name, col_selector, col_name, col_extract, alltext, file = "rda/IFPMA_db.rda")

#Save as .csv file

write.csv(alltext, file = "data/IFPMA_db.csv")


