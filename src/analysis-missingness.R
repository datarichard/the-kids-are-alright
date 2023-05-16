#### Missingness analysis ####
# For PNAS submission
# RW Morris
# 
# May 1st 2023
# 
# Does missingness occur at random or is it related to the outcome or predictor
# variables?
# 
# What matters is not the extent of the attrition, but whether it is 'ignorable'
# for the effects you wish to estimate. If the probability of attrition from the
# panel varies with the experience of mental health, it would not be ignorable. 
# For instance, people experiencing mental health problems may be more likely to
# leave the panel. In that case, there would be biases in the age profiles, 
# which are likely to also affect estimates of cohort and period effects.  
# 
# MCAR = missing completely at random (not data dependent)
# MAR = missing at random means y is missing depends on observed data
# MNAR = missing not at random means y is missing depends on y (unseen data 
# dependent)
# 
# Overview:
# https://www.sciencedirect.com/topics/mathematics/missingness
# 
#### Setup ####
library(tidyverse)
library(lme4)
library(broom)
library(broom.mixed)
library(emmeans)
library(ggeffects)
library(patchwork)

# Helper functions
source('~/Documents/R/helpers.r')

#### Import ####
hilda.data <- read_rds("data/preprocessed.RDS") %>% 
  select(xwaveid, year, sex, age, ghmh) %>%
  # filter(ghmh > 0) %>% # option for main analysis
  mutate(
    age_group = case_when(
      age <= 14 ~ "0-14",  
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
         fcohort = factor(cohort)) %>%
  group_by(xwaveid) %>%
  mutate(any_missing = any(ghmh < 0),
         all_missing = all(ghmh < 0),
         end_missing = last(ghmh < 0, order_by = year)) %>%
  ungroup()

hilda.data %>%
  filter(!all_missing) %>%
  filter(ghmh < 0) %>%
  count(ghmh)
# A tibble: 4 × 2
#   ghmh     n
#    -10 47090 = Non-responding person
#     -8 27282 = Missing SCQ
#     -5     2 = Multiple response
#     -4  1619 = Refused/not stated

hilda.data %>%
  filter(all_missing) %>%
  count(ghmh)
# A tibble: 3 × 2
#   ghmh     n
#    -10 58425 = Non-responding person
#     -8  2923 = Missing SCQ
#     -4    95 = Refused/not stated

hilda.data %>%
  filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
  filter(!all_missing) %>%
  filter(ghmh < 0) %>%
  count(ghmh)

# A tibble: 3 × 2 (compare to above)
# ghmh     n
#   -8 24502
#   -5     1
#   -4  1103
#   
# Missingness (non-responding persons) is removed by conditioning on cohort here
# and I'm not sure why...
# 
#### Plot ####
plot.data <- hilda.data %>%
  filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
  filter(ghmh > 0) # pairwise deletion

ylims = c(65, 80)

p1 <- ggplot(plot.data, aes(x = age, y = ghmh)) +
  geom_smooth(aes(group = 1), 
              method = "gam", formula = y ~ s(x, bs = "cs"), 
              se=F, color = "black", size = .5, linetype = "dashed") +
  geom_smooth(aes(group = cohort, color = cohort), 
              method = "gam", formula = y ~ s(x, bs = "cs"), 
              se=F, alpha = 0.2) +
  labs(
    subtitle = "Smoothed MHI-5 scores 0-100 (by cohort)", 
    y = "", x = "\n Age (years)", caption = "any missing") +
  coord_cartesian(ylim = ylims) +
  scale_color_manual(values = blues9[3:9]) +
  guides(color = guide_legend(title = "Birth cohort")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"),
        legend.title = element_text(size = 10),
        legend.position = c(0.85, 0.25),
        axis.title.x = element_text(size = 10))


p2 <- ggplot(filter(plot.data, !end_missing), aes(x = age, y = ghmh)) +
  geom_smooth(aes(group = 1), 
              method = "gam", formula = y ~ s(x, bs = "cs"), 
              se=F, color = "black", size = .5, linetype = "dashed") +
  geom_smooth(aes(group = cohort, color = cohort), 
              method = "gam", formula = y ~ s(x, bs = "cs"), 
              se=F, alpha = 0.2) +
  labs(
    subtitle = "Smoothed MHI-5 scores 0-100 (by cohort)", 
    y = "", x = "\n Age (years)", caption = "end missing") +
  coord_cartesian(ylim = ylims) +
  scale_color_manual(values = blues9[3:9]) +
  guides(color = guide_legend(title = "Birth cohort")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"),
        legend.title = element_text(size = 10),
        legend.position = c(0.85, 0.25),
        axis.title.x = element_text(size = 10))

p3 <- ggplot(filter(plot.data, !any_missing), aes(x = age, y = ghmh)) +
  geom_smooth(aes(group = 1), 
              method = "gam", formula = y ~ s(x, bs = "cs"), 
              se=F, color = "black", size = .5, linetype = "dashed") +
  geom_smooth(aes(group = cohort, color = cohort), 
              method = "gam", formula = y ~ s(x, bs = "cs"), 
              se=F, alpha = 0.2) +
  labs(
    subtitle = "Smoothed MHI-5 scores 0-100 (by cohort)", 
    y = "", x = "\n Age (years)", caption = "no missing") +
  coord_cartesian(ylim = ylims) +
  scale_color_manual(values = blues9[3:9]) +
  guides(color = guide_legend(title = "Birth cohort")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"),
        legend.title = element_text(size = 10),
        legend.position = c(0.85, 0.25),
        axis.title.x = element_text(size = 10))

p1 + p2 + p3

#### Total dependency ####
# these models do not center the ghmh variable by person, as we want to estimate
# the total dependency between ghmh and missingness rather than just the between
# or within dependency.

mf <- filter(hilda.data, !all_missing) %>% 
  filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
  # Create a missing flag
  mutate(missing = ghmh < 0) %>% 
  # Identify when the next year is missing for each person
  group_by(xwaveid) %>%
  mutate(missing_next = lead(missing, default = FALSE)) %>%
  ungroup() %>%
  # Remove the negative ghmh scores (i.e., missing scores) for everyone
  filter(ghmh > 0) %>%
  # Centre the remaining ghmh scores for each person so declines in ghmh predict
  # the next missing observation
  group_by(xwaveid) %>%
  mutate(cghmh = c(scale(ghmh, scale=F)),
         tghmh = if_else(ghmh < 52, "ill", "healthy")) %>%
  ungroup() %>%
  mutate(age.c = c(scale(age)),
         missing_next = as.factor(if_else(missing_next, "yes", "no")),
         wave = factor(year),
         tghmh = factor(tghmh))

# Null model
ghmh.0 <- glmer(
  formula = missing_next ~ 1 + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

ghmh.1 <- glmer(
  formula = missing_next ~ 1 + ghmh + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

# Mental health explains some of the missingness
anova(ghmh.0, ghmh.1)
# ghmh.0: missing_next ~ 1 + (1 | wave) + (1 | xwaveid)
# ghmh.1: missing_next ~ 1 + ghmh + (1 | wave) + (1 | xwaveid)
#        npar   AIC   BIC logLik deviance  Chisq Df Pr(>Chisq)    
# ghmh.0    3 93609 93641 -46802    93603                         
# ghmh.1    4 93448 93490 -46720    93440 163.14  1  < 2.2e-16 ***

ghmh.2 <- glmer(
  formula = missing_next ~ 1 + ghmh + cohort + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

ghmh.3 <- glmer(
  formula = missing_next ~ 1 + ghmh*cohort + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

# Mental health interacts with cohort
anova(ghmh.2, ghmh.3)
# ghmh.2: missing_next ~ 1 + ghmh + cohort + (1 | wave) + (1 | xwaveid)
# ghmh.3: missing_next ~ 1 + ghmh * cohort + (1 | wave) + (1 | xwaveid)
# npar   AIC   BIC logLik deviance  Chisq Df Pr(>Chisq)    
# ghmh.2    9 92470 92563 -46226    92452                         
# ghmh.3   14 92420 92565 -46196    92392 59.771  5  1.356e-11 ***

emtrends(ghmh.3, pairwise ~ cohort, var = "ghmh")

# $emtrends
# cohort ghmh.trend      SE  df asymp.LCL asymp.UCL
# 1940s    -0.01769 0.00197 Inf  -0.02154 -0.013837
# 1950s    -0.01599 0.00160 Inf  -0.01912 -0.012866
# 1960s    -0.00702 0.00137 Inf  -0.00970 -0.004331
# 1970s    -0.00549 0.00134 Inf  -0.00812 -0.002859
# 1980s    -0.00579 0.00118 Inf  -0.00810 -0.003480
# 1990s    -0.00228 0.00140 Inf  -0.00501  0.000461
# 
# Confidence level used: 0.95 
# 
# $contrasts
# contrast       estimate      SE  df z.ratio p.value
# 1940s - 1950s -0.001696 0.00253 Inf  -0.671  0.9851
# 1940s - 1960s -0.010674 0.00239 Inf  -4.462  0.0001
# 1940s - 1970s -0.012198 0.00238 Inf  -5.127  <.0001
# 1940s - 1980s -0.011900 0.00229 Inf  -5.194  <.0001
# 1940s - 1990s -0.015413 0.00241 Inf  -6.398  <.0001
# 1950s - 1960s -0.008977 0.00210 Inf  -4.272  0.0003
# 1950s - 1970s -0.010502 0.00209 Inf  -5.034  <.0001
# 1950s - 1980s -0.010204 0.00198 Inf  -5.144  <.0001
# 1950s - 1990s -0.013717 0.00212 Inf  -6.467  <.0001
# 1960s - 1970s -0.001524 0.00192 Inf  -0.795  0.9684
# 1960s - 1980s -0.001226 0.00181 Inf  -0.679  0.9843
# 1960s - 1990s -0.004740 0.00196 Inf  -2.423  0.1482
# 1970s - 1980s  0.000298 0.00178 Inf   0.167  1.0000
# 1970s - 1990s -0.003215 0.00194 Inf  -1.660  0.5582
# 1980s - 1990s -0.003513 0.00182 Inf  -1.926  0.3861
# 
# P value adjustment: tukey method for comparing a family of 6 estimates 

ggpredict(ghmh.3, terms = c("cohort", "ghmh [52, 64, 84]")) %>% plot()


ghmh.4 <- glmer(
  formula = missing_next ~ 1 + ghmh*cohort*age + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

# Adding age does not change the interaction between mental
# health and cohort
emtrends(ghmh.4, pairwise ~ cohort, var = "ghmh")

# $emtrends
# cohort ghmh.trend      SE  df asymp.LCL asymp.UCL
# 1940s    -0.00179 0.00742 Inf -0.016328  0.012758
# 1950s    -0.00709 0.00367 Inf -0.014289  0.000102
# 1960s    -0.00730 0.00162 Inf -0.010476 -0.004133
# 1970s    -0.00724 0.00203 Inf -0.011227 -0.003251
# 1980s    -0.00883 0.00340 Inf -0.015495 -0.002168
# 1990s     0.01641 0.00852 Inf -0.000293  0.033120
# 
# Confidence level used: 0.95 
# 
# $contrasts
# contrast       estimate      SE  df z.ratio p.value
# 1940s - 1950s  5.31e-03 0.00828 Inf   0.641  0.9879
# 1940s - 1960s  5.52e-03 0.00759 Inf   0.727  0.9787
# 1940s - 1970s  5.45e-03 0.00769 Inf   0.709  0.9810
# 1940s - 1980s  7.05e-03 0.00816 Inf   0.863  0.9551
# 1940s - 1990s -1.82e-02 0.01130 Inf  -1.610  0.5917
# 1950s - 1960s  2.11e-04 0.00401 Inf   0.053  1.0000
# 1950s - 1970s  1.45e-04 0.00420 Inf   0.035  1.0000
# 1950s - 1980s  1.74e-03 0.00500 Inf   0.347  0.9993
# 1950s - 1990s -2.35e-02 0.00928 Inf  -2.533  0.1146
# 1960s - 1970s -6.57e-05 0.00260 Inf  -0.025  1.0000
# 1960s - 1980s  1.53e-03 0.00377 Inf   0.406  0.9986
# 1960s - 1990s -2.37e-02 0.00868 Inf  -2.734  0.0688
# 1970s - 1980s  1.59e-03 0.00396 Inf   0.402  0.9987
# 1970s - 1990s -2.37e-02 0.00876 Inf  -2.699  0.0754
# 1980s - 1990s -2.52e-02 0.00917 Inf  -2.752  0.0655
# 
# P value adjustment: tukey method for comparing a family of 6 estimates 

# Write results
write_rds(ghmh.1, "results/missingness_1.rds")
write_rds(ghmh.2, "results/missingness_2.rds")
write_rds(ghmh.3, "results/missingness_3.rds")
write_rds(ghmh.4, "results/missingness_4.rds")





#### Difference smooths ####
library(mgcv)

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

filter(plot.data, !end_missing) %>%
  difference_gam(c("1990s", "1980s")) %>%
  write_rds("results/end_missing/gam_90v80.rds")

filter(plot.data, !end_missing) %>%
  difference_gam(c("1980s", "1970s")) %>%
  write_rds("results/end_missing/gam_80v70.rds")

filter(plot.data, !end_missing) %>%
  difference_gam(c("1970s", "1960s")) %>%
  write_rds("results/end_missing/gam_70v60.rds")

filter(plot.data, !end_missing) %>%
  difference_gam(c("1960s", "1950s")) %>%
  write_rds("results/end_missing/gam_60v50.rds")

filter(plot.data, !end_missing) %>%
  difference_gam(c("1950s", "1940s")) %>%
  write_rds("results/end_missing/gam_50v40.rds")

##### Plot difference smooths ####
library(patchwork)

# models
gam.list <- list(
  `90v80s` = read_rds("results/end_missing/gam_90v80.rds") %>% .$gam,
  `80v70s` = read_rds("results/end_missing/gam_80v70.rds") %>% .$gam,
  `70v60s` = read_rds("results/end_missing/gam_70v60.rds") %>% .$gam,
  `60v50s` = read_rds("results/end_missing/gam_60v50.rds") %>% .$gam,
  `50v40s` = read_rds("results/end_missing/gam_50v40.rds") %>% .$gam
)

# store the difference smooths
difference.smooths <- gam.list %>% 
  map2(.x = ., .y = names(gam.list), .f = ~{
    
    plot_obj <- plot(.x, seWithMean = T)
    # seWithMean = T for confidence intervals that include the uncertainty about
    # the overall mean as well as the centred smooth itself. This results in 
    # intervals with close to nominal (frequentist) coverage probabilities 
    # (Marra & Woods, 2012).
    
    bind_rows(
      
      as.data.frame(plot_obj[[1]][c("x", "se", "fit")]) %>%
        mutate(cohort = paste0("19", substring(.y, 4, 6), " smooth")),
      
      as.data.frame(plot_obj[[2]][c("x", "se", "fit")]) %>%
        mutate(cohort = paste0("19", substring(.y, 1, 2), " difference"))
    )
    
  }) 

difference_plot <- function(.df) {
  ggplot(.df, aes(x = x, y = fit)) +
    geom_hline(aes(yintercept=0), size = 0.1) + 
    geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
                fill = "grey80") +
    geom_line() +
    facet_wrap(~cohort) +
    labs(x = "Age (years)", y = "MHI-5 units") +
    theme_minimal(base_size = 9) +
    theme(panel.grid = element_blank(),
          axis.title = element_text(size = 7))
}

p1 <- difference_plot(difference.smooths[[1]])
p2 <- difference_plot(difference.smooths[[2]])
p3 <- difference_plot(difference.smooths[[3]])
p4 <- difference_plot(difference.smooths[[4]])
p5 <- difference_plot(difference.smooths[[5]])

p1 / p2 / p3 / p4 / p5









#### Within-person dependency ####







mf <- mhi5_present %>%
  mutate(missing = ghmh < 0) %>%
  # mutate(missing = ghmh == -10) %>%
  # mutate(missing = ghmh %in% c(-8, -10)) %>%
  group_by(xwaveid) %>%
  mutate(missing_next = lead(missing, default = FALSE)) %>%
  filter(ghmh > 0) %>%
  mutate(cghmh = c(scale(ghmh, scale=F)),
         tghmh = ghmh < 52) %>%
  ungroup() %>%
  filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
  mutate(age = c(scale(hhiage)),
         missing_next = as.factor(if_else(missing_next, "yes", "no")))

##### Null model ####
rfx.0 <- glmer(
  formula = missing_next ~ 1 + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

##### MHi5 model ####
rfx.1 <- glmer(
  formula = missing_next ~ 1 + cghmh + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

anova(rfx.0, rfx.1)
# Models:
#   rfx.0: missing_next ~ 1 + (1 | wave) + (1 | xwaveid)
#   rfx.1: missing_next ~ 1 + cghmh + (1 | wave) + (1 | xwaveid)
#       npar    AIC    BIC logLik deviance  Chisq Df Pr(>Chisq)    
# rfx.0    3 103177 103208 -51586   103171                         
# rfx.1    4 103149 103190 -51570   103141 30.519  1  3.306e-08 ***
# 
# cghmh predicts missingness

tidy(rfx.1, effects="fixed", conf.int=T)
# term  estimate std.error statistic p.value  conf.low conf.high
# cghmh -0.00444  0.000719     -6.18 6.47e-10 -0.00585  -0.00303 
# 
# 
# Lower cghmh scores predict some missingness, however the effect is small

##### Cohort main effect ####
rfx.2 <- glmer(
  formula = missing_next ~ 1 + cghmh + cohort + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

tidy(rfx.2, effects="fixed", conf.int=T)
# term        estimate std.error statistic   p.value conf.low conf.high
# cghmh       -0.00468  0.000721     -6.49 8.39e- 11 -0.00609  -0.00327
# cohort1950s  0.177    0.0534        3.31 9.40e-  4  0.0720    0.282  
# cohort1960s  0.504    0.0511        9.87 5.80e- 23  0.404     0.604  
# cohort1970s  0.868    0.0509       17.1  3.10e- 65  0.768     0.968  
# cohort1980s  1.18     0.0489       24.1  1.06e-128  1.08      1.28   
# cohort1990s  1.22     0.0518       23.5  4.46e-122  1.12      1.32   
# 
# Each cohort predicts missingness (relative to the 1940s cohort)

##### Cohort interaction ####
rfx.3 <- glmer(
  formula = missing_next ~ 1 + cghmh*cohort + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

# Adding the cghmh by cohort interaction does /not improve the model
anova(rfx.2, rfx.3)
#       npar    AIC    BIC logLik deviance  Chisq Df Pr(>Chisq)  
# rfx.2    9 102173 102267 -51078   102155                       
# rfx.3   14 102172 102317 -51072   102144 11.464  5    0.04291 *

# Missingness decreases as mental health improves for all cohorts
emtrends(rfx.3, pairwise ~ cohort, var = "cghmh")
# $emtrends
# cohort cghmh.trend      SE  df asymp.LCL asymp.UCL
# 1940s     -0.00597 0.00269 Inf  -0.01124 -0.000699
# 1950s     -0.01109 0.00205 Inf  -0.01511 -0.007063
# 1960s     -0.00275 0.00169 Inf  -0.00606  0.000571
# 1970s     -0.00203 0.00165 Inf  -0.00526  0.001193
# 1980s     -0.00495 0.00142 Inf  -0.00772 -0.002171
# 1990s     -0.00448 0.00173 Inf  -0.00787 -0.001096
# 
# Confidence level used: 0.95 
# 
# $contrasts
# contrast       estimate      SE  df z.ratio p.value
# 1940s - 1950s  0.005118 0.00338 Inf   1.513  0.6557
# 1940s - 1960s -0.003221 0.00318 Inf  -1.014  0.9135
# 1940s - 1970s -0.003936 0.00315 Inf  -1.249  0.8127
# 1940s - 1980s -0.001020 0.00304 Inf  -0.336  0.9994
# 1940s - 1990s -0.001487 0.00320 Inf  -0.465  0.9973
# 1950s - 1960s -0.008339 0.00266 Inf  -3.134  0.0213 *
# 1950s - 1970s -0.009054 0.00263 Inf  -3.441  0.0076 **
# 1950s - 1980s -0.006138 0.00249 Inf  -2.461  0.1358
# 1950s - 1990s -0.006605 0.00268 Inf  -2.462  0.1355
# 1960s - 1970s -0.000715 0.00236 Inf  -0.303  0.9997
# 1960s - 1980s  0.002201 0.00221 Inf   0.997  0.9191
# 1960s - 1990s  0.001734 0.00242 Inf   0.717  0.9799
# 1970s - 1980s  0.002916 0.00217 Inf   1.343  0.7610
# 1970s - 1990s  0.002449 0.00238 Inf   1.027  0.9090
# 1980s - 1990s -0.000467 0.00223 Inf  -0.209  0.9999
# 
# P value adjustment: tukey method for comparing a family of 6 estimates

#### Age models ####
rfx.4.0 <- glmer(
  formula = missing_next ~ 1 + cghmh*cohort + age + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

rfx.4.1 <- glmer(
  formula = missing_next ~ 1 + cghmh*cohort*age + (1|wave) + (1|xwaveid),
  family = "binomial",
  data = mf)

# Adding the age interaction does /not improve the model
anova(rfx.4.0, rfx.4.1)
#         npar    AIC    BIC logLik deviance  Chisq Df Pr(>Chisq)    
# rfx.4.0   15 102134 102290 -51052   102104                         
# rfx.4.1   26 102094 102365 -51021   102042 61.325 11  5.255e-09 ***
  
emtrends(rfx.4.1, pairwise ~ cohort, var = "cghmh")
# $emtrends
# cohort cghmh.trend      SE  df asymp.LCL asymp.UCL
# 1940s      0.00747 0.01007 Inf  -0.01227  0.027214
# 1950s     -0.00273 0.00452 Inf  -0.01158  0.006119
# 1960s     -0.00307 0.00184 Inf  -0.00667  0.000536
# 1970s     -0.00383 0.00251 Inf  -0.00875  0.001095
# 1980s     -0.00871 0.00440 Inf  -0.01734 -0.000083
# 1990s     -0.00371 0.01076 Inf  -0.02481  0.017385
# 
# Confidence level used: 0.95 
# 
# $contrasts
# contrast       estimate      SE  df z.ratio p.value
# 1940s - 1950s  0.010204 0.01104 Inf   0.925  0.9403
# 1940s - 1960s  0.010539 0.01024 Inf   1.029  0.9082
# 1940s - 1970s  0.011301 0.01038 Inf   1.089  0.8861
# 1940s - 1980s  0.016184 0.01099 Inf   1.472  0.6821
# 1940s - 1990s  0.011185 0.01474 Inf   0.759  0.9743
# 1950s - 1960s  0.000335 0.00488 Inf   0.069  1.0000
# 1950s - 1970s  0.001097 0.00517 Inf   0.212  0.9999
# 1950s - 1980s  0.005980 0.00631 Inf   0.948  0.9338
# 1950s - 1990s  0.000981 0.01167 Inf   0.084  1.0000
# 1960s - 1970s  0.000762 0.00311 Inf   0.245  0.9999
# 1960s - 1980s  0.005645 0.00477 Inf   1.183  0.8451
# 1960s - 1990s  0.000646 0.01092 Inf   0.059  1.0000
# 1970s - 1980s  0.004883 0.00507 Inf   0.964  0.9293
# 1970s - 1990s -0.000116 0.01105 Inf  -0.011  1.0000
# 1980s - 1990s -0.004999 0.01163 Inf  -0.430  0.9981
# 
# P value adjustment: tukey method for comparing a family of 6 estimates 



#### Illness model ####
rfx.5 <- glmer(
  formula = missing_next ~ 1 + tghmh*cohort + (1|xwaveid),
  family = "binomial",
  data = mf)

tidy(rfx.5, effects="fixed") %>%
  filter(str_detect(term, ":")) %>%
  select(-effect)
emmip(rfx.5, cohort ~ tghmh, cov.reduce = range)
ggpredict(rfx.5, terms = c("cohort", "tghmh")) %>% plot()


#### No missing smooths ####
library(mgcv)

# Quick example
filter(plot.data, !end_missing) %>%
  filter(cohort %in% c("1980s", "1970s")) %>% 
  gamm(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    correlation=corAR1(form=~1|xwaveid),
    method = "REML",
    data = .
  ) -> fit

plot(fit$gam, shade=T, pages=1)





balanced <- mhi5_present %>%
  rename(age = hhiage) %>%
  mutate(missing = ghmh < 0) %>%
  group_by(xwaveid) %>%
  mutate(any_missing = any(missing)) %>%
  ungroup() %>%
  filter(!any_missing) %>%
  mutate(xwaveid = factor(xwaveid),
         ocohort = ordered(cohort),
         fcohort = factor(cohort))

balanced %>%
  filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
  ggplot(aes(x = age, y = ghmh)) +
    geom_smooth(aes(group = 1), 
                method = "gam", formula = y ~ s(x, bs = "cs"), 
                se=F, color = "black", size = .5, linetype = "dashed") +
    geom_smooth(aes(group = cohort, color = cohort), 
                method = "gam", formula = y ~ s(x, bs = "cs"), 
                se=F, alpha = 0.2) +
    labs(
      subtitle = "Smoothed MHi-5 scores (0-100)", 
      y = "", x = "\n Age (years)") +
    scale_color_manual(values = grey.colors(6, rev = T)) +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold"),
          legend.title = element_text(size = 10),
          legend.position = c(0.9, 0.82),
          axis.title.x = element_text(size = 10))



df %>%
  filter(cohort %in% c("1990s", "1980s")) %>%
  gamm(
    formula = ghmh ~ cohort + s(age) + s(age, by = ocohort),
    correlation=corAR1(form=~1|xwaveid),
    method = "REML",
    data = .
  ) -> fit

plot(fit$gam, shade=T, pages=1)





