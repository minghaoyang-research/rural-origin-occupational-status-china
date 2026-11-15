# rural coefficient figure from saved tables
# run after scripts 09, 11 and 12: Rscript --vanilla R/13_plot_rural_coefficient.R

steps <- read.csv("output/supplementary/origin-adjustment/models.csv")
teaching <- read.csv("output/supplementary/teaching-composition/teaching_indicator.csv")
profiles <- read.csv("output/supplementary/local-profiles/profiles.csv")
raw <- steps[steps$model == "none", ]
adjusted <- steps[steps$model == "all", ]
teaching <- teaching[teaching$sample == "Main" & teaching$outcome == "isei", ]
scores <- profiles[match(c("ISEI", "Schooling", "Earnings"), profiles$quantity), ]
gaps <- profiles[match(c("ISEI minus Schooling", "ISEI minus Earnings"), profiles$quantity), ]

controls <- data.frame(
  label = c("No controls", "Qualification tier, parental\nschooling, sex and age", "Plus a teaching indicator"),
  B = c(raw$B, adjusted$B, teaching$expanded_B),
  low = c(raw$CI_low, adjusted$CI_low, teaching$expanded_CI_low),
  high = c(raw$CI_high, adjusted$CI_high, teaching$expanded_CI_high))
rankings <- data.frame(label = c("ISEI", "Schooling of its workers", "Earnings of its workers"),
                       B = scores$B_SD, low = scores$percentile_low, high = scores$percentile_high)

# one row per estimate
panel <- function(z, main, xlab, margin) {
  rows <- nrow(z):1
  plot(NA, xlim = range(c(0, z$low, z$high)) + c(-margin, margin), ylim = c(.5, nrow(z) + .5),
       yaxt = "n", xlab = xlab, ylab = "", main = main, cex.main = 1)
  axis(2, at = rows, labels = z$label, las = 1, cex.axis = .9)
  abline(v = 0, lty = 2, col = "grey70")
  segments(z$low, rows, z$high, rows, lwd = 2)
  points(z$B, rows, pch = 16)
  text(z$B, rows + .2, sprintf("%.2f", z$B), cex = .85)
}

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
png("output/figures/rural_coefficient.png", width = 2400, height = 1000, res = 200)
par(mfrow = c(1, 2), mar = c(5, 12, 3, 1), oma = c(2, 0, 0, 0))
panel(controls, sprintf("Controls added (%s graduates)", format(raw$N, big.mark = ",")),
      "Rural - urban ISEI difference (95% HC3 CI)", .4)
panel(rankings, sprintf("Occupation scored by (%s workers)", format(scores$N[1], big.mark = ",")),
      "Rural coefficient in SDs (95% bootstrap interval)", .03)
note <- sprintf("Paired differences from ISEI: schooling %.2f (%.2f to %.2f), earnings %.2f (%.2f to %.2f).",
                gaps$B_SD[1], gaps$percentile_low[1], gaps$percentile_high[1],
                gaps$B_SD[2], gaps$percentile_low[2], gaps$percentile_high[2])
mtext(paste("CGSS 2017; unweighted.", note), outer = TRUE, side = 1, line = .5, cex = .75)
dev.off()
