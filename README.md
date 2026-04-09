# Click-Through Rate (CTR) Prediction for Ads

##Project Overview
This project is a comprehensive Machine Learning pipeline designed to predict whether a user will click on an advertisement. The analysis uniquely combines behavioral data (online shoppers' intention) with global infrastructure metrics retrieved via the **World Bank API**.
The goal is to understand if regional digital development (like Internet Users per 100 people) acts as a significant predictor for ad engagement.

## Dataset
- Name: Online Shoppers Purchasing Intention
- Source: UCI ML Repository (https://archive.ics.uci.edu/dataset/468)
- Rows: 12,330 | Attributes: 18
- Types: 10 numeric + 8 categorical
- Target: Revenue (purchase intent: TRUE/FALSE)

## 📂 Repository Structure
```text
├── data/
│   ├── raw/                # Original datasets (World Bank API pull & Ad CSV)
│   └── processed/          # Merged and cleaned data ready for modeling
├── docker/                 # Containerization files (rf_predictions.csv)
├── outputs/
│   ├── plots/              # EDA visualizations and Model performance curves
│   └── model_results/      # Saved .rds models and prediction outputs
├── scripts/
│   ├── 01_api_ingestion.R  # World Bank API connection & data pull
│   ├── 02_preprocessing.R  # Data cleaning, merging, and feature engineering
│   ├── 03_eda.R            # Exploratory Data Analysis & Visualizations
│   └── 04_modelling.R      # Random Forest training and evaluation
└── README.md               # Project documentation
```

# Tech Stack

Language: R (v4.3.1)

Libraries: httr, jsonlite, dplyr, lubridate, ggplot2, corrplot, scales, randomForest, ggplot2, pROC, caret, recipes

API: World Bank Open Data API

Version Control: Git/GitHub

# 1. Installation

Install the necessary R packages before running the scripts

```R
install.packages(c("httr", "jsonlite", "dplyr", "lubridate", "ggplot2", "corrplot", "scales", "randomForest", "pROC", "caret", "recipes"))
```

# 2. Execution Order
To reproduce the results, run the scripts in the following sequence:

```
Ingestion: scripts/01_api_ingestion.R (Fetches World Bank data).

Preprocessing: scripts/02_preprocessing.R (Joins datasets and handles missing values).

EDA: scripts/03_eda.R (Generates insights and saves to outputs/plots/).

Modelling: scripts/04_modelling.R (Trains the Random Forest and outputs predictions).
```
## Data Synchronization Flow
Below is the automated pipeline from the initial code change to the final visualization:

```mermaid
graph TD
    A[GitHub Change] -->|git pull| B[Local Machine / Server]
    B --> C[Docker Container Reads Updated CSV]
    C --> D[Power BI Desktop / Service]
    D -->|Refresh| E[Updated Dashboard Visuals]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#00ff00,stroke:#333,stroke-width:2px
