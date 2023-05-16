#### The kids are not ok ####
# RWM April 14th 2023
# 
library(tidyverse)
library(mgcv)

`%notin%` <- Negate(`%in%`)

home <- "~/Dropbox (Sydney Uni)/the-kids-are-alright/"  

hilda.data <- read_rds("data/preprocessed.RDS") %>% 
  select(xwaveid, year, sex, age, ghmh, pdk10s, topup) %>%
  filter(!is.na(ghmh)) %>%
  mutate(
    age_group = case_when(
      age <= 14 ~ "0-14",  # there is n = 1 fourteen year old
      age <= 24 ~ "15-24", 
      age <= 34 ~ "25-34",
      age <= 44 ~ "35-44",
      age <= 54 ~ "45-54",
      age <= 65 ~ "55-64",
      age <= 75 ~ "65-74",
      age <= 85 ~ "75-84",
      TRUE      ~ "85+"),
    birthyear = year - age,
    cohort = case_when(
      birthyear %in% 1900:1929 ~ "1920s",
      birthyear %in% 1930:1939 ~ "1930s", 
      birthyear %in% 1940:1949 ~ "1940s",
      birthyear %in% 1950:1959 ~ "1950s",
      birthyear %in% 1960:1969 ~ "1960s",
      birthyear %in% 1970:1979 ~ "1970s",
      birthyear %in% 1980:1989 ~ "1980s",
      birthyear %in% 1990:1999 ~ "1990s",
      birthyear %in% 2000:2009 ~ "2000s", 
      birthyear %in% 2010:2020 ~ "2010s", 
      TRUE ~ "problem"
    )) %>%
  mutate(xwaveid = factor(xwaveid),
         ocohort = ordered(cohort),
         fcohort = factor(cohort))

# Quick example
hilda.data %>%
  filter(cohort %in% c("1990s", "1980s")) %>%
  mutate(xwaveid = factor(xwaveid)) %>% 
  gamm(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    correlation=corAR1(form=~1|xwaveid),
    method = "REML",
    data = .
  ) -> fit

plot(fit$gam, shade=T, pages=1)


#### Fit and save difference smooths #####
difference_gam <- function(.dat, cohorts) {
  
  cohorts <- sort(cohorts)
  
  .dat %>%
    filter(cohort %in% cohorts) %>%
    droplevels() %>%
    gamm(
      formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
      method = "REML",
      correlation = corAR1(form=~1|xwaveid),
      data = .
    ) 
}

difference_gam(hilda.data, c("1990s", "1980s")) %>%
  write_rds("results/gam_90v80.rds")

difference_gam(hilda.data, c("1980s", "1970s")) %>%
  write_rds("results/gam_80v70.rds")

difference_gam(hilda.data, c("1970s", "1960s")) %>%
  write_rds("results/gam_70v60.rds")

difference_gam(hilda.data, c("1960s", "1950s")) %>%
  write_rds("results/gam_60v50.rds")

difference_gam(hilda.data, c("1950s", "1940s")) %>%
  write_rds("results/gam_50v40.rds")

# Adding the linear effect of year changes the smooth trends for each cohort, 
# but not the smooth differences

difference_gam_p <- function(.dat, cohorts) {
  
  cohorts <- sort(cohorts)
  
  .dat %>%
    filter(cohort %in% cohorts) %>%
    droplevels() %>%
    gamm(
      formula = ghmh ~ cohort + s(age) + s(age, by = ocohort) + year,
      method = "REML",
      correlation = corAR1(form=~1|xwaveid),
      data = .
    ) 
}

difference_gam_p(hilda.data, c("1990s", "1980s")) %>%
  write_rds("results/linear_period/gam_90v80.rds")

difference_gam_p(hilda.data, c("1980s", "1970s")) %>%
  write_rds("results/linear_period/gam_80v70.rds")

difference_gam_p(hilda.data, c("1970s", "1960s")) %>%
  write_rds("results/linear_period/gam_70v60.rds")

difference_gam_p(hilda.data, c("1960s", "1950s")) %>%
  write_rds("results/linear_period/gam_60v50.rds")

difference_gam_p(hilda.data, c("1950s", "1940s")) %>%
  write_rds("results/linear_period/gam_50v40.rds")


# Note that adding the main/marginal/average (smooth) effect of year by:
# ghmh ~ cohort + s(age) + s(age, by = ocohort) + s(year)
# removes the cohort effect _because_ the cohort effect produces the decline we 
# see over years.

hilda.data %>%
  filter(cohort %in% c("1980s", "1970s")) %>%
  mutate(xwaveid = factor(xwaveid)) %>% 
  gamm(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort) + s(year),
    correlation=corAR1(form=~1|xwaveid),
    method = "REML",
    data = .
  ) -> fit2

plot(fit2$gam, shade=T, pages=1)

# However we can center age in each cohort and estimate the cohort effect with 
# the smooth effect of year in the model: 
fit <- hilda.data %>% 
  filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
  group_by(cohort) %>%
  mutate(age = c(scale(age, center = T, scale = F))) %>% 
  ungroup() %>%
  gam(
    formula = ghmh ~ fcohort + s(age, by = fcohort) + s(year),
    data = .
  ) 

write_rds(fit, "results/full_fit_w_period.rds")
# Recovering the original age values and plotting the difference smooths is done
# in PNAS_SI.Rmd





#### smooth main effects ####
#
# Below estimates the smooth differences from the main effect of age. However it 
# uses the entire range of age and the confidence/credible intervals tend to 
# blow-out due to uncertainty where the sample thins (e.g., <30yo or >50yo).
szfit <- hilda.data %>%
  filter(cohort %in% c("1990s", "1980s", "1970s", "1960s", "1950s", "1940s")) %>%
  gam(
    formula = ghmh ~ s(age) + s(fcohort, age, bs="sz", id=1),
    method = "REML",
    data = .
  )

plot(szfit, shade=T, pages=1)


#### examples from Simon Wood ####
dat <- dat %>%
  mutate(nfac = fct_rev(fac),
         onfac = ordered(nfac)) 

by1 <- gam(y ~ s(x2, by = nfac),
          data=dat,
          method="REML")
plot(by1, pages=1, main = "y ~ s(x2, by = nfac)")
summary(by1)

by2 <- gam(y ~ fac + s(x2, by = nfac),
           data=dat,
           method="REML")
plot(by2, pages=1, main = "y ~ fac + s(x2, by = nfac)")
summary(by2)

by3 <- gam(y ~ nfac + s(x2) + s(x2, by = nfac),
           data=dat,
           method="REML")
plot(by3, pages=1, main="y ~ nfac + s(x2) + s(x2, by = nfac)")
summary(by3)

by4 <- gam(y ~ nfac + s(x2) + s(x2, by = onfac),
           data=dat,
           method="REML")
plot(by4, pages=1, main = "y ~ nfac + s(x2) + s(x2, by = onfac)")
summary(by4)


by5 <- gam(y ~ nfac + s(x2) + s(nfac, x2, bs="sz"),
         data=dat,
         method="REML")
plot(by5, pages=1, main = "y ~ nfac + s(x2) + s(nfac, x2, bs='sz')")
summary(by5)

by6 <- gam(y ~ s(x2) + s(x2, nfac, bs="sz", id=1),
           data=dat,
           method="REML")
plot(by6, pages=1, main = "y ~ s(x2) + s(x2, nfac, bs='sz', id=1)")
summary(by6)


