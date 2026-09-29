#install.packages("zoo")
library(tidyverse)
library(zoo)

cps_agg <- read_csv("data/processed/cps_unemp_agg.csv") |>
  mutate(educ_group = factor(educ_group,
                             levels = c("Less than HS", "HS diploma",
                                        "Some college", "Bachelor's+")))

#Table 1: annual rate by education
annual_educ <- cps_agg |>
  filter(YEAR <= 2025) |>
  group_by(YEAR, educ_group) |>
  summarise(
    lf_wt    = sum(lf_wt),
    unemp_wt = sum(unemp_wt),
    n        = sum(n),
    .groups  = "drop"
  ) |>
  mutate(unemp_rate = unemp_wt / lf_wt * 100)

#Table 2: annual rate by sex and education
annual_sex_educ <- cps_agg |> 
  filter(YEAR <=2025) |> 
  group_by(YEAR,SEX,educ_group) |> 
  summarise(
    lf_wt    = sum(lf_wt),
    unemp_wt = sum(unemp_wt),
    n        = sum(n),
    .groups  = "drop"
  ) |>
  mutate(unemp_rate = unemp_wt / lf_wt * 100)
  
#Table 3: monthly rate by education
monthly_educ <- cps_agg |>
  group_by(date, educ_group) |>
  summarise(
    lf_wt    = sum(lf_wt),
    unemp_wt = sum(unemp_wt),
    .groups  = "drop"
  ) |>
  mutate(unemp_rate = unemp_wt / lf_wt * 100) |>
  arrange(educ_group, date) |>
  group_by(educ_group) |>
  mutate(unemp_rate_3m = zoo::rollmean(unemp_rate, k = 3, fill = NA, align = "right")) |>
  ungroup()

write_csv(annual_educ, "data/processed/annual_educ.csv")
write_csv(annual_sex_educ, "data/processed/annual_sex_educ.csv")
write_csv(monthly_educ,    "data/processed/monthly_educ.csv")