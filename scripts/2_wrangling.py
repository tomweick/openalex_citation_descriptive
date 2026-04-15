################
### OVERVIEW ###
################

# This script accesses the dataframe created in script 1_api_calls.py
# and does some initial data preprocessing, for easier analysis in R
# 1. It loads the JSON from script 1_api_calls.py
# 2. In one big loop it accesses key information from the JSON and appends rows to the dictionary 'rows'
# 3. Some columns like 'author_num' are created for better human readability later in the workflow
# 4. The full dataframe is exported as JSON for analysis
# 5. A small sample of the dataframe is exported as .csv for visual verification

import json
import pandas as pd

with open("data/data_authors_works_raw.json", "r", encoding="utf-8") as f:
    data_raw_authors = json.load(f)

#######################
### CREATING THE DF ###
#######################

# Access information in the JSON and append to rows

rows = []

for author_id, works in data_raw_authors.items():
    for work in works:

        # Check author specific info
        author_countries = None
        author_institutions = []

        # Loop through authorships to find matching author
        for authorship in work["authorships"]:
            if authorship["author"]["id"] == author_id:
                author_countries = authorship.get("countries")

                # Extract institution display names
                institutions_list = authorship.get("institutions", [])
                author_institutions = []
                for inst in institutions_list:
                    if "display_name" in inst:
                        author_institutions.append(inst["display_name"])
                break  # stop after finding the matching author

# Append individual rows
        rows.append({
            "paper_id": work["id"],
            "person_id": author_id,
            "affiliation_id": author_institutions,
            "time_id": work["publication_date"],
            "countries": author_countries,
            "cited_by_count": work["cited_by_count"]
        })

df = pd.DataFrame(rows)

#########################################
### FEATURE ENGINEERING & READABILITY ###
#########################################

# Make a copy

df_readable = df.copy()

# Enumerate authors: unique numeric id per author

author_mapping = {
    author: i + 1 for i, author in enumerate(df_readable["person_id"].unique())
}

df_readable["author_num"] = df_readable["person_id"].map(author_mapping)

# Enumerate works of each author individually

df_readable["work_num"] = df_readable.groupby("person_id").cumcount() + 1

# Average raw citations per author

avg_citations = (
    df_readable.groupby("person_id")["cited_by_count"]
    .mean()
    .rename("avg_cited_by_count")
)

# Include avg_citations back into df_readable

df_readable = df_readable.merge(avg_citations, on="person_id")

df_readable = df_readable[
    [
        "author_num",
        "person_id",
        "paper_id",
        "work_num",
        "time_id",
        "countries",
        "affiliation_id",
        "cited_by_count",
        "avg_cited_by_count"
    ]
]

##############
### Export ###
##############

# Export to a JSON file for further use

with open("data/data_analysis_raw.json", "w", encoding="utf-8") as f:
    json.dump(df_readable.to_dict(orient="records"), f, ensure_ascii=False, indent=2)
print("Saved author works to data_analysis_raw.json")

# This creates a csv file for human readable manual data inspection

df_check = df_readable.head(30)
df_check.to_csv("data/author_works_check.csv", index=False)