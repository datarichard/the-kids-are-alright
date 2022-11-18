#### Modern Work ####
# For Blackdog Institute collaboration paper
# RW Morris
# 
# Preprocessing 
# Oct 12th 2022
# 
#### Setup ####
library(tidyverse)
library(haven)
setwd("~/Dropbox (Sydney Uni)/HILDA/the-kids-are-alright/src")

#### Import data ####
path_to_hilda <- list.files(
  path = '~/Dropbox (Sydney Uni)/HILDA/data',
  pattern = '^Combined.*.dta$',
  full.names = TRUE
)

hilda <- list()
for (pathtofile in path_to_hilda) {
  df <- read_dta(pathtofile)
  hilda <- append(hilda, list(df))
  cat('.')
}

# Helper functions
source('~/Dropbox (Sydney Uni)/HILDA/src/gather_hilda.R')

extract_numeric <- function (x) {
  as.numeric(gsub("[^0-9.-]+", "", as.character(x)))
}

`%notin%` <- Negate(`%in%`)



#### Life satisfaction ####
satisfaction <- gather_hilda(hilda, c("losat", "losateo", "losatfs",
                                   "losatft", "losathl", "losatlc", "losatnl",
                                   "losatsf", "losatyh")) %>%
  spread(code, val) %>%
  mutate_if(is.double, ~ ifelse(. < 0, NA_real_, .))



#### Wellbeing ####
mhi5 <- gather_hilda(hilda, "ghmh") %>%
  spread(code, val) %>%
  mutate_if(is.double, ~ ifelse(. < 0, NA_real_, .))

k10 <- gather_hilda(hilda, c("pdk10s", "pdk10rc")) %>%
  spread(code, val) %>%
  mutate_if(is.double, ~ ifelse(. < 0, NA_real_, .))

#### Demographics ####
state_key = c(`1` = "NSW", `2` = "VIC", `3` = "QLD", `4` = "SA", `5` = "WA", 
              `6` = "TAS", `7` = "NT", `8` = "ACT")

region_key = c(`0` = "capital", `1` = "urban", `2` = "regional", `3` = "rural")

key_esbrd = c(`1` = "employed", `2` = "unemployed", `3` = "not in labour force")

demographic_items <- gather_hilda(hilda, c(
  "hhda10",  # SEIFA 2001 Decile of socio-economic advantage (higher is better)
  "hgage",   # age
  "hgsex",   # sex (male = 1)
  "helth",   # long term health condition (yes = 1)
  "mrcurr",  # current marital status (married/de facto ≤ 2)
  "edhigh1", # highest education achieved
  "edfts",   # current fulltime student (yes = 1)
  "esbrd",   # "employed", "unemployed", "not in labour force"
  "hhtup",   # Wave 11 top-up person
  "hhstate", # household State of residence (NSW, VIC, QLD, SA, WA, TAS, NT, ACT)
  "hhssos",  # household section of State (major urban, other urban, boundary, rural)
  "hhwte"    # enumarated persons cross-sectional weight (sex, broad age, region
             # employment, marital status)
  )) %>%
  spread(code, val) %>%
  mutate_if(is.double, ~ ifelse(. < 0, NA_real_, .)) %>%
  mutate(hhssos = replace_na(hhssos, 3),
         hhssos = recode(hhssos, !!!region_key),
         hhstate = recode(hhstate, !!!state_key),
         esbrd = recode(esbrd, !!!key_esbrd)
  ) 

demographics <- demographic_items %>%
  transmute(
    wave,
    xwaveid,
    sex = if_else(hgsex == 1, "Male", "Female"),
    age = as.numeric(hgage),
    employment = esbrd,
    student = if_else(edfts == 1 | age <= 17, TRUE, FALSE, missing = FALSE),
    edu = case_when( 
      edhigh1 == 10 ~ NA_character_,           # recode undetermined 
      edhigh1 == 1 ~  "Grad",                  # PhD
      edhigh1 == 2 ~  "Grad",                  # Grad diploma
      edhigh1 == 3 ~  "Grad",                  # Bachelors
      edhigh1 == 4 ~  "Highschool",            # Diploma
      edhigh1 == 5 ~  "Highschool",            # Certificate
      edhigh1 == 8 ~  "Highschool",            # Year 12
      edhigh1 == 9 ~  "None",                  # Year 11 or less
      age <= 17 ~  "In school",
      edhigh1 < 0 ~   NA_character_            # recode missing values
    ),
    edu = ordered(edu, levels = c("None", 
                                  "In school", 
                                  "Highschool", 
                                  "Grad")),
    chronic = if_else(helth == 1, TRUE, FALSE, missing = FALSE),
    relationship = case_when(
      mrcurr == 6 ~ "single",
      mrcurr <= 2 ~ "married/de facto",
      mrcurr <= 5 ~ "separated/divorced/widowed",
      TRUE ~ "(missing)"),
    SEIFA = as.integer(extract_numeric(hhda10)),
    region = paste(hhstate, hhssos, sep = "_"),
    topup = hhtup %in% 1,
    weights = hhwte
  )

#### Final join ####
left_join(mhi5, demographics) %>%
  left_join(satisfaction) %>%
  left_join(k10) %>%
  group_by(wave) %>%
  mutate(year = which(letters == wave[1]) + 2000) %>%
  ungroup() -> df

write_rds(df, "data/preprocessed.RDS")
