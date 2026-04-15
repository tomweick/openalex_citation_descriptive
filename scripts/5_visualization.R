################
### OVERVIEW ###
################

# This script accesses information produced from 4_analysis.R and creates and exports plots.

# It is reccomended to open the project via the CAMR.Rproj file, otherwise:
# setwd("") Uncomment and fill in.

paths_root <- ".."
renv::load(project = paths_root)

library("here")
library("renv")
library("gt")
library("ggplot2")
library("webshot2")

source(here::here("scripts", "4_analysis.R"))

output <- here::here("output")

if (!dir.exists(output)) {
  dir.create(output, recursive = TRUE)
}

# Frequencies overview ----------------------------------------------------

tbl_authors_works <- tibble::tibble(
  groups = c(
    "No migration",
    "Internal migration",
    "International migration",
    "Total count",
    "Total average"
  ),
  one = c(
    paste0(unique_no_authors, " <br>(", round((unique_no_authors/(unique_total_authors)*100), 2), "%)"),
    paste0(unique_aff_authors, " <br>(", round((unique_aff_authors/(unique_total_authors)*100), 2), "%)"),
    paste0(unique_country_authors, " <br>(", round((unique_country_authors/(unique_total_authors)*100), 2), "%)"),
    paste0(unique_total_authors, "<br>(100%)"),
    paste0("/")
  ),
  two = c(
    paste0(works_no, " <br>(", round((works_no/(works_total)*100), 2), "%)"),
    paste0(works_aff, " <br>(", round((works_aff/(works_total)*100), 2), "%)"),
    paste0(works_cou, " <br>(", round((works_cou/(works_total)*100), 2), "%)"),
    paste0(works_total, "<br>(100%)"),
    paste0("/")
  ),
  three = c(
    paste0(round(avg_c_no, 2)),
    paste0(round(avg_c_aff, 2)),
    paste0(round(avg_c_cou, 2)),
    paste0("/"),
    paste0(round(avg_c_total, 2))
  ),
  four = c(
    paste0(round(avg_c_no_t, 2)),
    paste0(round(avg_c_aff_t, 2)),
    paste0(round(avg_c_cou_t, 2)),
    paste0("/"),
    paste0(round(avg_c_total_t, 2))
  )
)

# Render gt table

tbl_authors_works <- tbl_authors_works %>%
  gt() %>%
  fmt_markdown(columns = c(one, two)) %>%
  cols_label(
    groups = "Migration group",
    one = "Authors",
    two = "Works",
    three = "Average citations",
    four = "Average year normalised citations"
  ) %>%
  tab_header(title = "Descriptive Statistics: Authors, Works, Average Citations, Average Year Normalised Citations by Migration Groups") %>%
               tab_source_note(
                 source_note = "Notes: 1) International migration is by default a subset of internal migration. The groups are operationalised as mutually exclusive manually. 2) Time effects heavily influence the results, despite time normalisation.")

file_path <- file.path(output, "1_descriptives.pdf")
gtsave(tbl_authors_works, filename = file_path)

# Each table is saved as a full-page A4 PDF

# Average citation change within authors ----------------------------------

# For internal migration

data_analysis_temp <- data_analysis %>%
  filter(is.finite(a_diff_tn)) %>%
  filter(migration_type == 1)

works_temp     <- nrow(data_analysis_temp)
authors_temp  <- n_distinct(data_analysis_temp$person_id)

mean_a_diff_tn <- mean(data_analysis_temp$a_diff_tn)

hist2 <- ggplot(data_analysis_temp, aes(x = a_diff_tn)) +
  geom_histogram(
    bins = 60,
    fill = "#3C3C3C",
    color = "black",
    linewidth = 0.4
  ) +
  labs(
    x = "Time normalised citation differences in individual authors \n after internal migration",
    y = "Count",
    title = paste(
      "Histogram: Time Normalised Citation Differences \nin Individual Authors After Internal Migration",
      "\nN Works =", works_temp,
      ", N Authors =", authors_temp,
      ", Mean =", round(mean_a_diff_tn, 3)
    )
  ) +
  theme_classic(base_size = 14) +
  coord_cartesian(xlim = c(-5, 5), ylim = c(0, 1000))

file_path <- file.path(output, "2_hist_cit_change_int.pdf")
ggsave(filename = file_path, plot = hist2, width = 6, height = 4)

hist2

# For international migration

data_analysis_temp <- data_analysis %>%
  filter(is.finite(c_diff_tn)) %>%
  filter(migration_type == 2)

mean_c_diff_tn <- mean(data_analysis_temp$c_diff_tn)

works_temp     <- nrow(data_analysis_temp)
authors_temp  <- n_distinct(data_analysis_temp$person_id)

hist3 <- ggplot(data_analysis_temp, aes(x = c_diff_tn)) +
  geom_histogram(
    bins = 60,
    fill = "#3C3C3C",
    color = "black",
    linewidth = 0.4
  ) +
  labs(
    x = "Time normalised citation differences in individual authors \n after international migration",
    y = "Count",
    title = paste(
      "Histogram: Time Normalised Citation Differences \nin Individual Authors after International Migration",
      "\nN Works =", works_temp,
      ", N Authors =", authors_temp,
      ", Mean =", round(mean_c_diff_tn, 3)
    )
  ) +
  theme_classic(base_size = 14) +
  coord_cartesian(xlim = c(-5, 5), ylim = c(0, 1000))

file_path <- file.path(output, "3_hist_cit_change_country.pdf")
ggsave(filename = file_path, plot = hist3, width = 6, height = 4)

# Scatterplot: time-normalised citation by work age ------------------------------------

scatter <- ggplot(data_analysis, aes(x = work_age, y = year_norm_cit, color = factor(migration_type))) +
  geom_point(alpha = 0.2) +             
  geom_smooth(method = "loess", se = FALSE) +  
  scale_color_manual(
    values = c("0" = "darkgrey", "1" = "#3c8aff", "2" = "orange"), 
    labels = c("No migration", "Internal migration", "International migration"),
    name = "Career long migration"
  ) +
  labs(
    x = "Work age",
    y = "Time normalised citations per work",
    title = paste(
      "Scatterplot:\nTime Normalised Citations and Work Age\n by Migration Groups",
      "\nN Works =", nrow(data_analysis), ", N Authors =", n_distinct(data_analysis$person_id)
    )
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5)
  ) +
  coord_cartesian(xlim = c(0, 75), ylim = c(0, 5))

file_path <- file.path(output, "4_scatter_tn_cit.pdf")
ggsave(filename = file_path, plot = scatter, width = 9, height = 6)

# Sample size flowchart ---------------------------------------------------

flow_tbl <- tibble::tibble(
  step = c(
    "Raw data",
    "Remove cases: missing institution",
    "Remove cases: missing country",
    "Remove cases: missing new vars"
  ),
  n = c(
    paste0(s_1_before_a, " (", s_1_before_w, ")"),
    paste0(s_2_miss_aff_a, " (", s_2_miss_aff_w, ")"),
    paste0(s_3_miss_aff_a, " (", s_3_miss_aff_w, ")"),
    paste0(s_4_miss_all_a, " (", s_4_miss_all_w, ")")
  ),
  Difference = c(
    "/",
    paste0(s_2_miss_aff_a - s_1_before_a, " (", s_2_miss_aff_w - s_1_before_w, ")"),
    paste0(s_3_miss_aff_a - s_2_miss_aff_a, " (", s_3_miss_aff_w - s_2_miss_aff_w, ")"),
    paste0(s_4_miss_all_a - s_3_miss_aff_a, " (", s_4_miss_all_w - s_3_miss_aff_w, ")")
  ),
  pct_of_raw = c(
    "100% (100%)",
    paste0(round(100 * s_2_miss_aff_a / s_1_before_a, 1), "% (",
           round(100 * s_2_miss_aff_w / s_1_before_w, 1), "%)"),
    paste0(round(100 * s_3_miss_aff_a / s_1_before_a, 1), "% (",
           round(100 * s_3_miss_aff_w / s_1_before_w, 1), "%)"),
    paste0(round(100 * s_4_miss_all_a / s_1_before_a, 1), "% (",
           round(100 * s_4_miss_all_w / s_1_before_w, 1), "%)")
  )
)

# Render gt table

note_text <- paste0(
  "1) “New vars” refers to variables that were manually inferred from the data.
  2) Some analyses require additional cleaning of missing values; where applicable, the corresponding sample size (N) is reported.
  3) ", amount_flattened, " cases of multiple affiliations per author (per work) were flattened to the first affiliation (",
  round(100 * amount_flattened / s_1_before_w, 1), "% of all works)."
)


flow_tbl <- flow_tbl %>%
  gt() %>%
  cols_label(
    step = "Sample progression",
    n = "N: Authors (Works)",
    Difference = "Difference",
    pct_of_raw = "%"
  ) %>%
  tab_header(title = "Flowtable: Evolution of the Sample Size") %>%
  tab_source_note(
    source_note = note_text)

file_path <- file.path(output, "5_sample_flowchart.pdf")
gtsave(flow_tbl, filename = file_path)

# Each table is saved as a full-page A4 PDF