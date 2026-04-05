library(ggplot2)
library(dplyr)
library(corrplot)
library(scales)

df <- read.csv("data/processed_shoppers.csv")
df$Revenue     <- as.factor(df$Revenue)
df$VisitorType <- as.factor(df$VisitorType)
df$Season      <- as.factor(df$Season)

#Plot 1 Purchase Rate by Month Bar Graph 
monthly <- df %>%
  group_by(Month) %>%
  summarise(PurchaseRate = mean(Revenue == "TRUE") * 100,
            .groups = "drop") %>%
  mutate(Month = factor(Month,
                        levels = c("Jan","Feb","Mar","Apr","May","Jun",
                                   "Jul","Aug","Sep","Oct","Nov","Dec")))

p1 <- ggplot(monthly, aes(x = Month, y = PurchaseRate, fill = PurchaseRate)) +
  geom_col() +
  scale_fill_gradient(low = "#cce5ff", high = "#004085") +
  theme_minimal() +
  labs(title  = "Purchase Conversion Rate by Month (%)",
       x = "Month", y = "Conversion Rate (%)")
ggsave("outputs/plots/p1_conversion_by_month.png", p1, width = 10, height = 5)

#Plot 2 PageValues Distribution by Revenue Boxplot
p2 <- ggplot(df, aes(x = Revenue, y = PageValues, fill = Revenue)) +
  geom_boxplot(outlier.alpha = 0.2) +
  scale_y_log10() +
  scale_fill_manual(values = c("FALSE" = "#f8d7da", "TRUE" = "#d4edda")) +
  theme_minimal() +
  labs(title = "Page Values Distribution: Buyers vs Non-Buyers",
       x = "Revenue (Purchase)", y = "Page Values (log scale)")
ggsave("outputs/plots/p2_pagevalues_revenue.png", p2, width = 8, height = 5)

# Plot 3 Bounce Rate vs Exit Rate Scatter, coloured by Revenue
p3 <- ggplot(df %>% sample_n(3000),   # sample for readability
             aes(x = BounceRates, y = ExitRates, color = Revenue)) +
  geom_point(alpha = 0.4, size = 1.5) +
  scale_color_manual(values = c("FALSE" = "#adb5bd", "TRUE" = "#e63946")) +
  theme_minimal() +
  labs(title = "Bounce Rate vs Exit Rate by Purchase Outcome",
       x = "Bounce Rate", y = "Exit Rate")
ggsave("outputs/plots/p3_bounce_exit_scatter.png", p3, width = 8, height = 5)

#Plot 4 Visitor Type × Revenue Stacked Bar
vtype <- df %>%
  group_by(VisitorType, Revenue) %>%
  summarise(Count = n(), .groups = "drop")

p4 <- ggplot(vtype, aes(x = VisitorType, y = Count, fill = Revenue)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = c("FALSE" = "#dee2e6", "TRUE" = "#339af0")) +
  theme_minimal() +
  labs(title = "Purchase Proportion by Visitor Type",
       x = "Visitor Type", y = "Proportion")
ggsave("outputs/plots/p4_visitortype_revenue.png", p4, width = 8, height = 5)

#Plot 5 Correlation Heatmap
num_df <- df %>% select(Administrative, Administrative_Duration,
                        Informational, Informational_Duration,
                        ProductRelated, ProductRelated_Duration,
                        BounceRates, ExitRates, PageValues,
                        SpecialDay, TotalPages, TotalDuration,
                        EngagementRatio, SessionScore)
cor_mat <- cor(num_df, use = "complete.obs")
png("outputs/plots/p6_correlation_heatmap.png", width = 900, height = 900)
corrplot(cor_mat, method = "color", type = "upper",
         addCoef.col = "black", number.cex = 0.6,
         tl.cex = 0.8, title = "Correlation Matrix", mar = c(0,0,2,0))
dev.off()

#Summary stats to file 
sink("outputs/summary_stats.txt")
cat("SUMMARY STATISTICS \n\n")
print(summary(df))
cat("\nPURCHASE RATE\n")
print(prop.table(table(df$Revenue)) * 100)
sink()

cat("EDA complete. 6 plots saved to outputs/plots/\n")