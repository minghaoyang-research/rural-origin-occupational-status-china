# mapping figure from saved tables
map_table <- read.csv("output/tables/mapping_contributions.csv")
map_models <- read.csv("output/tables/model_coefficients.csv")
map_scales <- read.csv("output/tables/scale_comparison.csv")
map_plot <- map_table[map_table$occupation != "Total", ]
plot_n <- map_table$N[map_table$occupation == "Total"]
limits <- range(c(0, map_plot$rural_change_SD, map_plot$female_change_SD))
padding <- .28 * diff(limits)

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
png("output/figures/mapping_contributions.png", width = 2400, height = 1250, res = 200)
par(mfrow = c(1, 2), mar = c(5, 10, 4, 2), oma = c(3, 0, 2, 0))
for (term in c("rural_origin", "female")) {
  change <- map_plot[[if (term == "rural_origin") "rural_change_SD" else "female_change_SD"]]
  b <- vapply(c("primary", "overview"), function(version) {
    raw <- map_models$B[map_models$version == version & map_models$model == "Model3" &
                          map_models$term == term]
    scale <- if (version == "primary") "ISEI syntax" else "ISEI overview"
    raw / map_scales$outcome_sd[map_scales$scale == scale]
  }, numeric(1))
  positions <- nrow(map_plot):1
  label <- if (term == "rural_origin") "Rural origin" else "Female"
  plot(NA, xlim = limits + c(-padding, padding), ylim = c(.4, nrow(map_plot) + .6),
       yaxt = "n", xlab = "Contribution to coefficient change (outcome SDs)", ylab = "",
       main = sprintf("%s: %.4f to %.4f", label, b[1], b[2]))
  axis(2, at = positions, labels = map_plot$occupation, las = 1, cex.axis = .85)
  abline(v = 0, col = "grey65")
  rect(pmin(0, change), positions - .22, pmax(0, change), positions + .22,
       col = "grey35", border = NA)
  labels <- ifelse(abs(change) < .0005, sprintf("%+.5f", change), sprintf("%+.3f", change))
  text(change, positions, labels, pos = ifelse(change < 0, 2, 4), offset = .4, cex = .75)
  mtext(sprintf("Sum of contributions: %+.4f", sum(change)), side = 3, line = .4, cex = .8)
}
mtext("ISEI mapping changes after centring and scaling", outer = TRUE, side = 3, line = .4, font = 2)
mtext(sprintf("Each mapping has mean 0 and SD 1; overview minus syntax (N = %s).",
              format(plot_n, big.mark = ",")), outer = TRUE, side = 1, line = .5, cex = .75)
dev.off()
