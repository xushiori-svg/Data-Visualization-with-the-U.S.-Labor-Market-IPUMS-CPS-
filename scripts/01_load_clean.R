# 01_load_clean.R
# Reads the IPUMS CPS data, keeps people aged 25+ in the labor force,
# groups education into 4 categories, and saves a small summary table.
#
# The raw data are not in this repo because the file is too large (about 6 GB)
# and IPUMS does not allow sharing it. To get the same data:
# 1. Go to https://cps.ipums.org and create an extract
# 2. Samples: Basic Monthly, January 1980 to August 2026
# 3. Variables: AGE, SEX, EDUC, EMPSTAT, LABFORCE
# 4. Do not use "Select cases" (the age filter is done in this script)
# 5. Download the .dat file and the .xml file and put both in data/raw/
# 6. Keep only one extract (.xml and .dat) in data/raw/

library(ipumsr)
library(tidyverse)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

#The code reads the first .xml file it finds in that folder.
xml_file <- list.files("data/raw", pattern = "\\.xml$", full.names = TRUE)[1]
ddi <- read_ipums_ddi(xml_file)

process_chunk <- function(x, pos) {
  x |>
    filter(AGE >= 25) |>
    mutate(
      educ_group = case_when(
        EDUC >= 2 & EDUC <= 60 | EDUC == 71 ~ "Less than HS",
        EDUC %in% c(72, 73) ~ "HS diploma",
        EDUC %in% c(80, 81, 90, 91, 92, 100) ~ "Some college",
        EDUC %in% c(110, 111, 120, 121, 122, 123, 124, 125) ~ "Bachelor's+",
        TRUE ~ NA_character_
      ),
      in_lf = EMPSTAT %in% c(10, 12, 20, 21, 22),
      unemp = EMPSTAT %in% c(20, 21, 22)
    ) |>
    filter(!is.na(educ_group), in_lf) |>
    group_by(YEAR, MONTH, SEX, educ_group) |>
    summarise(
      lf_wt = sum(WTFINL),
      unemp_wt = sum(WTFINL * unemp),
      n = n(),
      .groups = "drop"
    )
}

# Read the data in chunks so the computer does not run out of memory
cps_agg <- read_ipums_micro_chunked(
  ddi,
  callback = IpumsDataFrameCallback$new(process_chunk),
  chunk_size = 1000000
)

cps_agg <- cps_agg |>
  group_by(YEAR, MONTH, SEX, educ_group) |>
  summarise(
    lf_wt = sum(lf_wt),
    unemp_wt = sum(unemp_wt),
    n = sum(n),
    .groups = "drop"
  ) |>
  mutate(
    SEX = droplevels(as_factor(SEX)),
    MONTH = as.integer(zap_labels(MONTH)),
    YEAR = as.integer(YEAR),
    date = make_date(YEAR, MONTH, 1)
  ) |>
  arrange(date, SEX, educ_group)

# Check
nrow(cps_agg)
range(cps_agg$YEAR)

write_csv(cps_agg, "data/processed/cps_unemp_agg.csv")
