library(caret)
library(randomForest)
library(cluster)
library(ggplot2)
library(dplyr)
library(pROC)

df <- read.csv("data/processed_shoppers.csv")
df$Revenue <- as.factor(df$Revenue)

#Step 1: Drop correlated features before training 

cols_to_drop <- c(
  "ExitRates",
  "TotalPages",
  "TotalDuration",
  "SessionScore",
  "EngagementRatio",
  "Administrative_Duration",
  "Informational_Duration"
)

cat("Dropped correlated columns:\n")
print(cols_to_drop)

# Columns retained for modelling
features <- c(
  "Administrative",          
  "Informational",           
  "ProductRelated",          
  "ProductRelated_Duration", 
  "BounceRates",             
  "PageValues",              
  "SpecialDay",
  "Season",                  
  "DurationGroup",           
  "Month",
  "VisitorType",
  "Weekend",
  "OperatingSystems",
  "Browser",
  "Region",
  "TrafficType"
)

cat("\nFeatures used for training:", length(features), "\n")
print(features)

#Step 2: Encode factors
factor_cols <- c("Month", "VisitorType", "Weekend", "Season", "DurationGroup",
                 "OperatingSystems", "Browser", "Region", "TrafficType")

df[factor_cols] <- lapply(df[factor_cols], as.factor)

#Step 3: Train / test split 
set.seed(42)
split <- createDataPartition(df$Revenue, p = 0.8, list = FALSE)
train <- df[split, ]
test  <- df[-split, ]

cat(sprintf("\nTrain: %d rows | Test: %d rows\n", nrow(train), nrow(test)))
cat("Class balance (train):\n")
print(prop.table(table(train$Revenue)) * 100)

# MODEL 1: Random Forest — clean feature set, no correlated predictors
rf_model <- randomForest(
  x         = train[, features],
  y         = train$Revenue,
  ntree     = 200,
  mtry      = 4,               
  importance = TRUE,
  classwt   = c("FALSE" = 1, "TRUE" = 5)   # handle class imbalance (~84/16 split)
)

print(rf_model)

#Evaluation
rf_preds <- predict(rf_model, test[, features])
rf_probs <- predict(rf_model, test[, features], type = "prob")[, "TRUE"]

cm <- confusionMatrix(rf_preds, test$Revenue, positive = "TRUE")
cat("\n=== Random Forest Results (after collinearity removal) ===\n")
cat("Accuracy :", round(cm$overall["Accuracy"],  4), "\n")
cat("Precision:", round(cm$byClass["Precision"], 4), "\n")
cat("Recall   :", round(cm$byClass["Recall"],    4), "\n")
cat("F1 Score :", round(cm$byClass["F1"],        4), "\n")

# ROC + AUC
roc_obj <- roc(test$Revenue, rf_probs, levels = c("FALSE", "TRUE"))
cat("AUC      :", round(auc(roc_obj), 4), "\n")

png("outputs/plots/roc_curve.png", width = 700, height = 500)
plot(roc_obj, col = "#e63946", lwd = 2,
     main = paste("ROC Curve | AUC =", round(auc(roc_obj), 3)))
dev.off()

# Feature importance plot (clean — only retained features)
imp_df <- data.frame(
  Feature    = rownames(importance(rf_model)),
  Importance = importance(rf_model)[, "MeanDecreaseGini"]
) %>%
  arrange(desc(Importance)) %>%
  head(12)

p_imp <- ggplot(imp_df, aes(x = reorder(Feature, Importance),
                            y = Importance, fill = Importance)) +
  geom_col() +
  scale_fill_gradient(low = "#cce5ff", high = "#003f88") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Feature importance after collinearity removal",
       x = "Feature", y = "Mean Decrease Gini")
ggsave("outputs/plots/feature_importance.png", p_imp, width = 9, height = 6)

# Save predictions
test$Predicted_Revenue    <- rf_preds
test$Purchase_Probability <- rf_probs
write.csv(test, "outputs/model_results/rf_predictions.csv", row.names = FALSE)

# MODEL 2: K-Means — use only non-collinear numeric features

# Use the clean numeric set — no derived sums, no correlated pairs
cluster_features <- c("BounceRates", "PageValues",
                      "ProductRelated", "ProductRelated_Duration",
                      "Administrative", "Informational", "SpecialDay")

cluster_data   <- df[, cluster_features]
cluster_scaled <- scale(cluster_data)

# Elbow
wss <- sapply(1:10, function(k) {
  kmeans(cluster_scaled, centers = k, nstart = 10)$tot.withinss
})

png("outputs/plots/elbow_plot.png", width = 700, height = 400)
plot(1:10, wss, type = "b", pch = 19, col = "#003f88",
     xlab = "k", ylab = "Total within-cluster SS",
     main = "Elbow method — optimal k")
dev.off()

set.seed(42)
km   <- kmeans(cluster_scaled, centers = 4, nstart = 25)
df$Cluster <- as.factor(km$cluster)

# Silhouette on a sample (full 12K distance matrix is slow)
set.seed(1)
samp_idx <- sample(nrow(cluster_scaled), 2000)
sil      <- silhouette(km$cluster[samp_idx], dist(cluster_scaled[samp_idx, ]))
cat("\nAvg Silhouette Score (2000-row sample):", round(mean(sil[, 3]), 4), "\n")

# Cluster plot — PageValues vs BounceRates (no collinear pair used)
p_clust <- ggplot(df, aes(x = PageValues, y = BounceRates,
                          color = Cluster, shape = Revenue)) +
  geom_point(alpha = 0.4, size = 1.5) +
  scale_color_brewer(palette = "Set1") +
  theme_minimal() +
  labs(title = "Visitor segments: PageValues vs BounceRates",
       x = "Page Values", y = "Bounce Rate")
ggsave("outputs/plots/kmeans_visitor_segments.png", p_clust, width = 9, height = 6)

write.csv(df, "data/final_with_clusters.csv", row.names = FALSE)
cat("\nModelling complete. All outputs saved.\n")