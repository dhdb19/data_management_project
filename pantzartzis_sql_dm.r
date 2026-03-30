library("tidyverse")
library("RPostgres")
library("DBI")
library("sf")
library("arrow")
library("geoarrow")
library("sfarrow")
library("purrr")
library("glue")

# ---- Some helpful lists


# The EU uses non-standard two-letter codes for Greece and the UK, so they appear twice in the list:  United Kingdom as UK (EU scheme), and GB (ISO 3166-1 alpha-2)), Greece as EL (EU scheme), and GR (ISO 3166-1 alpha-2)

europe <- c(
  "AD",
  "AL",
  "AM",
  "AT",
  "AZ",
  "BA",
  "BE",
  "BG",
  "BY",
  "CH",
  "CY",
  "CZ",
  "DE",
  "DK",
  "EE",
  "EL",
  "ES",
  "FI",
  "FR",
  "GB",
  "GE",
  "GR",
  "HR",
  "HU",
  "IE",
  "IS",
  "IT",
  "KZ",
  "LI",
  "LT",
  "LU",
  "LV",
  "MC",
  "MD",
  "ME",
  "MK",
  "MT",
  "NL",
  "NO",
  "PL",
  "PT",
  "RO",
  "RS",
  "RU",
  "SE",
  "SI",
  "SK",
  "SM",
  "TR",
  "UA",
  "UK",
  "VA",
  "XK"
)



eu <- europe[!europe %in% c(
  "AD", "AL", "AM", "AZ", "BA", "BY", "CH", "GE", "IS", "KZ",
  "LI", "MC", "MD", "ME", "MK", "NO", "RS", "RU", "SM",
  "TR", "UA", "VA", "XK", "GB"
)]

efta <- c("NO", "LI", "IS")
eea <- c(eu, efta)

eustat_iso <- c(eu, "NO", "CH", "LI")




# ---- Establish datbase connection
db <- dbConnect(Postgres(),
  dbname = "dataproject",
  user = "dpuser",
  password = "dppassword",
)


# Drop all tables and check that databse is empty


dbExecute(
  db,
  "DROP SCHEMA public CASCADE"
)

dbExecute(
  db,
  "CREATE SCHEMA public"
)

dbGetQuery(
  db,
  "
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema='public'
  AND table_type='BASE TABLE';"
)

# ---- Check if postgis and tablefunc extensions are activated
tryCatch(
  expr = {
    dbExecute(db, "CREATE EXTENSION IF NOT EXISTS postgis")
  },
  error = function(e) {
    message("The postgis extension has already been loaded")
  }
)

tryCatch(
  expr = {
    dbExecute(db, "CREATE EXTENSION IF NOT EXISTS tablefunc")
  },
  error = function(e) {
    message("The tablefunc extension has already been loaded")
  }
)

# ---- Helper function to write dataframes to the database
write_tbl_db <- function(data) {
  tryCatch(
    expr = {
      dbWriteTable(
        db,
        deparse(
          substitute(data)
        ),
        data
      )
    },
    error = function(e) {
      message("This table already exists")
    }
  )
}

# ---- Helper function to iteratively execute SQL queries.
# Takes an iterator, usually a character vector, where each string is a SQL query

db_execute <- function(queries) {
  map(
    queries,
    function(query) {
      dbExecute(db, query)
    }
  )
}


# ---- Helper function to iteratively get SQL queries
db_query <- function(queries) {
  map(
    queries,
    function(query) {
      dbGetQuery(db, query)
    }
  )
}



# ---- Load the ESS6 dataset and clean the data
ess6 <- read_csv("data/ess6.csv")

# Writing to the database may take some time
write_tbl_db(ess6)


# Rename columns

db_execute(c(
  "ALTER TABLE ess6
  RENAME COLUMN essround TO ess_round",
  "ALTER TABLE ess6
  RENAME COLUMN regunit TO nuts_level",
  "ALTER TABLE ess6
  RENAME COLUMN region TO nuts_id",
  "ALTER TABLE ess6
  RENAME COLUMN imsmetn TO imm_allow_same",
  "ALTER TABLE ess6
  RENAME COLUMN imdfetn TO imm_allow_different",
  "ALTER TABLE ess6
  RENAME COLUMN impcntr TO imm_allow_poor",
  "ALTER TABLE ess6
  RENAME COLUMN imbgeco TO imm_economy",
  "ALTER TABLE ess6
  RENAME COLUMN imueclt TO imm_culture",
  "ALTER TABLE ess6
  RENAME COLUMN imwbcnt TO imm_worse_better"
))

# Replace NA values with actual NAs.
# Variables are Likert-scale with special reserved values for different kids os missing data.
# See the codebook
# ! This takes longer to execute

db_execute(c(
  "UPDATE ess6
  SET imm_allow_same =
    CASE
      WHEN imm_allow_same  BETWEEN 1 AND 4 THEN imm_allow_same
      ELSE NULL
    END",
  "UPDATE ess6
  SET imm_allow_different =
    CASE
      WHEN imm_allow_different  BETWEEN 1 AND 4 THEN imm_allow_different
      ELSE NULL
    END",
  "UPDATE ess6
  SET imm_allow_poor =
    CASE
      WHEN imm_allow_poor  BETWEEN 1 AND 4 THEN imm_allow_poor
      ELSE NULL
    END",
  "UPDATE ess6
  SET imm_economy =
    CASE
      WHEN imm_economy  BETWEEN 1 AND 10 THEN imm_economy
      ELSE NULL
    END",
  "UPDATE ess6
  SET imm_culture =
    CASE
      WHEN imm_culture  BETWEEN 1 AND 10 THEN imm_culture
      ELSE NULL
    END",
  "UPDATE ess6
  SET imm_worse_better =
    CASE
      WHEN imm_worse_better  BETWEEN 1 AND 10 THEN imm_worse_better
      ELSE NULL
    END"
))




# ---- Load the ESS10 dataset and clean the data

ess10 <- read_csv("data/ess10.csv")

# Writing to the database may take some time

write_tbl_db(ess10)


# Rename columns
db_execute(c(
  "ALTER TABLE ess10
  RENAME COLUMN essround TO ess_round",
  "ALTER TABLE ess10
  RENAME COLUMN regunit TO nuts_level",
  "ALTER TABLE ess10
  RENAME COLUMN region TO nuts_id",
  "ALTER TABLE ess10
  RENAME COLUMN imsmetn TO imm_allow_same",
  "ALTER TABLE ess10
  RENAME COLUMN imdfetn TO imm_allow_different",
  "ALTER TABLE ess10
  RENAME COLUMN impcntr TO imm_allow_poor",
  "ALTER TABLE ess10
  RENAME COLUMN imbgeco TO imm_economy",
  "ALTER TABLE ess10
  RENAME COLUMN imueclt TO imm_culture",
  "ALTER TABLE ess10
  RENAME COLUMN imwbcnt TO imm_worse_better"
))

# Replace NA values with actual NAs.
# Variables are Likert-scale with special reserved values for different kids os missing data.
# See the codebook
# ! This takes longer to execute


db_execute(c(
  "UPDATE ess10
  SET imm_allow_same =
    CASE
      WHEN imm_allow_same  BETWEEN 1 AND 4 THEN imm_allow_same
      ELSE NULL
    END",
  "UPDATE ess10
  SET imm_allow_different =
    CASE
      WHEN imm_allow_different  BETWEEN 1 AND 4 THEN imm_allow_different
      ELSE NULL
    END",
  "UPDATE ess10
  SET imm_allow_poor =
    CASE
      WHEN imm_allow_poor  BETWEEN 1 AND 4 THEN imm_allow_poor
      ELSE NULL
    END",
  "UPDATE ess10
  SET imm_economy =
    CASE
      WHEN imm_economy  BETWEEN 1 AND 10 THEN imm_economy
      ELSE NULL
    END",
  "UPDATE ess10
  SET imm_culture =
    CASE
      WHEN imm_culture  BETWEEN 1 AND 10 THEN imm_culture
      ELSE NULL
    END",
  "UPDATE ess10
  SET imm_worse_better =
    CASE
      WHEN imm_worse_better  BETWEEN 1 AND 10 THEN imm_worse_better
      ELSE NULL
    END"
))


# ---- Load the 2021 EUROSTAT census 1km × 1km data
# ! This takes longer to execute

census_2021_grid <- st_read_parquet("data/ESTAT_Census_2021_V2.parquet")

# Writing to the database may take some time

write_tbl_db(census_2021_grid)

# Rename columns and activate geographic column
# Create index on the geometry variable

execute_queries <- db_execute(c(
  "ALTER TABLE census_2021_grid
    ALTER COLUMN geom
    TYPE geometry(polygon, 3035)",
  'ALTER TABLE census_2021_grid
    RENAME COLUMN "T" TO total_pop',
  'ALTER TABLE census_2021_grid
    RENAME COLUMN "NAT" TO nat_pop',
  "CREATE INDEX census_2021_index ON census_2021_grid USING GIST (geom)"
))

# Clean up data for entries with nonsensical values

db_execute(c(
  "CREATE TABLE census_2021_clean AS
  SELECT nat_pop, total_pop, geom
  FROM census_2021_grid
  WHERE
      nat_pop >= 0 AND
      total_pop >= 0 AND
      nat_pop != 9999 AND
      total_pop != 9999
  "
))



# ---- Load the dataset of NUTS region geographic boundaries

nuts <- st_read("data/NUTS_RG_60M_2021_3035.gpkg", crs = 3035)

write_tbl_db(nuts)

# Rename columns
# Create index on geometry variable
db_execute(c(
  'ALTER TABLE nuts
  RENAME COLUMN "LEVL_CODE" TO nuts_level',
  'ALTER TABLE nuts
  RENAME COLUMN "NUTS_ID" TO nuts_id',
  "ALTER TABLE nuts
  ADD PRIMARY KEY (nuts_id)",
  "CREATE INDEX nuts_index ON nuts USING GIST (geom)"
))


# ---- Join 2021 census population data (1km × 1km grid-level) with NUTS data, to get NUTS-level share of local immigrant population
# ! This takes longer to execute

db_execute(
  "CREATE TABLE census_2021_nuts AS
    WITH tmp AS (
      SELECT census_2021_grid.nat_pop, census_2021_grid.total_pop, census_2021_grid.geom, nuts.nuts_id, nuts.nuts_level
      FROM census_2021_grid
      JOIN nuts
      ON st_contains(nuts.geom, census_2021_grid.geom)
      )
    SELECT tmp.nuts_id, 1 - (sum(tmp.nat_pop)::decimal / nullif(sum(tmp.total_pop), 0)::decimal) AS imm_share, nuts_level
    FROM tmp
    GROUP BY nuts_id, nuts_level"
)


# Prepare dataset for self-merge to get hierarchical Dataset
# Unit of observation is the "NUTS region" - "local immigrant share of the population" at all NUTS levels
# Observations also contain the "local immigrant share of the population" observation for all greater NUTS levels.
# I.e. an observation at NUTS 3 level, also contains the observation for the larger level 2 and leve 1 region it is contained within.

db_execute(
  c(
    "ALTER TABLE census_2021_nuts
    ADD nuts1 varchar",
    "UPDATE census_2021_nuts
    SET nuts1 = substring(nuts_id, 1, 3)
    WHERE nuts_level > 0",
    "ALTER TABLE census_2021_nuts
    ADD nuts2 varchar",
    "UPDATE census_2021_nuts
    SET nuts2 = substring(nuts_id, 1, 4)
    WHERE nuts_level > 1",
    "ALTER TABLE census_2021_nuts
    ADD nuts3 varchar",
    "UPDATE census_2021_nuts
    SET nuts3 = substring(nuts_id, 1, 5)
    WHERE nuts_level > 2"
  )
)

# Self-join to obtain hierarchical data

db_execute(
  "CREATE TABLE census_2021_joined AS
    SELECT
      n0.imm_share,
      n0.nuts_id,
      n1.imm_share AS imm_share_1,
      n2.imm_share AS imm_share_2,
      n3.imm_share AS imm_share_3,
      n1.nuts_id AS nuts_id1,
      n2.nuts_id AS nuts_id2,
      n3.nuts_id AS nuts_id3
    FROM
      census_2021_nuts n0
    LEFT JOIN census_2021_nuts n1 ON n0.nuts1 = n1.nuts_id
    LEFT JOIN census_2021_nuts n2 ON n0.nuts2 = n2.nuts_id
    LEFT JOIN census_2021_nuts n3 ON n0.nuts3 = n3.nuts_id
    "
)



# ---- Load the 2011 census data

census_2011 <- read_csv("data/census_2011.csv")

write_tbl_db(census_2011)


# Rename columns
db_execute(c(
  'ALTER TABLE census_2011
    RENAME COLUMN "GEO" TO nuts_id',
  'ALTER TABLE census_2011
    RENAME COLUMN "POB" TO immigrant',
  'ALTER TABLE census_2011
    RENAME COLUMN "VALUE" TO value'
))


# Pivot somewhat strange long table format into wider format
# Observations, as downloaded from the EUROSTAT census hub are at the "NUTS-region" - "variable-meaning" - "variable value" level.
# I.e. observation 1: region xy123 - native-born - 5679, observation 2: region xy123 - foreign-born - 5678

db_execute(
  'CREATE TABLE census_2011_clean AS
    SELECT * FROM crosstab(
      \'SELECT nuts_id, immigrant, value
      FROM census_2011
      ORDER BY nuts_id, immigrant\',
      \'SELECT DISTINCT immigrant FROM census_2011 ORDER BY immigrant\'
    ) AS ct(
      nuts_id text,
      "FOR" varchar,
      "NAT" varchar,
      "OTH" varchar,
      "UNK" varchar
    )'
)

# Rename columns
db_execute(c(
  'ALTER TABLE census_2011_clean
    RENAME COLUMN "FOR" TO immigrant',
  'ALTER TABLE census_2011_clean
    RENAME COLUMN "NAT" TO native',
  'ALTER TABLE census_2011_clean
    RENAME COLUMN "OTH" TO other',
  'ALTER TABLE census_2011_clean
    RENAME COLUMN "UNK" TO unknown'
))

# Cleanup and remove non-numeric values from the columns that contain numeric population data
db_execute(c(
  "DELETE FROM census_2011_clean
  WHERE NOT (
    immigrant ~ '^[0-9]+(\\.[0-9]+)?$' AND
    native ~ '^[0-9]+(\\.[0-9]+)?$' AND
    other ~ '^[0-9]+(\\.[0-9]+)?$' AND
    unknown ~ '^[0-9]+(\\.[0-9]+)?$'
)"
))


# Add column containing the NUTS-level of the observation

db_execute(c(
  "ALTER TABLE census_2011_clean
  ADD nuts_level numeric
  ",
  "UPDATE census_2011_clean
  SET nuts_level =
    CASE
      WHEN length(nuts_id) = 2 THEN 0
      WHEN length(nuts_id) = 3 THEN 1
      WHEN length(nuts_id) = 4 THEN 2
      WHEN length(nuts_id) = 5 THEN 3 END
      "
))


# Prepare data for self-join to obtain hierarchical data and calculate variable of interest local immigrant share of population

db_execute(
  c(
    "ALTER TABLE census_2011_clean
    ADD nuts1 varchar",
    "UPDATE census_2011_clean
    SET nuts1 = substring(nuts_id, 1, 3)
    WHERE nuts_level > 0",
    "ALTER TABLE census_2011_clean
    ADD nuts2 varchar",
    "UPDATE census_2011_clean
    SET nuts2 = substring(nuts_id, 1, 4)
    WHERE nuts_level > 1",
    "ALTER TABLE census_2011_clean
    ADD nuts3 varchar",
    "UPDATE census_2011_clean
    SET nuts3 = substring(nuts_id, 1, 5)
    WHERE nuts_level > 2",
    "ALTER TABLE census_2011_clean
    ADD imm_share decimal",
    "UPDATE census_2011_clean
    SET imm_share = immigrant::numeric / nullif(immigrant::numeric + native::numeric + other::numeric + unknown::numeric, 0)"
  )
)


# Self-join to get hierarchical data

db_execute(
  "CREATE TABLE census_2011_joined AS
    SELECT
      n0.imm_share,
      n0.nuts_id,
      n1.imm_share AS imm_share_1,
      n2.imm_share AS imm_share_2,
      n3.imm_share AS imm_share_3,
      n1.nuts_id AS nuts_id1,
      n2.nuts_id AS nuts_id2,
      n3.nuts_id AS nuts_id3
    FROM
      census_2011_clean n0
    LEFT JOIN census_2011_clean n1 ON n0.nuts1 = n1.nuts_id
    LEFT JOIN census_2011_clean n2 ON n0.nuts2 = n2.nuts_id
    LEFT JOIN census_2011_clean n3 ON n0.nuts3 = n3.nuts_id
    "
)



# ---- Join the ESS6 dataset with the 2011 Eurostat census data to get NUTS-level immigrant share of the population

db_execute(
  "CREATE TABLE ess6_prefinal AS
  SELECT
    ess6.ess_round,
    ess6.nuts_id,
    ess6.imm_allow_same,
    ess6.imm_allow_different,
    ess6.imm_allow_poor,
    ess6.imm_economy,
    ess6.imm_culture,
    ess6.imm_worse_better,
    census_2011_joined.imm_share_1,
    census_2011_joined.imm_share_2,
    census_2011_joined.imm_share_3
  FROM ess6
  LEFT JOIN census_2011_joined ON ess6.nuts_id = census_2011_joined.nuts_id"
)



# Join the ESS10 dataset with the 2021 Eurostat census data to get local immigrant share of the population
db_execute(
  "CREATE TABLE ess10_prefinal AS
  SELECT
    ess10.ess_round,
    ess10.nuts_id,
    ess10.imm_allow_same,
    ess10.imm_allow_different,
    ess10.imm_allow_poor,
    ess10.imm_economy,
    ess10.imm_culture,
    ess10.imm_worse_better,
    census_2021_joined.imm_share_1,
    census_2021_joined.imm_share_2,
    census_2021_joined.imm_share_3
  FROM ess10
  LEFT JOIN census_2021_joined ON ess10.nuts_id = census_2021_joined.nuts_id"
)

# ---- Row-wise concatenate datasets for final analysis dataset

db_execute(
  "CREATE TABLE analysis_dataset_sql AS
  SELECT * FROM ess6_prefinal
  UNION ALL
  SELECT * FROM ess10_prefinal"
)

db_query("SELECT * FROM analysis_dataset_sql LIMIT 200")
