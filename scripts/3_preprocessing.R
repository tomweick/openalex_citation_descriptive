################
### OVERVIEW ###
################

# This script reads in the data previously exported by the 2_wrangling.py script
# and documents different sample sizes at stages of data cleaning.
# The data is exported as R native .rdf file

# It is reccomended to open the project via the CAMR.Rproj file, otherwise:
# setwd("") Uncomment and fill in.

paths_root <- ".."
renv::load(project = paths_root)

library("dplyr")
library("here")
library("renv")


# Read the JSON -----------------------------------------------------------

path_data <- here::here("data", "data_analysis_raw.json")

txt <- readLines(path_data)
txt <- gsub(": NaN", ": null", txt)

data_raw <- jsonlite::fromJSON(paste(txt, collapse = ""))

# Data cleaning / adjusting -----------------------------------------------------------

s_1_before_w <- as.numeric(nrow(data_raw))
s_1_before_a <- length(unique(data_raw$person_id))

# Time variable as years only

data_raw <- data_raw |>
  mutate(
    time_id = as.integer(substr(time_id, 1, 4))  # Keep only first 4 characters -> year
  )

# Remove missings in affiliations

data_raw <- data_raw[sapply(data_raw$affiliation_id, length) > 0, ] # countries is inferred by affiliation data

s_2_miss_aff_w <- as.numeric(nrow(data_raw))
s_2_miss_aff_a <- length(unique(data_raw$person_id))

data_raw <- data_raw[sapply(data_raw$countries, length) > 0, ]

s_3_miss_aff_w <- as.numeric(nrow(data_raw))
s_3_miss_aff_a <- length(unique(data_raw$person_id))

# Remove other missings

data_raw <- data_raw %>%
  filter(
    !is.na(person_id) &
      !is.na(time_id) &
      !is.na(affiliation_id) &
      !is.na(countries) &
      !is.na(paper_id) &
      !is.na(cited_by_count)
  )

s_4_miss_all_w <- as.numeric(nrow(data_raw))
s_4_miss_all_a <- length(unique(data_raw$person_id))

# Flatten multiple affiliations to the first one listed

amount_flattened <- sum(sapply(data_raw$affiliation_id, length) > 1)

data_raw$affiliation_id <- sapply(data_raw$affiliation_id, function(x) {
  if (!is.character(x)) return(NA_character_)
  x[1]  # access first string
})

data_raw$countries <- sapply(data_raw$countries, function(x) {
  if (!is.character(x)) return(NA_character_)
  x[1]  # access first string
})

# Flag migrating researchers ----------------------------------------------

# Flag by "did this person change at all, during their career"

data_raw <- data_raw %>%
  group_by(person_id) %>%
  mutate(
    # Any affiliation change
    affiliation_changed = ifelse(n_distinct(affiliation_id) > 1, 1, 0),
    
    # Any country change
    country_changed = ifelse(n_distinct(countries) > 1, 1, 0),
    
    # Affiliation change that is NOT a country change
    other_affiliation_change = ifelse(affiliation_changed == 1 & country_changed == 0, 1, 0)
  ) %>%
  ungroup()

data_raw <- data_raw %>%
  mutate(migration_type = case_when(
    country_changed == 1 ~ 2,                             # international migration
    other_affiliation_change == 1 ~ 1,                    # internal migration
    TRUE ~ 0                                              # no migration
  ))

# Flag by, within one author, was the paper published when migrated yes or no

data_raw <- data_raw %>%
  arrange(person_id, time_id) %>%
  group_by(person_id) %>%
  mutate(
    # Flag where current affiliation differs from first known affiliation
    affiliation_migrated = as.integer(cumany(affiliation_id != first(affiliation_id)))
  ) %>%
  ungroup()

data_raw <- data_raw %>%
  arrange(person_id, time_id) %>%
  group_by(person_id) %>%
  mutate(
    # Flag where current affiliation differs from first known countries
    country_migrated = as.integer(cumany(countries != first(countries)))
  ) %>%
  ungroup()

# Export ------------------------------------------------------------------

saveRDS(data_raw, here("data", "data_analysis.rds"))