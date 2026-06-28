# Publication Volume and Academic Migration (OpenAlex)

This project is under active development.

This project analyses whether academic migration is associated with changes in publication performance among researchers.

## Overview

Does migration coincide with changes in publication performance? This project provides reports of Key Performance Indicators of research performance, such as time normalized citation differences. Analyses are time-normalized and compare groups of mobile and non-mobile researchers. This is a presentation of observational and correlational analysis, causality can not be inferred.

Important information about the sample and preprocessing steps is provided at the end of the report.

The PyAlex API in Python is used to access OpenAlex data (Priem et al., 2022). Statistical Analysis is done in R and reported with Quarto.

Planned improvements include configurable data collection, and data- and report versioning.

## Features

-   Reproducible end-to-end
-   Automated OpenAlex data collection via the PyAlex API
-   Automated data cleaning and preprocessing
-   Sample size tracking
-   Report generation with Quarto

## Tech Stack

-   **Python / R**
-   **Quarto:** Report generation
-   **PyAlex:** OpenAlex API
-   **Virtual Environment** (renv for R, venv for Python)
-   **Git**

## Getting Started

To get a local copy of this project up and running, follow these steps.

### Requirements

-   **R** (Tested for ver 4.5.1)
    -   **IDE**: R Studio (to Open files through the .rproj file)
    -   Globally installed R Packages **"renv"** and **"here"**
-   **Python** (tested for ver 3.13.3)
-   OpenAlex API key (<https://developers.openalex.org/guides/authentication>)

## Replication instruction

1)  Install Python 3.13 and R 4.5.1

2)  Activate Virtual Environment (uv), install Python depencies and run

```         
  uv sync
   
  python scripts/1_api_calls.py                   # API Key required
  python scripts/2_wrangling.py
```

3)  Install global requirements for R (see above)

```         
  R console:
  
  install.packages(c("renv", "here"))
```

4.  Render report.qmd (R scripts are automatically sourced during rendering)

## Scripts

### 1. `1_api_calls.py`

API setup: requires an API key (free access: <https://developers.openalex.org/guides/authentication>)

-   Pulls 1,000 random author IDs

-   Retrieves all publications for all 1,000 authors

-   Saves outputs to:

    -   `data_authors_raw.json`

    -   `data_authors_works_raw.json`

### 2. `2_wrangling.py`

-   Filters previously created data for relevant information

-   Structures dataset for downstream analysis

-   Saves output to `data_analysis_raw.json`

### 3. `3_preprocessing.py`

-   Performs additional data cleaning:

    -   Removes duplicates

    -   Multi-affiliation publications

-   Exports final dataset to `data_analysis.rds`

### 4. `4_analysis.py`

-   Constructs key performance metrics

### 5. `5_visualization.py`

-   Creates all visualizations for the analysis

## Outputs

Aggregated statistical outputs and visualizations are stored in `/output`.

## Sources

-   OpenAlex: <https://doi.org/10.48550/arXiv.2205.01833> (Priem et al., 2022)

-   PyAlex: <https://github.com/J535D165/pyalex>

-   Partly based on: Github ReadMe Template: <https://github.com/Sumonta056/Readme-Template>

## Literature

-   Priem, J., Piwowar, H., & Orr, R. (2022). *OpenAlex: A fully-open index of scholarly works, authors, venues, institutions, and concepts*. OpenAlex. <https://doi.org/10.48550/arXiv.2205.01833>
