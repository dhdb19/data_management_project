library("tidyverse")
library("RPostgres")
library("DBI")
library("sf")
library("arrow")
library("geoarrow")
library("sfarrow")
library("purrr")

# ---- Helpful objects

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






# ---- Load and prepare the EUROSTAT 2021 census data (1km × 1km grid)

estat <- st_read_parquet("data/ESTAT_Census_2021_V2.parquet") %>%
  st_set_crs(3035) %>%
  rename_with(tolower) %>%
  rename(
    total_pop = t,
    nat_pop = nat,
    recentimm_pop = chg_out
  ) %>%
  select(!c(ends_with("ci"))) %>%
  select(
    geom,
    nat_pop,
    total_pop,
    recentimm_pop,
  ) %>%
  filter(
    nat_pop >= 0,
    total_pop >= 0,
    recentimm_pop >= 0
  )


# ---- Load and prepare the NUTS dataset

nuts <- st_read("data/NUTS_RG_60M_2021_3035.gpkg", crs = 3035) %>%
  rename_with(tolower) %>%
  rename(
    nuts_level = levl_code
  ) %>%
  filter(
    cntr_code %in% eustat_iso
  ) %>%
  select(nuts_id, nuts_level, geom)

countries <- nuts %>%
  as.data.frame() %>%
  select(nuts_id) %>%
  filter(nchar(nuts_id) == 2) %>%
  pull()

# ---- Spatially join 2021 census data (grid-level) with NUTS dataset to get NUTS level population statistics, i.e. share of immigrant population

# Convert NUTS polygons to centroid for efficiency ! This takes a long time !

estat_points <- st_centroid(estat)


# Spatial join ! This takes a long time !

census_2021_joined <- st_join(estat_points, nuts)


# Calculate local share of immigrant population, using self-joins to establish hierachical data.
# Unit of observation is the "NUTS region" - "local immigrant share of the population" at all NUTS levels
# Observations also contain the "local immigrant share of the population" observation for all greater NUTS levels.
# I.e. an observation at NUTS 3 level, also contains the observation for the larger level 2 and leve 1 region it is contained within.

census_2021_self <- census_2021_joined %>%
  as.data.frame() %>%
  select(!geom) %>%
  group_by(nuts_id, nuts_level) %>%
  summarize(
    imm_share = 1 - (sum(nat_pop) / sum(total_pop))
  ) %>%
  drop_na() %>%
  mutate(
    nuts1 = case_when(
      nuts_level > 0 ~ substr(nuts_id, 1, 3),
      .default = NA
    ),
    nuts2 = case_when(
      nuts_level > 1 ~ substr(nuts_id, 1, 4),
      .default = NA
    ),
    nuts3 = case_when(
      nuts_level > 2 ~ substr(nuts_id, 1, 5),
      .default = NA
    )
  )


census_2021 <- census_2021_self %>%
  left_join(
    census_2021_self %>% select(
      imm_share_1 = imm_share, nuts_id
    ),
    by = join_by(nuts1 == nuts_id)
  ) %>%
  left_join(
    census_2021_self %>% select(
      imm_share_2 = imm_share, nuts_id
    ),
    by = join_by(nuts2 == nuts_id)
  ) %>%
  left_join(
    census_2021_self %>% select(
      imm_share_3 = imm_share, nuts_id
    ),
    by = join_by(nuts3 == nuts_id)
  )



# ---- Load and prepare 2011 census data
# Follows roughly same steps as preparation of 2021 data, but 2011 data was available precompiled at the NUTS 3 level

census_2011_self <- read_csv("data/census_2011.csv") %>%
  select(GEO, POB, VALUE) %>%
  pivot_wider(names_from = POB, values_from = VALUE) %>%
  rename(
    imm = FOR,
    nuts_id = GEO
  ) %>%
  rename_with(tolower) %>%
  mutate(
    total = as.numeric(nat) + as.numeric(imm) + as.numeric(oth) + as.numeric(unk),
    imm_share = as.numeric(imm) / total,
    nuts_level = case_when(
      nchar(nuts_id) == 2 ~ 0,
      nchar(nuts_id) == 3 ~ 1,
      nchar(nuts_id) == 4 ~ 2,
      nchar(nuts_id) == 5 ~ 3,
    ),
    nuts1 = case_when(
      nchar(nuts_id) > 2 ~ substr(nuts_id, 1, 3),
      .default = NA
    ),
    nuts2 = case_when(
      nchar(nuts_id) > 3 ~ substr(nuts_id, 1, 4),
      .default = NA
    ),
    nuts3 = case_when(
      nchar(nuts_id) > 4 ~ substr(nuts_id, 1, 5),
      .default = NA
    )
  )

census_2011 <- census_2011_self %>%
  left_join(
    census_2011_self %>% select(imm_share_2 = imm_share, nuts_id),
    by = join_by(nuts2 == nuts_id)
  ) %>%
  left_join(
    census_2011_self %>% select(imm_share_1 = imm_share, nuts_id),
    by = join_by(nuts1 == nuts_id)
  ) %>%
  left_join(
    census_2011_self %>% select(imm_share_3 = imm_share, nuts_id),
    by = join_by(nuts3 == nuts_id)
  ) %>%
  select(nuts_id, nuts_level, imm_share, imm_share_1, imm_share_2, imm_share_3)



# ---- Load and prepare ESS6 data

ess6 <- read_csv("data/ess6.csv") %>%
  rename(
    ess_round = essround,
    nuts_id = region,
    nuts_level = regunit,
    imm_allow_same = imsmetn,
    imm_allow_different = imdfetn,
    imm_allow_poor = impcntr,
    imm_economy = imbgeco,
    imm_culture = imueclt,
    imm_worse_better = imwbcnt
  ) %>%
  filter(str_starts(nuts_id, str_c(countries, collapse = "|"))) %>%
  mutate(
    imm_allow_same = case_when(
      !imm_allow_same %in% seq(1:4) ~ NA,
      .default = imm_allow_same
    ),
    imm_allow_different = case_when(
      !imm_allow_different %in% seq(1:4) ~ NA,
      .default = imm_allow_different
    ),
    imm_allow_poor = case_when(
      !imm_allow_poor %in% seq(1:4) ~ NA,
      .default = imm_allow_poor
    ),
    imm_economy = case_when(
      !imm_economy %in% seq(0:10) ~ NA,
      .default = imm_economy
    ),
    imm_culture = case_when(
      !imm_culture %in% seq(0:10) ~ NA,
      .default = imm_culture
    ),
    imm_worse_better = case_when(
      !imm_worse_better %in% seq(0:10) ~ NA,
      .default = imm_worse_better
    ),
  ) %>%
  left_join(
    census_2011,
    by = join_by(nuts_id == nuts_id)
  ) %>%
  select(
    ess_round,
    nuts_id,
    # nuts_level,
    imm_share_1,
    imm_share_2,
    imm_share_3,
    imm_allow_same,
    imm_allow_different,
    imm_allow_poor,
    imm_economy,
    imm_culture,
    imm_worse_better
  )



# ---- Load and prepare ESS10 data

ess10 <- read_csv("data/ess10.csv") %>%
  rename(
    ess_round = essround,
    nuts_id = region,
    nuts_level = regunit,
    imm_allow_same = imsmetn,
    imm_allow_different = imdfetn,
    imm_allow_poor = impcntr,
    imm_economy = imbgeco,
    imm_culture = imueclt,
    imm_worse_better = imwbcnt
  ) %>%
  filter(str_starts(nuts_id, str_c(countries, collapse = "|"))) %>%
  mutate(
    nuts_level = case_when(
      nuts_level == 1 | name == "ESS10SCe03_1" & nchar(nuts_id) == 3 ~ 1,
      nuts_level == 2 | name == "ESS10SCe03_1" & nchar(nuts_id) == 4 ~ 2,
      nuts_level == 3 | name == "ESS10SCe03_1" & nchar(nuts_id) == 5 ~ 3,
    ),
    imm_allow_same = case_when(
      !imm_allow_same %in% seq(1:4) ~ NA,
      .default = imm_allow_same
    ),
    imm_allow_different = case_when(
      !imm_allow_different %in% seq(1:4) ~ NA,
      .default = imm_allow_different
    ),
    imm_allow_poor = case_when(
      !imm_allow_poor %in% seq(1:4) ~ NA,
      .default = imm_allow_poor
    ),
    imm_economy = case_when(
      !imm_economy %in% seq(0:10) ~ NA,
      .default = imm_economy
    ),
    imm_culture = case_when(
      !imm_culture %in% seq(0:10) ~ NA,
      .default = imm_culture
    ),
    imm_worse_better = case_when(
      !imm_worse_better %in% seq(0:10) ~ NA,
      .default = imm_worse_better
    ),
  ) %>%
  left_join(
    census_2021,
    by = join_by(nuts_id == nuts_id)
  ) %>%
  select(
    ess_round,
    nuts_id,
    # imm_share,
    # nuts_level,
    imm_share_1,
    imm_share_2,
    imm_share_3,
    imm_allow_same,
    imm_allow_different,
    imm_allow_poor,
    imm_economy,
    imm_culture,
    imm_worse_better
  )


# ---- Concatenate datasets to create final analysis dataset
analysis_dataset_r <- bind_rows(
  ess6,
  ess10
)
