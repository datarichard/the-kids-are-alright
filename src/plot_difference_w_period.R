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

func1 <- function(x) round(seq(min(x), max(x), 1))
func2 <- function(x) round(seq(min(x), max(x), 2))

#### recover age ####
# hilda.data %>% 
#   filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
#   group_by(cohort) %>%
#   summarise(
#     low = min(age),
#     m = mean(age),
#     hi = max(age)
#   ) 
#   
#         Ages:
# cohort    low     m    hi
#  1940s     52  65.5    80
#  1950s     42  55.8    70
#  1960s     32  46.2    60
#  1970s     22  36.8    50
#  1980s     15  27.0    40
#  1990s     15  21.0    30



#### recover MHI-5 ####
# hilda.data %>% 
#   filter(cohort %in% c("1940s", "1950s", "1960s", "1970s", "1980s", "1990s")) %>%
#   group_by(cohort) %>%
#   summarise(
#     ghmh = mean(ghmh)
#   ) 
# 
# cohort   ghmh
#  1940s   76.6
#  1950s   74.7
#  1960s   73.3
#  1970s   72.9
#  1980s   72.2
#  1990s   70.6

#### reference plots ####
plot_obj <- plot(fit, seWithMean = T)

reference_plots <- bind_rows(
  as.data.frame(plot_obj[[1]][c("x", "se", "fit")]) %>%
    mutate(cohort = "1940s smooth",
           age = x + 65,
           fit = fit + 76.6,
           y = if_else(age < 52 | age > 80, NA_real_, fit)),
  as.data.frame(plot_obj[[2]][c("x", "se", "fit")]) %>%
    mutate(cohort = "1950s smooth",
           age = x + 56,
           fit = fit + 74.7,
           y = if_else(age < 42 | age > 70, NA_real_, fit)),
  as.data.frame(plot_obj[[3]][c("x", "se", "fit")]) %>%
    mutate(cohort = "1960s smooth",
           age = x + 46,
           fit = fit + 73.3,
           y = if_else(age < 32 | age > 60, NA_real_, fit)),
  as.data.frame(plot_obj[[4]][c("x", "se", "fit")]) %>%
    mutate(cohort = "1970s smooth",
           age = x + 37,
           fit = fit + 72.9,
           y = if_else(age < 22 | age > 50, NA_real_, fit)),
  as.data.frame(plot_obj[[5]][c("x", "se", "fit")]) %>%
    mutate(cohort = "1980s smooth",
           age = x + 27,
           fit = fit + 72.2,
           y = if_else(age < 15 | age > 40, NA_real_, fit))
) %>%
  mutate(cohort = fct_rev(cohort))



p1 <- ggplot(reference_plots, aes(x = age)) +
  geom_ribbon(aes(ymin = fit - se, ymax = fit + se, y = NULL),
              fill = "grey80") +
  geom_line(aes(y = y)) +
  scale_y_continuous(breaks = func2) +
  facet_wrap(~cohort, ncol = 1, scales ="free") +
  labs(x = "Age (years)", y = "MHI-5 score") +
  theme_minimal(base_size = 9) +
  theme(panel.grid = element_blank(),
        axis.title = element_text(size = 7))

#### difference plots ####
smooth_diff <- function(model, f1, f2, var, alpha = 0.05,
                        unconditional = TRUE) {
  
  pdat <- expand.grid(
    age = -10:10,
    fcohort = as.factor(c(f1, f2)),
    year = 2001:2020)
  
  xp <- predict(model, newdata = pdat, type = 'lpmatrix')
  c1 <- grepl(f1, colnames(xp))
  c2 <- grepl(f2, colnames(xp))
  r1 <- pdat[[var]] == f1
  r2 <- pdat[[var]] == f2
  ## difference rows of xp for data from comparison
  X <- xp[r1, ] - xp[r2, ]
  ## zero out cols of X related to splines for other lochs
  X[, ! (c1 | c2)] <- 0
  ## zero out the parametric cols
  X[, !grepl('^s\\(', colnames(xp))] <- 0
  dif <- X %*% coef(model)
  se <- sqrt(rowSums((X %*% vcov(model, unconditional = unconditional)) * X))
  crit <- qt(alpha/2, df.residual(model), lower.tail = FALSE)
  upr <- dif + (crit * se)
  lwr <- dif - (crit * se)
  data.frame(pair = paste(f1, f2, sep = '-'),
             age = -10:10,
             diff = dif,
             se = se,
             upper = upr,
             lower = lwr)
}


difference_plots <- bind_rows(
  smooth_diff(fit, '1990s', '1980s', 'fcohort') %>%
    mutate(age = age + 24,
           diff = if_else(age < 15 | age > 30, NA_real_, diff)),
  smooth_diff(fit, '1980s', '1970s', 'fcohort') %>%
    mutate(age = age + 27,
           diff = if_else(age < 15 | age > 40, NA_real_, diff)),
  smooth_diff(fit, '1970s', '1960s', 'fcohort') %>%
    mutate(age = age + 37,
           diff = if_else(age < 22 | age > 50, NA_real_, diff)),
  smooth_diff(fit, '1960s', '1950s', 'fcohort') %>%
    mutate(age = age + 46,
           diff = if_else(age < 32 | age > 60, NA_real_, diff)),
  smooth_diff(fit, '1950s', '1940s', 'fcohort') %>%
    mutate(age = age + 56,
           diff = if_else(age < 42 | age > 70, NA_real_, diff))
) %>%
  mutate(pair = fct_rev(pair))


p2 <- ggplot(difference_plots, aes(x = age, y = diff, group = pair)) +
    geom_hline(aes(yintercept=0), size = 0.1) + 
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2) +
    geom_line() +
    scale_y_continuous(breaks = func2) +
    facet_wrap(~ pair, ncol = 1, scales = "free") +
    labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 9) +
    theme(panel.grid = element_blank(),
          axis.title = element_text(size = 7))





p1 + p2













