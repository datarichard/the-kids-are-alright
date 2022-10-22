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
  filter(age_group %notin% c("0-14", "75-84", "85+")) %>%
  filter(cohort %notin% c("1920s", "1930s", "2000s"))

plot_APC <- function(.df, ylims = NULL) {
  
  plot_years <- c(seq(2001, 2020, 3), 2020)
  
  line_colors <- c("#9ECAE1", "#6BAED6", "#4292C6", "#2171B5", "#08519C", "#08306B")
  line_highlight <- c("#9ECAE1", "#6BAED6", "#4292C6", "#2171B5", "#08519C", "#ed111a")
  
  p1 <- ggplot(.df, aes(x = year, y = wellbeing)) +
    geom_smooth(aes(group = age_group, color = age_group), 
                method = "gam", se=F) +
    labs(
      subtitle = "Mental Wellbeing (0-100) is lower for younger age groups 
across all survey years, and especially low in recent surveys", 
      y = "", x = "\n Survey year") +
    coord_cartesian(ylim = ylims) +
    scale_color_manual(values = rev(line_colors)) +
    theme_economist() +
    theme(plot.title = element_text(face = "bold"),
          legend.title = element_text(size = 10),
          axis.title.x = element_text(size = 12))
  
  
  p2 <- ggplot(.df, aes(x = age, y = wellbeing)) +
    geom_smooth(aes(group = 1), method = "gam", 
                se=F, color = "black", size = .5, linetype = "dashed") +
    geom_smooth(aes(group = cohort, color = cohort), 
                method = "gam", 
                formula = y ~ s(x, bs = "cs"), se=F) +
    coord_cartesian(ylim = ylims) +
    labs(
      subtitle = "Mental Wellbeing (0-100) is getting worse for younger 
generations, particularly Millenials (red)", 
      y = "", x = "\n Age (years)") +
    scale_color_manual(values = line_highlight) +
    theme_economist() +
    theme(plot.title = element_text(face = "bold"),
          legend.title = element_text(size = 10),
          axis.title.x = element_text(size = 12))
  
  p1 + p2 + 
    plot_annotation(
      title = "\"The kids are not alright\"",
      caption = "Data source: HILDA Survey 2001-2020") & 
    theme(legend.position = "bottom",
          legend.title = element_blank(),
          legend.text = element_text(size = 10),
          plot.title = element_text(size = 18, face = "bold"),
          plot.background = element_rect(fill = "#d5e4eb"))
}


hilda.data %>%
  rename(wellbeing = ghmh) %>%
  plot_APC(ylims = c(65, 80))

