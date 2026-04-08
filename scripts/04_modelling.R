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
write.csv(test, "docker/rf_predictions.csv", row.names = FALSE)
cat("\nModelling complete. All outputs saved.\n")