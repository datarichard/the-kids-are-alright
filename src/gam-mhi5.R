#### The kids are not ok ####
library(tidyverse)
library(patchwork)
library(ggthemes)

`%notin%` <- Negate(`%in%`)

home <- "~/Dropbox (Sydney Uni)/the-kids-are-alright/"  

hilda <- read_rds(paste0(home, "data/preprocessed.RDS")) 

hilda.data <- hilda %>%
  select(xwaveid, year, ghmh, losat, age, lsemp, losat, losateo, losatfs, 
         losatft, losathl, losatlc, losatnl, losatsf, losatyh) %>%
  mutate(
    age_group = case_when(
      age <= 14 ~ "0-14",
      age <= 24 ~ "15-24", # there is n = 1 fourteen year old
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
  filter(!is.na(ghmh) | !is.na(losat))

hilda.data <- hilda.data %>%
  # filter(age_group %notin% c("0-14", "75-84", "85+")) %>%
  # filter(cohort %notin% c("1920s", "1930s", "2000s")) %>%
  mutate(ocohort = ordered(cohort),
         fcohort = factor(cohort))

count(hilda.data, ocohort)
# A tibble: 6 × 2
#   cohort      n
# 1 1940s   31844
# 2 1950s   46054
# 3 1960s   53440
# 4 1970s   48246
# 5 1980s   52962
# 6 1990s   35846


#### Estimate cohort smooths #####
library(mgcv)

# overall age smooth
fit <- gam(
  formula = ghmh ~ s(age),
  data = hilda.data
)

plot(fit)

# age smooth by all cohorts
fit <- gam(
  formula = ghmh ~ fcohort + s(age) + s(age, by = fcohort),
  # method = "REML",
  data = hilda.data
)

plot(fit, shade=T, pages=1)

difference_gam <- function(.dat, cohorts) {
  
  cohorts <- sort(cohorts)
  
  .dat %>%
    filter(cohort %in% cohorts) %>%
    mutate(ocohort = ordered(cohort)) %>%
    gam(
      formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
      method = "REML",
      data = .
    ) -> fit
  
  plot_obj <- plot(fit, seWithMean = T)
  # seWithMean = T for confidence intervals that include the uncertainty about
  # the overall mean as well as the centred smooth itself. This results in inter-
  # vals with close to nominal (frequentist) coverage probabilities (Marra & 
  # Woods, 2012).
  
  bind_rows(
    
    as.data.frame(plot_obj[[1]][c("x", "se", "fit")]) %>%
      mutate(cohort = paste(cohorts[1], "smooth")),
    
    as.data.frame(plot_obj[[2]][c("x", "se", "fit")]) %>%
      mutate(cohort = paste(cohorts[2], "difference"))
  )
  
}

p1 <- difference_gam(hilda.data, c("1990s", "1980s")) %>% 
  ggplot(aes(x = x, y = fit)) +
  geom_hline(aes(yintercept=0), linetype = "dotted") + 
  geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
              fill = "grey80") +
  geom_line() +
  facet_wrap(~cohort) +
  labs(x = "Age", y = "centred estimate") +
  theme_minimal()

p2 <- difference_gam(hilda.data, c("1980s", "1970s")) %>% 
  ggplot(aes(x = x, y = fit)) +
  geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
              alpha = 0.3) +
  geom_line() +
  facet_wrap(~cohort) +
  labs(x = "Age", y = "centred estimate") +
  theme_minimal()

p3 <- difference_gam(hilda.data, c("1970s", "1960s")) %>% 
  ggplot(aes(x = x, y = fit)) +
  geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
              alpha = 0.3) +
  geom_line() +
  facet_wrap(~cohort) +
  labs(x = "Age", y = "centred estimate") +
  theme_minimal()

p4 <- difference_gam(hilda.data, c("1960s", "1950s")) %>% 
  ggplot(aes(x = x, y = fit)) +
  geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
              alpha = 0.3) +
  geom_line() +
  facet_wrap(~cohort) +
  labs(x = "Age", y = "centred estimate") +
  theme_minimal()

p5 <- difference_gam(hilda.data, c("1950s", "1940s")) %>% 
  ggplot(aes(x = x, y = fit)) +
  geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
              alpha = 0.3) +
  geom_line() +
  facet_wrap(~cohort) +
  labs(x = "Age", y = "centred estimate") +
  theme_minimal()

p1 / p2 / p3 / p4 / p5

#### Adjust for dependency ####
hilda.data %>%
  filter(cohort %in% c("1990s", "1980s")) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    method = "REML",
    data = .
  ) -> fit

summary(fit)
plot(fit, shade=T, pages=1)


hilda.data %>%
  filter(cohort %in% c("1990s", "1980s")) %>%
  mutate(xwaveid = factor(xwaveid)) %>% 
  gamm(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    correlation=corAR1(form=~1|xwaveid),
    method = "REML",
    data = .
  ) -> fit2

summary(fit2$gam)
plot(fit2$gam, shade=T, pages=1)



# age smooth by 2 cohorts
hilda.data %>%
  filter(cohort %in% c("1990s", "1980s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)

plot1990 <- plot(fit, seWithMean = T)

str(plot1990)

smooth.df <- bind_rows(
  
  as.data.frame(plot1990[[1]][c("x", "se", "fit")]) %>%
    mutate(cohort = "1980s smooth"),
  
  as.data.frame(plot1990[[2]][c("x", "se", "fit")]) %>%
    mutate(cohort = "1990s difference")
  )

ggplot(smooth.df, aes(x = x, y = fit)) +
  geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
              alpha = 0.3, ) +
  geom_line() +
  facet_wrap(~cohort) +
  labs(x = "Age", y = "centred estimate") +
  theme_minimal()






hilda.data %>%
  filter(cohort %in% c("1980s", "1970s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)

hilda.data %>%
  filter(cohort %in% c("1970s", "1960s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)

hilda.data %>%
  filter(cohort %in% c("1960s", "1950s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)

hilda.data %>%
  filter(cohort %in% c("1950s", "1940s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)


# age smooth by 3 cohorts
hilda.data %>%
  filter(cohort %in% c("1990s", "1980s", "1970s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)

hilda.data %>%
  filter(cohort %in% c("1980s", "1970s", "1960s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    # method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)

hilda.data %>%
  filter(cohort %in% c("1970s", "1960s", "1950s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    # method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)


hilda.data %>%
  filter(cohort %in% c("1960s", "1950s", "1940s")) %>%
  mutate(ocohort = ordered(cohort)) %>%
  gam(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    # method = "REML",
    data = .
  ) -> fit

plot(fit, shade=T, pages=1)




