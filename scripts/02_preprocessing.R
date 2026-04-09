library(dplyr)
library(lubridate)

df <- read.csv("data/raw/online_shoppers_intention.csv")

cat("=== Initial Shape ===\n")
cat("Rows:", nrow(df), "| Cols:", ncol(df), "\n")
cat("Missing values:\n")
print(colSums(is.na(df)))

# --- NEW: World Bank API Data Integration ---

# 1. Load your API data
# Assuming you saved your API pull as worldbank_internet_users.csv
wb_raw <- read.csv("data/raw/worldbank_internet_users.csv")

# 2. Encode Alphabetically (1 to 236)
wb_encoded <- wb_raw %>%
  distinct(Country, .keep_all = TRUE) %>%  # Ensure no duplicates
  arrange(Country) %>%                     # Sort A-Z
  mutate(RegionID = row_number()) %>%      # Assign 1 to 236
  select(RegionID, Country, InternetUsersPer100)

df <- df %>%
  mutate(Region = as.integer(as.character(Region))) %>% # Convert factor back to int for join
  left_join(wb_encoded, by = c("Region" = "RegionID"))

# 4. Handle any missing data from the join
df$InternetUsersPer100[is.na(df$InternetUsersPer100)] <- median(df$InternetUsersPer100, na.rm = TRUE)

cat("\n=== Integration Complete ===\n")
cat("Added World Bank columns: Country, InternetUsersPer100\n")

#Fixing data types
df$Revenue      <- as.factor(df$Revenue)       
df$Weekend      <- as.factor(df$Weekend)
df$Month        <- as.factor(df$Month)
df$VisitorType  <- as.factor(df$VisitorType)
df$OperatingSystems <- as.factor(df$OperatingSystems)
df$Browser      <- as.factor(df$Browser)
df$Region       <- as.factor(df$Region)
df$TrafficType  <- as.factor(df$TrafficType)

#Feature Engineering

# Total pages visited across all categories
df$TotalPages <- df$Administrative + df$Informational + df$ProductRelated

# Total time spent on site (seconds)
df$TotalDuration <- df$Administrative_Duration +
  df$Informational_Duration  +
  df$ProductRelated_Duration

# Engagement ratio: PageValues per page visited (avoid div by zero)
df$EngagementRatio <- ifelse(df$TotalPages > 0,
                             df$PageValues / df$TotalPages, 0)

# Bounce-Exit spread (high = poor engagement)
df$BounceExitSpread <- df$ExitRates - df$BounceRates

# Session quality score (composite)
df$SessionScore <- df$PageValues * (1 - df$BounceRates) * (1 - df$ExitRates)

# Month to season
df$Season <- case_when(
  df$Month %in% c("Dec", "Jan", "Feb") ~ "Winter",
  df$Month %in% c("Mar", "Apr", "May") ~ "Spring",
  df$Month %in% c("Jun", "Jul", "Aug") ~ "Summer",
  TRUE                                  ~ "Autumn"
)
df$Season <- as.factor(df$Season)

#3. Duration buckets (for EDA grouping) 
df$DurationGroup <- cut(df$TotalDuration,
                        breaks = c(-Inf, 0, 300, 1000, 3000, Inf),
                        labels = c("Zero", "Short", "Medium", "Long", "Very Long"))

#4. Save
# 4. Save to processed folder
write.csv(df, "data/processed_shoppers.csv", row.names = FALSE)
cat("\nPreprocessing done. Final shape:", nrow(df), "rows x", ncol(df), "cols\n")
