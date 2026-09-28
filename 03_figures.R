#install.packages("ggrepel")
library(tidyverse)
library(ggrepel)

annual_educ <- read_csv("data/processed/annual_educ.csv") |>
  mutate(educ_group = factor(educ_group,
                             levels = c("Less than HS", "HS diploma",
                                        "Some college", "Bachelor's+")))

recessions <- tribble(
  ~start,  ~end,    ~label,
  1980.0,  1980.5,  "1980",
  1981.5,  1982.92, "1981–82",
  1990.5,  1991.25, "1990–91",
  2001.17, 2001.92, "2001",
  2007.92, 2009.5,  "Great\nRecession",
  2020.08, 2020.33, "COVID-19"
)

educ_colors <- c("Less than HS" = "#B2182B", "HS diploma" = "#EF8A62",
                 "Some college" = "#67A9CF", "Bachelor's+" = "#2166AC")

# figure 1
p1 <- ggplot(annual_educ, aes(x = YEAR, y = unemp_rate, color = educ_group)) +
  geom_rect(data = recessions,
            aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE, fill = "grey80", alpha = 0.5) +
  geom_text(data = recessions,
            aes(x = (start + end) / 2, y = Inf, label = label),
            inherit.aes = FALSE, vjust = 1.3, size = 3, color = "grey30") +
  geom_vline(xintercept = 1992, linetype = "dashed", color = "grey50") +
  annotate("text", x = 1992.4, y = max(annual_educ$unemp_rate) * 0.8,
           label = "Education question\nchanged (1992)",
           hjust = 0, size = 3, color = "grey40") +
  geom_line(linewidth = 1.1) +
  geom_text_repel(data = filter(annual_educ, YEAR == max(YEAR)),
                  aes(label = educ_group),
                  hjust = 0, nudge_x = 1, direction = "y",
                  segment.color = NA, size = 3.5, fontface = "bold") +
  scale_color_manual(values = educ_colors) +
  scale_x_continuous(breaks = seq(1985, 2025, 5),
                     expand = expansion(mult = c(0.01, 0.15))) +
  scale_y_continuous(labels = scales::label_percent(scale = 1)) +
  labs(
    title    = "Less education, higher unemployment, and bigger swings in recessions",
    subtitle = "Annual unemployment rate by educational attainment, ages 25+, 1980–2025",
    x = NULL, y = "Unemployment rate",
    caption  = "Source: IPUMS CPS basic monthly files, weighted with WTFINL. Shaded areas are NBER recessions."
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank())

p1

ggsave("output/figures/fig1_unemp_by_educ.png", p1,
       width = 9, height = 5.5, dpi = 300)

# figure 2

gap <- annual_sex_educ |>
  filter(educ_group %in% c("Less than HS", "Bachelor's+")) |>
  select(YEAR, SEX, educ_group, unemp_rate) |>
  pivot_wider(names_from = SEX, values_from = unemp_rate) |>
  mutate(gap = Female - Male)

p2 <- ggplot(gap, aes(x = YEAR, y = gap, color = educ_group)) +
  geom_rect(data = recessions,
            aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE, fill = "grey80", alpha = 0.5) +
  geom_hline(yintercept = 0, color = "grey30") +
  geom_line(linewidth = 1.1) +
  annotate("text", x = 1983, y = Inf, label = "Women's rate higher ↑",
           hjust = 0, vjust = 1.5, size = 3.2, color = "grey30") +
  annotate("text", x = 1983, y = -Inf, label = "Men's rate higher ↓",
           hjust = 0, vjust = -1, size = 3.2, color = "grey30") +
  geom_text_repel(data = filter(gap, YEAR == max(YEAR)),
                  aes(label = educ_group), hjust = 0, nudge_x = 1,
                  direction = "y", segment.color = NA,
                  size = 3.5, fontface = "bold") +
  scale_color_manual(values = educ_colors) +
  scale_x_continuous(breaks = seq(1985, 2025, 5),
                     expand = expansion(mult = c(0.01, 0.15))) +
  labs(
    title    = "Who gets hit harder depends on the recession",
    subtitle = "Women's minus men's unemployment rate (percentage points), ages 25+, 1980–2025",
    x = NULL, y = "Gap (percentage points)",
    caption  = "Source: IPUMS CPS basic monthly files, weighted with WTFINL. Shaded areas are NBER recessions."
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank())

p2

ggsave("output/figures/fig2_unemp_by_sex_educ.png", p2,
       width = 9, height = 6.5, dpi = 300)

# figure 3

monthly_educ <- read_csv("data/processed/monthly_educ.csv") |>
  mutate(educ_group = factor(educ_group,
                             levels = c("Less than HS", "HS diploma",
                                        "Some college", "Bachelor's+")))
peaks <- tibble(
  recession = factor(c("Great Recession", "COVID-19"),
                     levels = c("Great Recession", "COVID-19")),
  start = as.Date(c("2007-12-01", "2020-02-01"))
)

aligned2 <- peaks |>
  cross_join(monthly_educ) |>
  mutate(months = (year(date) - year(start)) * 12 + (month(date) - month(start))) |>
  filter(months >= -12, months <= 60) |>
  group_by(recession, educ_group) |>
  mutate(baseline = mean(unemp_rate[months < 0]),
         change   = unemp_rate - baseline) |>
  ungroup() |>
  filter(months >= 0,
         educ_group %in% c("Less than HS", "Bachelor's+"))

peak_pts <- aligned2 |>
  group_by(recession, educ_group) |>
  slice_max(change, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(label = sprintf("+%.1f pp", change))

ymax <- max(aligned2$change)

phase_rect <- tibble(
  recession = factor(c("Great Recession", "COVID-19", "COVID-19"),
                     levels = levels(peaks$recession)),
  xmin = c(0, 0, 2),
  xmax = c(26, 2, 24),
  fill = c("#2166AC", "#D6604D", "#D6604D"),
  alpha = c(0.08, 0.18, 0.06)
)

phase_text <- tibble(
  recession = factor(c("Great Recession", "Great Recession", "COVID-19", "COVID-19"),
                     levels = levels(peaks$recession)),
  x     = c(13, 59, 5, 26),
  y     = c(ymax * 0.95, ymax * 0.85, ymax * 0.80, ymax * 0.35),
  hjust = c(0.5, 1, 0, 0),
  label = c("Slow climb:\npeak after ~2 years",
            "Still above the\npre-recession level\nafter 5 years",
            "Spike: peak within\n2 months",
            "Back near the\npre-recession level\nwithin ~2 years")
)

p3 <- ggplot(aligned2, aes(x = months, y = change, color = educ_group)) +
  geom_rect(data = phase_rect,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE,
            fill = phase_rect$fill, alpha = phase_rect$alpha) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_text(data = tibble(recession = factor("Great Recession",
                                             levels = levels(peaks$recession))),
            aes(x = 60, y = 0, label = "Pre-recession level"),
            inherit.aes = FALSE, hjust = 1, vjust = -0.5,
            size = 3, color = "grey40") + 
  geom_line(linewidth = 1.1) +
  geom_point(data = peak_pts, size = 2.8) +
  geom_label(data = peak_pts, aes(label = label),
             vjust = -0.5, size = 3.3, fontface = "bold", show.legend = FALSE,
             fill = "white", label.size = 0, alpha = 0.85) +
  geom_text(data = phase_text,
            aes(x = x, y = y, label = label, hjust = hjust),
            inherit.aes = FALSE, size = 3.2, color = "grey25",
            lineheight = 0.9) +
  facet_wrap(~ recession, nrow = 1) +
  scale_color_manual(values = educ_colors) +
  scale_x_continuous(breaks = seq(0, 60, 12)) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(
    title    = "After COVID, unemployment peaked in two months. After 2008, it took two years.",
    subtitle = "Change in monthly unemployment rate since the recession began, relative to the prior 12-month average, ages 25+",
    x = "Months since recession began",
    y = "Change (percentage points)", color = NULL,
    caption  = "Source: IPUMS CPS basic monthly files (not seasonally adjusted), weighted with WTFINL. Recession start dates from NBER."
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top",
        plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold", size = 12),
        panel.grid.minor = element_blank(),
        panel.spacing = unit(1.5, "lines"))

p3

ggsave("output/figures/fig3_recession_aligned.png", p3,
       width = 11, height = 5.5, dpi = 300)