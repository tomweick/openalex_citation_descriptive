################
### OVERVIEW ###
################

# This script connects to the API and does minimal data wrangling
# 1. Request a list of n = 1000 authors
# 2. Extract the id's from the authors
# 3. Use id to request a list of each authors total works
# 4. Export the list to /data as JSON

# NOTE: Please make sure to enter your OpenAlex API key (l. 37) when running the script.
# OpenAlex API key can be requested / accessed here:
# https://docs.openalex.org/how-to-use-the-api/api-overview
# https://openalex.org/settings/api

###############
### Imports ###
###############

import pyalex as pa
from pyalex import Works, Authors
from pyalex import config

import time
import json
import os
from itertools import chain

#################
### API SETUP ###
#################

config.max_retries = 1
config.retry_backoff_factor = 0.1
config.retry_http_codes = [429, 500, 503]

# pa.config.api_key = "<>" # Put your API key here and uncomment the line

##########################
### GET RANDOM AUTHORS ###
##########################

data_authors_raw = []

for _ in range(1000):
    author = Authors().random()
    data_authors_raw.append(dict(author))
    time.sleep(0.1)
    print(f" Author fetched, total: {len(data_authors_raw)}")

############################
### CREATING THE DATASET ###
############################

os.makedirs("data", exist_ok=True)

with open("data/data_authors_raw.json", "w", encoding="utf-8") as f:
    json.dump(
        data_authors_raw, f, ensure_ascii=False, indent=2
    ) # Export a preliminary dataset

print("Saved random authors to data_authors_raw.json")

# Read the created file to memory

with open("data/data_authors_raw.json", "r", encoding="utf-8") as f:
    data_raw_authors = json.load(f)

print("Loaded authors into memory")

####################
### EXTRACT id's ###
####################

# This part accesses id's from the created Authors list

data_authors_id = [author["id"] for author in data_raw_authors]

# Save to file

with open("data/data_authors_ids.json", "w", encoding="utf-8") as f:
    json.dump(data_authors_id, f, ensure_ascii=False, indent=2)

print("Saved author id's to data_authors_ids.json")

# Get publication history of authors in all_ids

data_author_works = {}

for author_id in data_authors_id:
    works_query = Works().filter(author={"id": author_id})

    # Pagination allows to get more than 25 authors per researcher
    works = list(chain(*works_query.paginate(per_page=200)))

    data_author_works[author_id] = works

    time.sleep(0.2)
    print(f"Works for author {author_id} fetched, total: {len(works)}")

# print to a file

with open("data/data_authors_works_raw.json", "w", encoding="utf-8") as f:
    json.dump(data_author_works, f, ensure_ascii=False, indent=2)

print("Saved author works to data_authors_works_raw.json")