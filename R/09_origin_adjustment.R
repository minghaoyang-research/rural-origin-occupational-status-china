# adjustment of the rural coefficient; run after 04
source("R/03_construct_isei.R")
d <- as.data.frame(analysis_sample)
blocks <- list(education = c("edu_bachelor", "edu_postgrad"),
               parental = "par_edu_yrs", demographics = c("female", "age"))
controls <- unname(unlist(blocks))
full_formula <- isei ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin
out <- "output/supplementary/origin-adjustment"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
save_table <- function(x, name) write.csv(x, file.path(out, paste0(name, ".csv")), row.names = FALSE)

# eight control combinations, always including rural origin
subsets <- list(none = character(), education = "education", parental = "parental",
                demographics = "demographics", education_parental = c("education", "parental"),
                education_demographics = c("education", "demographics"),
                parental_demographics = c("parental", "demographics"),
                all = names(blocks))
models <- list()
for (name in names(subsets)) {
  groups <- subsets[[name]]
  variables <- c("rural_origin", unlist(blocks[groups]))
  fit <- lm(reformulate(variables, "isei"), data = d, na.action = na.fail)
  models[[name]] <- fit
}
same_rows <- all(vapply(models, function(fit)
  identical(rownames(model.frame(fit)), rownames(d)), logical(1)))
raw <- models$none

model_row <- function(fit, label, data) {
  b <- unname(coef(fit)["rural_origin"])
  se <- sqrt(sandwich::vcovHC(fit, type = "HC3")["rural_origin", "rural_origin"])
  cl <- province_table(fit, data)
  cl <- cl[cl$term == "rural_origin", ]
  data.frame(model = label, N = nobs(fit), B = b, SE_HC3 = se,
             df = df.residual(fit), CI_low = b - qt(.975, df.residual(fit)) * se,
             CI_high = b + qt(.975, df.residual(fit)) * se,
             p_HC3 = 2 * pt(abs(b / se), df.residual(fit), lower.tail = FALSE),
             provinces = cl$provinces, SE_province = cl$SE_province,
             province_CI_low = cl$CI_low, province_CI_high = cl$CI_high,
             p_province = cl$p_province)
}
steps <- NULL
coefficients <- NULL
for (name in names(models)) {
  fit <- models[[name]]
  steps <- rbind(steps, model_row(fit, name, d))
  b <- coef(fit)
  coefficients <- rbind(coefficients, data.frame(model = name, term = names(b), B = unname(b)))
}
save_table(steps, "models")
save_table(coefficients, "coefficients")

# control slopes and rural–urban mean gaps
decompose <- function(data, outcome = "isei", weights = rep(1, nrow(data))) {
  data$adjustment_weight <- weights
  full <- lm(update(full_formula, paste(outcome, "~ .")), data = data,
             weights = adjustment_weight, na.action = na.fail, singular.ok = FALSE)
  short <- lm(reformulate("rural_origin", outcome), data = data, weights = adjustment_weight, na.action = na.fail)
  rural <- data$rural_origin == 1
  urban_mean <- rural_mean <- setNames(numeric(length(controls)), controls)
  for (name in controls) {
    x <- data[[name]]
    urban_mean[name] <- weighted.mean(x[!rural], weights[!rural])
    rural_mean[name] <- weighted.mean(x[rural], weights[rural])
  }
  beta <- coef(full)[controls]
  change <- -beta * (rural_mean - urban_mean)
  terms <- data.frame(term = controls, block = rep(names(blocks), lengths(blocks)),
                      urban_mean, rural_mean, gap = rural_mean - urban_mean,
                      B_full = unname(beta), increase = unname(change), row.names = NULL)
  group <- aggregate(increase ~ block, terms, sum)
  b0 <- unname(coef(short)["rural_origin"])
  b1 <- unname(coef(full)["rural_origin"])
  list(terms = terms, groups = group, raw = b0, adjusted = b1, full = full, short = short)
}
primary <- decompose(d)
save_table(primary$terms, "decomposition_terms")
groups <- primary$groups
groups$percent_of_increase <- 100 * groups$increase / (primary$adjusted - primary$raw)
save_table(groups, "decomposition_groups")

# record the saved Model 3 alongside this fit
means <- tapply(d$isei, d$rural_origin, mean)
saved <- read.csv("output/tables/model_coefficients.csv")
saved <- saved[saved$version == "primary" & saved$model == "Model3" & saved$term == "rural_origin", ]
save_table(data.frame(N = nrow(d), rural_N = sum(d$rural_origin == 1),
                     urban_N = sum(d$rural_origin == 0), all_models_same_rows = same_rows,
                     urban_mean = means[1], rural_mean = means[2], raw_B = primary$raw,
                     adjusted_B = primary$adjusted, increase = primary$adjusted - primary$raw,
                     decomposition_sum = sum(groups$increase),
                     saved_Model3_B = saved$B, saved_Model3_SE_HC3 = saved$SE_HC3,
                     identity_error = primary$adjusted - primary$raw - sum(groups$increase)), "verification")

# six orders of adding controls
orders <- rbind(c(1, 2, 3), c(1, 3, 2), c(2, 1, 3), c(2, 3, 1), c(3, 1, 2), c(3, 2, 1))
sequential <- NULL
for (i in seq_len(nrow(orders))) {
  path <- names(blocks)[orders[i, ]]
  before <- primary$raw
  for (j in seq_along(path)) {
    added <- path[seq_len(j)]
    # model names use education, parental, demographics in that order
    included <- names(blocks)[names(blocks) %in% added]
    name <- if (j == 3) "all" else paste(included, collapse = "_")
    after <- unname(coef(models[[name]])["rural_origin"])
    sequential <- rbind(sequential, data.frame(order = paste(path, collapse = " > "),
      step = j, added = path[j], before, after, increase = after - before))
    before <- after
  }
}
save_table(sequential, "sequences")
order_summary <- NULL
for (g in names(blocks)) {
  changes <- sequential$increase[sequential$added == g]
  order_summary <- rbind(order_summary, data.frame(
    block = g, minimum = min(changes), maximum = max(changes), order_average = mean(changes),
    full_model_decomposition = groups$increase[match(g, groups$block)]))
}
save_table(order_summary, "order_summary")

# weights, alternative scoring and current occupations
variants <- list(main = primary,
                 survey_weighted = decompose(d, weights = as.numeric(d$weight)),
                 overview_ISEI = decompose(d, outcome = "isei_overview"),
                 current_occupation = decompose(d[d$occ_source == "current_A59", ]))
sensitivity <- NULL
for (name in names(variants)) {
  x <- variants[[name]]
  g <- setNames(x$groups$increase, x$groups$block)
  sensitivity <- rbind(sensitivity, data.frame(
    version = name, N = nobs(x$full), raw_B = x$raw, adjusted_B = x$adjusted,
    increase = x$adjusted - x$raw, education = g["education"],
    parental = g["parental"], demographics = g["demographics"]))
}
save_table(sensitivity, "sensitivity")

# province bootstrap: repeat whole provinces using frequency weights
set.seed(42)
province <- match(d$s41, sort(unique(d$s41)))
G <- max(province)

point <- origin_adjustment_draw(d, rep(1, nrow(d)), full_formula, blocks)
B <- 1999L
boot_draws <- matrix(NA_real_, nrow = length(point), ncol = B,
                     dimnames = list(names(point), NULL))
for (i in seq_len(B)) {
  multiplicity <- tabulate(sample.int(G, G, replace = TRUE), nbins = G)
  boot_draws[, i] <- origin_adjustment_draw(d, multiplicity[province], full_formula, blocks)
}
stopifnot(all(is.finite(boot_draws)))
ci <- matrix(NA_real_, nrow = length(point), ncol = 2)
for (i in seq_along(point)) ci[i, ] <- quantile(boot_draws[i, ], probs = c(.025, .975))
save_table(data.frame(quantity = names(point), estimate = unname(point),
                     percentile_low = ci[, 1], percentile_high = ci[, 2],
                     resamples = B, provinces = G, seed = 42, row.names = NULL), "bootstrap")
writeLines(capture.output(sessionInfo()), file.path(out, "session-info.txt"))
print(steps[, c("model", "N", "B", "CI_low", "CI_high")], row.names = FALSE)
print(groups, row.names = FALSE)
cat("Saved origin-adjustment tables.\n")
