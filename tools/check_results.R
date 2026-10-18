# Saved samples, coefficient contrasts and decompositions.
read_table <- function(name) read.csv(file.path("output/tables", paste0(name, ".csv")))
same <- function(actual, expected, label) {
  if (!length(actual) || any(!is.finite(actual)) ||
      !isTRUE(all.equal(actual, expected, tolerance = 1e-8, check.attributes = FALSE)))
    stop(label, call. = FALSE)
}

flow <- read_table("sample_flow")
coefs <- read_table("model_coefficients")
origin <- read_table("origin_summary")
N <- tail(flow$N, 1)
same(read_table("model_fit")$N, rep(N, 7), "Primary model sample sizes")
same(sum(origin$N), N, "Origin totals")
selection <- read_table("selection_by_origin")
for (group in c("Urban", "Rural")) {
  z <- selection[selection$origin == group, ]
  same(z$percent_of_age_group, 100 * z$N / z$N[z$stage == "age_eligible"], "Selection percentages")
  same(z$N[z$stage == "final_sample"], origin$N[origin$origin == group], "Selection final counts")
}
income <- read_table("income_comparison")
same(income$N, rep(tail(read_table("income_sample_flow")$N, 1), nrow(income)), "Matched income sample")
routes <- read_table("teaching_routes")
route_counts <- read_table("teaching_route_counts")
for (sample in c("full", "current")) {
  z <- routes[routes$sample == sample, ]
  same(z$N, rep(sum(route_counts$N[route_counts$sample == sample]), nrow(z)), "Matched qualification-route samples")
}

# HC3 residual df and clustered G-1 df on the main fit.
m3 <- coefs[coefs$version == "primary" & coefs$model == "Model3", ]
df <- N - nrow(m3)
same(cbind(m3$p_HC3, m3$CI_low, m3$CI_high),
     cbind(2 * pt(abs(m3$B / m3$SE_HC3), df, lower.tail = FALSE),
           m3$B - qt(.975, df) * m3$SE_HC3, m3$B + qt(.975, df) * m3$SE_HC3), "Model 3 HC3 inference")
province <- read_table("province_cluster")
z <- province[province$specification == "unweighted", ]
same(z$B, m3$B[match(z$term, m3$term)], "Clustered Model 3 coefficients")
same(cbind(z$p_province, z$CI_low, z$CI_high),
     cbind(2 * pt(abs(z$B / z$SE_province), z$provinces - 1, lower.tail = FALSE),
           z$B - qt(.975, z$provinces - 1) * z$SE_province,
           z$B + qt(.975, z$provinces - 1) * z$SE_province), "Model 3 clustered inference")
m4 <- coefs[coefs$version == "primary" & coefs$model == "Model4", ]
b4 <- setNames(m4$B, m4$term)
tier <- read_table("within_tier_origin")
same(tier$B[order(tier$tier)], unname(b4["rural_origin"] + c(0, b4["bach_x_rural"], b4["post_x_rural"])),
     "Model 4 within-tier coefficients")

crosswalk <- read.csv("output/tables/isei_mapping.csv", colClasses = c(isco4 = "character"))
same(crosswalk$overview[crosswalk$isco4 == "3314"], 63, "ISCO 3314 correction")
mapping <- read_table("mapping_contributions")
pieces <- mapping[mapping$occupation != "Total", ]
scales <- read_table("scale_comparison")
for (term in c("rural_origin", "female")) {
  column <- if (term == "rural_origin") "rural_change" else "female_change"
  base <- m3$B[m3$term == term]
  alternative <- coefs$B[coefs$version == "overview" & coefs$model == "Model3" & coefs$term == term]
  same(sum(pieces[[column]]), alternative - base, paste(term, "mapping change"))
  same(sum(pieces[[paste0(column, "_SD")]]),
       alternative / scales$outcome_sd[scales$scale == "ISEI overview"] -
         base / scales$outcome_sd[scales$scale == "ISEI syntax"], paste(term, "standardised mapping change"))
}

# Reference shifts against the three directly fitted allocations.
contributions <- read_table("occupation_contributions")
reference <- read_table("occupation_reference_sensitivity")
base <- contributions[contributions$reference == "Sample mean", ]
adjusted <- read_table("occupation_adjusted")
gamma <- setNames(adjusted$adjusted_difference_pp / 100, adjusted$occupation)
gamma <- c(gamma, Other = -sum(gamma), Total = 0)
same(reference$membership_B, unname(gamma[reference$occupation]), "Membership coefficients in proportions")
expected <- base$B[match(reference$occupation, base$occupation)] -
  (reference$reference_score - base$reference_score[1]) * reference$membership_B
same(reference$B, expected, "Occupation allocation reference shift")
keys <- paste(reference$reference, reference$occupation)
rows <- match(paste(contributions$reference, contributions$occupation), keys)
same(reference$B[rows], contributions$B, "Reference formula and direct fits")
same(sum(base$B[base$occupation != "Total"]), m3$B[m3$term == "rural_origin"], "Occupation allocation total")

# Sector contrasts use the rural coefficient plus the relevant interaction.
sector_coefs <- read_table("sector_coefficients")
contrasts <- read_table("sector_contrasts")
sector_tests <- read_table("sector_tests")
for (fit in split(sector_coefs, interaction(sector_coefs$model, sector_coefs$outcome, sector_coefs$version, drop = TRUE))) {
  z <- contrasts[contrasts$model == fit$model[1] & contrasts$outcome == fit$outcome[1] &
                   contrasts$version == fit$version[1], ]
  b <- setNames(fit$B, fit$term)
  reference_group <- if (fit$model[1] == "sector") "Public" else "Other occupations"
  expected <- rep(b["rural_origin"], nrow(z))
  for (i in which(z$group != reference_group)) {
    term <- if (fit$model[1] == "sector") paste0("rural_origin:sector_f", z$group[i]) else "rural_origin:teaching"
    expected[i] <- expected[i] + b[term]
  }
  same(z$B, expected, "Sector contrasts")
}
for (method in c("classical", "HC3", "province")) {
  df2 <- if (method == "province") sector_tests$provinces - 1 else sector_tests$residual_df
  same(sector_tests[[paste0("p_", method)]],
       pf(sector_tests[[paste0("F_", method)]], sector_tests$df1, df2, lower.tail = FALSE),
       paste("Sector joint F", method))
}

# adjustment supplement: control attribution and six paths to Model 3
adjust_table <- function(name) read.csv(file.path("output/supplementary/origin-adjustment", paste0(name, ".csv")))
am <- adjust_table("models")
at <- adjust_table("decomposition_terms")
ag <- adjust_table("decomposition_groups")
ap <- adjust_table("sequences")
ao <- adjust_table("order_summary")
b <- setNames(m3$B, m3$term)
products <- -b[at$term] * (at$rural_mean - at$urban_mean)
same(at$B_full, unname(b[at$term]), "Adjustment slopes from Model 3")
same(at$increase, unname(products), "Adjustment term products")
for (group in c("education", "parental", "demographics"))
  same(ag$increase[ag$block == group], sum(products[at$block == group]), "Adjustment group attribution")
b0 <- am$B[am$model == "none"]
b1 <- am$B[am$model == "all"]
same(sum(products), b1 - b0, "Adjustment identity")
same(c(b1, am$SE_HC3[am$model == "all"]),
     c(b["rural_origin"], m3$SE_HC3[m3$term == "rural_origin"]), "Adjustment matches Model 3")
same(am$N, rep(N, nrow(am)), "Adjustment common sample size")
paths <- split(ap, ap$order)
groups <- c("education", "parental", "demographics")
stopifnot(length(paths) == 6, !anyDuplicated(vapply(paths, function(z) paste(z$added, collapse = ">"), "")))
for (path in paths) {
  expected <- b0
  for (j in 1:3) {
    included <- groups[groups %in% path$added[1:j]]
    model <- if (j == 3) "all" else paste(included, collapse = "_")
    expected <- c(expected, am$B[am$model == model])
  }
  same(as.matrix(path[c("before", "after", "increase")]),
       cbind(head(expected, -1), tail(expected, -1), diff(expected)),
       "Adjustment path uses fitted coefficients and their increments")
}
for (group in groups)
  same(ao$order_average[ao$block == group], mean(ap$increase[ap$added == group]), "Average entry-order increment")

# Geographic supplement starts from Model 3.
geo <- read.csv("output/supplementary/geographic-sorting/sorting_test.csv")
z <- geo[geo$model == "Model 3 (full sample)", ]
same(c(z$N, z$B_rural, z$SE_HC3),
     c(N, m3$B[m3$term == "rural_origin"], m3$SE_HC3[m3$term == "rural_origin"]), "Geographic baseline")
same(geo$N[geo$model == "Model 3 (sorting sample)"],
     geo$N[geo$model == "Model 3 + current residence"], "Geographic matched sample")

cat("Saved-table checks passed.\n")
