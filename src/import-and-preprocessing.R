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

#### Employment variables ####
# Job variables
# Causal job status
# There are multiple variables indicating casual job status.

"esdtl"
# Detailed current labour force status: 1 Employed FT; 2 Employed PT; 
# 3 Unemployed, looking for FT work; 4 Unemployed, looking for PT work; 5 Not in
# the labour force, marginally attached; 6 Not in the labour force, not 
# marginally attached; 7 Employed, but usual hours worked unknown 

"jbmcnt"
# Looking at SHOWCARD C23, which of these categories best describes your current
# contract of employment?  Employed on a fixed-term contract, Employed on a 
# casual basis, Employed on a permanent or ongoing basis, Other

"jbcasab" 
# Casual worker (ABS definition: no paid holiday leave, no paid sick leave)
# Split data into casual vs permanent, then show split of casual into the three 
# age groups

"jbmlh"
# Employed through labour-hire firm or temporary employment agency
# 

"esempst"
# Self-employed is not indicated in ESDTL, but is indicated in ESEMPST and ESEMPDT

key_esbrd = c(`1` = "employed", `2` = "unemployed", `3` = "not in labour force")
key_esdtl = c(`1` = "full-time", `2` = "part-time", `3` = "unemployed (FT)", 
              `4` = "unemployed (PT)", `5` = "marginal workforce", 
              `6` = "not in workforce", `7` = "employed unknown")
key_jbmcnt = c(`1` = "fixed-term", `2` = "casual", `3` = "permanent", `8` = "other")
key_jbcasab = c(`1` = "casual", `2` = "permanent")
key_jbmlh = c(`1` = "Employed by labour hire firm", 
              `2` = "Not employed by labour hire firm")
key_esempst = c(`1` = "employee", `2` = "own business", `3` = "self-employed", 
                `4` = "family-worker")

employment <- gather_hilda(hilda, 
  c("esbrd", "esdtl", "jbcasab", "jbmcnt", "jbmlh", "esempst")) %>%
  spread(code, val) %>%
  mutate_if(is.double, ~ ifelse(. < 0, NA_real_, .)) %>% 
  # filter(esbrd %in% 1:2) %>% 
  mutate(
    esbrd = recode(esbrd, !!!key_esbrd),
    esdtl = recode(esdtl, !!!key_esdtl),
    jbmcnt = recode(jbmcnt, !!!key_jbmcnt),
    jbcasab = recode(jbcasab, !!!key_jbcasab),
    jbmlh = recode(jbmlh, !!!key_jbmlh),
    esempst = recode(esempst, !!!key_esempst)
  ) 

# Job security
job_security <- c(
  "jomsf",   # I have a secure future in my job [1:7, all waves]
  "jomwf",   # I worry about the future of my job [1:7, all waves]
  "jompf",   # I get paid fairly for the things I do in my job
  "jomcsb",  # Company I work for will still be in business in 5 years
  "jbmploj", # Percent chance of losing job in the next 12 months [0:100, all waves]
  "jbmpgj"	 # Percent chance will find and accept job at least as good as current job
)

# Job control
job_control <- c(
  "jomfd",  # I have a lot of freedom to decide how I DO my job 
  "jomfw",  # I have a lot of freedom to decide WHEN I do my work (not needed)
  "jomls",  # I have a lot of say about what happens in my job
  "jomflex" # My working times can be flexible
)

# Job demands
job_demands <- c(
  "jomcd",   # My job is complex and difficult 
  "jomms",   # My job is more stressful than I had ever imagined	
  "jompi",   # I fear that the amount of stress in my job will make me physically ill
  "jomns",   # My job often required me to learn new skills
  "jomus",   # I use my skills in current job
  "lsemp",   # Combined hrs/mins per week - Paid employment [waves 2:16, all pop]
  "jbhruc",  # Hours per week usually worked in all jobs
  "jbmhruc", # Hours per week usually worked in main job
  "jbhrqf"   # Data Quality Flag: hours of work main job vs all jobs
)

job_items <- gather_hilda(hilda, c(job_security, job_control, job_demands)) %>%
  spread(code, val) %>%
  mutate_if(is.double, ~ ifelse(. < 0, NA_real_, .)) %>%
  # to do: remove jbmpgj = 997, 999 values, try the following:
  mutate(across(c(jbmploj, jbmpgj), ~replace(., . %in% c(997, 998, 999), NA)))


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



#### Demographics ####
state_key = c(`1` = "NSW", `2` = "VIC", `3` = "QLD", `4` = "SA", `5` = "WA", 
              `6` = "TAS", `7` = "NT", `8` = "ACT")

region_key = c(`0` = "capital", `1` = "urban", `2` = "regional", `3` = "rural")

demographic_items <- gather_hilda(hilda, c(
  "hhda10",  # SEIFA 2001 Decile of socio-economic advantage (higher is better)
  "hgage",   # age
  "hgsex",   # sex (male = 1)
  "helth",   # long term health condition (yes = 1)
  "mrcurr",  # current marital status (married/de facto ≤ 2)
  "edhigh1", # highest education achieved
  "edfts",   # current fulltime student (yes = 1)
  "hhstate", # household State of residence (NSW, VIC, QLD, SA, WA, TAS, NT, ACT)
  "hhssos",  # household section of State (major urban, other urban, boundary, rural)
  "hhwte"    # enumarated persons cross-sectional weight (sex, broad age, region
             # employment, marital status)
  )) %>%
  spread(code, val) %>%
  mutate_if(is.double, ~ ifelse(. < 0, NA_real_, .)) %>%
  mutate(hhssos = replace_na(hhssos, 3),
         hhssos = recode(hhssos, !!!region_key),
         hhstate = recode(hhstate, !!!state_key)
  ) 

demographics <- demographic_items %>%
  transmute(
    wave,
    xwaveid,
    sex = if_else(hgsex == 1, "Male", "Female"),
    age = as.numeric(hgage),
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
    weights = hhwte
  )

#### Final join ####
left_join(employment, job_items) %>%
  left_join(satisfaction) %>%
  left_join(mhi5) %>%
  left_join(demographics) %>% 
  group_by(wave) %>%
  mutate(year = which(letters == wave[1]) + 2000) %>%
  ungroup() -> df

write_rds(df, "../data/preprocessed.RDS")
