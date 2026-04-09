library(httr)
library(jsonlite)

readRenviron(".Renviron")                        
api_key <- Sys.getenv("WORLDBANK_API_KEY")       

# Guard: stop early if key is missing rather than silently failing later
if (nchar(api_key) == 0) {
  stop("WORLDBANK_API_KEY not found. Did you create .Renviron at project root?")
}

cat("API key loaded successfully.\n")

# Configuration 
base_url  <- "https://api.worldbank.org/v2/country/all/indicator/IT.NET.USER.ZS"
log_file  <- "api_log.txt"
out_file  <- "data/raw/worldbank_internet_users.csv"

#Pagination loop
page     <- 1
all_data <- list()

repeat {
  
  response <- GET(
    url   = base_url,
    query = list(
      format   = "json",
      per_page = 100,
      page     = page,
      date     = "2008",
      apikey   = api_key          # key injecting here 
    )
  )
  
  # Log every call
  cat(
    format(Sys.time()), 
    "| page:", page,
    "| status:", status_code(response), "\n",
    file  = log_file,
    append = TRUE
  )
  
  # Stopping on bad status
  if (status_code(response) != 200) {
    warning(paste("Non-200 response on page", page, "— stopping pagination."))
    break
  }
  
  # Parse Data from web
  raw_text <- content(response, as = "text", encoding = "UTF-8")
  parsed   <- fromJSON(raw_text, flatten = TRUE)
  
  total_pages   <- parsed[[1]]$pages
  page_data     <- as.data.frame(parsed[[2]])
  all_data[[page]] <- page_data
  
  cat(sprintf("  Page %d/%d fetched — %d rows\n", page, total_pages, nrow(page_data)))
  
  if (page >= total_pages) break
  page <- page + 1
  Sys.sleep(0.3)       # polite rate limiting — avoids 429 errors
}

# Combining and cleaning
internet_df <- do.call(rbind, all_data)
internet_df <- internet_df[, c("country.value", "date", "value")]
colnames(internet_df) <- c("Country", "Year", "InternetUsersPer100")

# Remove rows where World Bank returned no data for that country-year
internet_df <- internet_df[!is.na(internet_df$InternetUsersPer100), ]

# Save 
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
write.csv(internet_df, out_file, row.names = FALSE)

cat(sprintf("\nDone. %d rows saved to %s\n", nrow(internet_df), out_file))
cat(sprintf("API call log written to %s\n", log_file))