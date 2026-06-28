################
### OVERVIEW ###
################

# This script performs the main analysis.
# It prepares variables used for plotting in 5_visualization.R
# and calculates group-specific descriptive statistics and means

# It is reccomended to open the project via the CAMR.Rproj file, otherwise:
# setwd("") Uncomment and fill in.

paths_root <- ".."
renv::load(project = paths_root)

library("here")
library("renv")

source(here::here("scripts", "3_preprocessing.R"))

data_analysis <- readRDS(here::here("data", "data_analysis.rds"))

# Feature engineering -----------------------------------------------------

# Age of each work in years

data_analysis <- data_analysis %>%
  group_by(person_id) %>%
  mutate(
    work_age = max(data_analysis$time_id, na.rm = TRUE) - time_id
    # Work age is calculated relative to the most recent publication year in the dataset
  ) %>%
  ungroup()

# Descriptives ------------------------------------------------------------

# Unique authors affiliation change

unique_aff_authors <- data_analysis %>%
  group_by(person_id) %>%
  summarise(
    affiliation_changed = max(affiliation_changed),
    country_changed     = max(country_changed)
  ) %>%
  filter(affiliation_changed == 1 & country_changed == 0) %>%
  nrow()

# Unique authors country change

unique_country_authors <- data_analysis %>%
  group_by(person_id) %>%
  summarise(country_changed = max(country_changed)) %>%
  filter(country_changed == 1) %>%
  nrow()

# Unique authors no change

unique_no_authors <- data_analysis %>%
  group_by(person_id) %>%
  summarise(
    affiliation_changed = max(affiliation_changed),
    country_changed     = max(country_changed)
  ) %>%
  filter(affiliation_changed == 0 & country_changed == 0) %>%
  nrow()

# Total unique authors

unique_total_authors <- data_analysis %>%
  group_by(person_id) %>%
  summarise() %>%
  nrow()

# Average citations

avg_c_no <- mean(
  data_analysis$cited_by_count[data_analysis$country_changed == 0 & data_analysis$affiliation_changed == 0]
)

avg_c_aff <- mean(
  data_analysis$cited_by_count[data_analysis$affiliation_changed == 1 & data_analysis$country_changed == 0]
)

avg_c_cou <- mean(
  data_analysis$cited_by_count[data_analysis$country_changed == 1]
)

avg_c_total <- mean(
  data_analysis$cited_by_count
)

# Amount of works for each group

works_no <- data_analysis %>%
  filter(affiliation_changed == 0 & country_changed == 0) %>%
  nrow()

# Works for authors with only affiliation migration (no country change)

works_aff <- data_analysis %>%
  filter(affiliation_changed == 1 & country_changed == 0) %>%
  nrow()

# Works for authors with any country change

works_cou <- data_analysis %>%
  filter(country_changed == 1) %>%
  nrow() 

# Total

works_total <- data_analysis %>%
  nrow()

# Time sensitive descriptives ---------------------------------------------

# Year-normalized citation count for every work
# introduces recency bias (smaller denominator)
# but accounts for exposure to being cited.

data_analysis <- data_analysis %>%
  mutate(
    year_norm_cit = cited_by_count / ifelse(work_age > 0, work_age, 1)
  )

# Average time normalized citations

# Average citations for works with no change

avg_c_no_t <- data_analysis %>%
  filter(country_changed == 0 & affiliation_changed == 0) %>%
  summarise(avg_cit = mean(year_norm_cit, na.rm = TRUE)) %>%
  pull(avg_cit)

# Average citations for works with affiliation change only (no country change)

avg_c_aff_t <- data_analysis %>%
  filter(affiliation_changed == 1 & country_changed == 0) %>%
  summarise(avg_cit = mean(year_norm_cit, na.rm = TRUE)) %>%
  pull(avg_cit)

# Average citations for works with country change

avg_c_cou_t <- data_analysis %>%
  filter(country_changed == 1) %>%
  summarise(avg_cit = mean(year_norm_cit, na.rm = TRUE)) %>%
  pull(avg_cit)

# Average citations for all works

avg_c_total_t <- data_analysis %>%
  summarise(avg_cit = mean(year_norm_cit, na.rm = TRUE)) %>%
  pull(avg_cit)

# Average increase in citations per paper / divided by age of the work

data_analysis <- data_analysis %>%
  group_by(person_id) %>%
  mutate(
    avg_c_before_aff = mean(year_norm_cit[affiliation_migrated == 0], na.rm = TRUE),
    avg_c_after_aff  = mean(year_norm_cit[affiliation_migrated == 1], na.rm = TRUE),
    avg_c_before_cou = mean(year_norm_cit[country_migrated == 0 & affiliation_migrated == 0], na.rm = TRUE),
    avg_c_after_cou  = mean(year_norm_cit[country_migrated == 1], na.rm = TRUE)
  ) %>%
  ungroup()

# differences in citation

data_analysis <- data_analysis %>%
  mutate(
    a_diff = avg_c_after_aff - avg_c_before_aff
  )

data_analysis <- data_analysis %>%
  mutate(
    c_diff = avg_c_after_cou - avg_c_before_cou
  )

# Time-normalized difference

data_analysis <- data_analysis %>% 
  mutate(a_diff_tn = (avg_c_after_aff - avg_c_before_aff) / work_age,
         c_diff_tn = (avg_c_after_cou - avg_c_before_cou) / work_age )
