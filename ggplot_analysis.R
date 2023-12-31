library(viridis)
library(dplyr)
library(ggplot2)
library(scales) # For breaks_width()
library(ggthemes) # Load additional ggplot themes
library(ggpmisc) # To display equation on plot

source("private.r")
ROWER_NAME <- identity$name

IGNORED_DISTANCES = c()

format_seconds <- function(x) {
  mins <- floor(x / 60)
  secs <- x %% 60
  sprintf("%2d:%02d", mins, secs)
}

# Loading dfs and removing columns with only NAs
season_df <- read.csv('Concept2-data/concept2-season-2024.csv')
#Removing 'formatted' columns
season_df[c(4,6,12)] <- rep(NULL,3)

colnames(season_df)[c(4,5,8)] <- c("Work.Time.Seconds","Rest.Time.Seconds","SPM")
season_df$Pace.Seconds <- (season_df$Work.Time.Seconds/season_df$Work.Distance)*500
season_df <- Filter(function(x)!all(is.na(x)), season_df)
season_df <- season_df[!season_df$Work.Distance %in% IGNORED_DISTANCES, ]
head(season_df)

ggplot(season_df, aes(x = SPM, y = Pace.Seconds, color = factor(Work.Distance, levels = sort(unique(Work.Distance))), alpha = as.POSIXct(Date))) + 
  geom_point(size = 4) +
  scale_x_continuous(breaks = breaks_width(1)) + 
  # scale_color_continuous(trans = "log10") + si color est numerique
  scale_y_continuous(breaks = breaks_width(4), labels = format_seconds) + 
  scale_color_manual(values = rainbow(length(unique(season_df$Work.Distance)), rev=TRUE)) +
  labs(color = "Distance (m)") +
  theme_solarized(base_size = 16) 



# Group by column 'W.D' and summarize to get the minimum time for each 'W.D' value
best_times_df <- subset(season_df, !(Work.Distance %in% IGNORED_DISTANCES)) %>%
  group_by(Work.Distance) %>%
  summarize(Pace.Seconds = min(Pace.Seconds)) 

best_times_df$Work.Distance.Log <- 5 * log2(best_times_df$Work.Distance/2000)

# Fit a linear regression model
fit <- lm(Pace.Seconds ~ Work.Distance.Log , data=best_times_df)
summary(fit)$r.squared

# PLOTTING
# Plotting points and model
ggplot(season_df, aes(x = Work.Distance, y = Pace.Seconds, color = SPM)) + 
  geom_smooth(data = best_times_df,
              method = "lm", formula = y ~ log2(x/2000), 
              color = "black", alpha=0.08, linewidth = 0.4,
              fullrange=TRUE, n=1000) +
  geom_point(data = best_times_df ,size=5, shape=1, color = "black") +
  geom_point(size = 3) +

  
# Styling
  
  scale_color_viridis_c(direction = -1) +
  scale_x_continuous(n.breaks=20, expand=c(0,0), limits=c(0,max(season_df$Work.Distance)*1.02)) + 
  coord_cartesian(ylim=c(min(season_df$Pace.Seconds),max(season_df$Pace.Seconds))) +
  # scale_color_continuous(trans = "log10") + si color est numerique
  scale_y_continuous(breaks = breaks_width(4), labels = format_seconds, expand = expansion(add= c(10,2))) + 
  theme_solarized(base_size = 14) +

  
# Adding labels
  
  labs(title = paste("Loi de Paul pour", ROWER_NAME),
       caption = "github.com/sileooo/rowing-data-analysis") + 
  xlab("Distance") + 
  ylab("Temps pour 500 m")

