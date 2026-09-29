# Unemployment by Education in the U.S. (IPUMS CPS)

The question is: how does unemployment vary by education, and how did different education groups do in recessions?

## Data

I use IPUMS CPS basic monthly data from January 1980 to August 2026. The sample is people aged 25 and over in the civilian labor force. All numbers use the CPS weight `WTFINL`, so they can describe the U.S. population.

The raw data is not in this repo because the file is too large (about 6 GB) and IPUMS does not allow sharing it. The processed data in `data/processed/` is small, so you can make the figures without downloading anything.

To download the same raw data:

1. Go to https://cps.ipums.org and create an extract
2. Samples: Basic Monthly, January 1980 to August 2026
3. Variables: AGE, SEX, EDUC, EMPSTAT, LABFORCE
4. Do not use "Select cases" for age
5. Download the .dat file and the .xml file and put both in `data/raw/`
6. Put only one extract in `data/raw/`

## Folders

```
CPS-Unemployment-Education/
├── README.md
├── CPS-Unemployment-Education.Rproj
├── scripts/
│   ├── 01_load_clean.R      # reads raw data, makes education groups
│   ├── 02_compute_rates.R   # calculates weighted unemployment rates
│   └── 03_figures.R         # makes the three figures
├── data/
│   ├── raw/                 # raw IPUMS files (not uploaded in Github)
│   └── processed/
│       ├── cps_unemp_agg.csv
│       ├── annual_educ.csv
│       ├── annual_sex_educ.csv
│       └── monthly_educ.csv
└── output/
    └── figures/
        ├── fig1_unemp_by_educ.png
        ├── fig2_unemp_by_sex_educ.png
        └── fig3_recession_aligned.png
```

## How to run

1. Open `CPS-Unemployment-Education.Rproj` in RStudio
2. Install packages
3. If you downloaded the raw data, run `01_load_clean.R` 
4. Run `02_compute_rates.R`
5. Run `03_figures.R`

If you did not download the raw data, skip step 3.

## Notes

- Education groups: less than high school, high school diploma, some college or associate degree, bachelor's degree or higher. The CPS changed the education question in 1992, so I matched the old and new codes.
- October 2025 is missing because data was not collected during the government shutdown.

## Source

Data from IPUMS CPS, University of Minnesota, www.ipums.org.