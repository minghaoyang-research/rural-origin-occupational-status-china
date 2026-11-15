# teaching by age, sex and route; teaching, occupation and employer added to Model 3

source("R/03_construct_isei.R")
d <- as.data.frame(analysis_sample)
out <- "output/supplementary/teaching-composition"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
save_table <- function(x, name) write.csv(x, file.path(out, paste0(name, ".csv")), row.names = FALSE)

d$teaching <- as.numeric(substr(d$isco4, 1, 2) == "23")
d$teaching_pct <- 100 * d$teaching

# HC3 estimate and interval for a sum of coefficients
hc3 <- function(fit, terms = "rural_origin") {
  b <- sum(coef(fit)[terms])
  se <- sqrt(sum(sandwich::vcovHC(fit, type = "HC3")[terms, terms]))
  df <- df.residual(fit)
  data.frame(B = b, SE_HC3 = se, CI_low = b - qt(.975, df) * se, CI_high = b + qt(.975, df) * se)
}
hc3_test <- function(reduced, full)
  lmtest::waldtest(reduced, full, vcov = sandwich::vcovHC(full, type = "HC3"), test = "F")$`Pr(>F)`[2]

# sample description by origin
describe <- function(z) c(N = nrow(z), isei_mean = mean(z$isei), isei_sd = sd(z$isei),
                          age_mean = mean(z$age), age_sd = sd(z$age),
                          parent_education_mean = mean(z$par_edu_yrs), parent_education_sd = sd(z$par_edu_yrs),
                          female_percent = 100 * mean(z$female),
                          junior_college_percent = 100 * mean(z$edu_lvl == 1),
                          bachelor_percent = 100 * mean(z$edu_lvl == 2),
                          postgraduate_percent = 100 * mean(z$edu_lvl == 3))
descriptives <- data.frame(All = describe(d), Urban = describe(d[d$rural_origin == 0, ]),
                           Rural = describe(d[d$rural_origin == 1, ]))
save_table(cbind(characteristic = rownames(descriptives), descriptives), "descriptives")
tiers <- chisq.test(table(d$edu_lvl, d$rural_origin))
save_table(data.frame(chi_square = unname(tiers$statistic), df = unname(tiers$parameter), p = tiers$p.value),
           "tier_origin_test")

# rural difference in teaching by age and sex
d$age35 <- as.numeric(d$age >= 35 & d$age <= 44)
d$age45 <- as.numeric(d$age >= 45)
d$age40 <- as.numeric(d$age >= 40)
d$rural_x_age35 <- d$rural_origin * d$age35
d$rural_x_age45 <- d$rural_origin * d$age45
d$rural_x_age40 <- d$rural_origin * d$age40
d$rural_x_age <- d$rural_origin * (d$age - 40)
d$rural_x_female <- d$rural_origin * d$female

teach <- lm(teaching_pct ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin, data = d)
bands_main <- update(teach, . ~ . + age35 + age45)
bands <- update(bands_main, . ~ . + rural_x_age35 + rural_x_age45)
halves_main <- update(teach, . ~ . + age40)
halves <- update(halves_main, . ~ . + rural_x_age40)
linear <- update(teach, . ~ . + rural_x_age)
sexes <- update(teach, . ~ . + rural_x_female)

age_sex <- rbind(
  cbind(model = "Three age bands", group = c("25-34", "35-44", "45-60"),
        rbind(hc3(bands), hc3(bands, c("rural_origin", "rural_x_age35")), hc3(bands, c("rural_origin", "rural_x_age45"))),
        interaction_p_HC3 = hc3_test(bands_main, bands)),
  cbind(model = "Two age bands", group = c("25-39", "40-60"),
        rbind(hc3(halves), hc3(halves, c("rural_origin", "rural_x_age40"))),
        interaction_p_HC3 = hc3_test(halves_main, halves)),
  cbind(model = "Age in years", group = "Change per year", hc3(linear, "rural_x_age"),
        interaction_p_HC3 = hc3_test(teach, linear)),
  cbind(model = "Sex", group = c("Men", "Women"),
        rbind(hc3(sexes), hc3(sexes, c("rural_origin", "rural_x_female"))),
        interaction_p_HC3 = hc3_test(teach, sexes))
)
save_table(age_sex, "teaching_by_age_sex")

# province bootstrap on the saved draws
draws <- province_draws()
# coefficients of a fitted model under frequency weights
reweight <- function(fit) {
  X <- model.matrix(fit)
  y <- model.response(model.frame(fit))
  function(w) lm.wfit(X[w > 0, , drop = FALSE], y[w > 0], w[w > 0])$coefficients
}
# percentile intervals; stat() returns named statistics for one draw
percentile <- function(data, stat) {
  province <- match(as.numeric(data$s41), as.numeric(colnames(draws)))
  t(apply(apply(draws, 1, function(m) stat(m[province])), 1, quantile, probs = c(.025, .975)))
}

# adult and regular highest awards, junior college and bachelor
route <- d[d$a7a_num %in% c(9, 10, 11, 12), ]
route$adult <- as.numeric(route$a7a_num %in% c(9, 11))
route$rural_x_adult <- route$rural_origin * route$adult
route_fit <- lm(teaching_pct ~ edu_bachelor + female + age + par_edu_yrs + rural_origin + adult + rural_x_adult,
                data = route)
refit <- reweight(route_fit)
route_boot <- percentile(route, function(w) {
  b <- refit(w)
  c(Adult = b[["rural_origin"]] + b[["rural_x_adult"]], Regular = b[["rural_origin"]])
})
route_contrasts <- cbind(
  route = c("Adult", "Regular", "Adult minus regular"), N = nobs(route_fit),
  rbind(hc3(route_fit, c("rural_origin", "rural_x_adult")), hc3(route_fit), hc3(route_fit, "rural_x_adult")),
  percentile_low = c(route_boot[, 1], NA), percentile_high = c(route_boot[, 2], NA))
save_table(route_contrasts, "route_contrasts")

# current workers with positive 2016 labour income
income <- as.numeric(d$a8b)
inc <- d[d$occ_source == "current_A59" & known_income(income) & income > 0, ]
inc$log_income <- log(as.numeric(inc$a8b))
controls <- c("edu_bachelor", "edu_postgrad", "female", "age", "par_edu_yrs", "rural_origin")

# Model 3 with and without the teaching indicator
teaching_indicator <- NULL
specs <- list(list(sample = "Main", data = d, outcome = "isei", province = FALSE),
              list(sample = "Income", data = inc, outcome = "isei", province = FALSE),
              list(sample = "Income", data = inc, outcome = "log_income", province = FALSE),
              list(sample = "Income", data = inc, outcome = "isei", province = TRUE),
              list(sample = "Income", data = inc, outcome = "log_income", province = TRUE))
for (spec in specs) {
  z <- spec$data
  base <- lm(reformulate(c(controls, if (spec$province) "factor(s41)"), spec$outcome), data = z)
  expanded <- update(base, . ~ . + teaching)
  refit_base <- reweight(base)
  refit_expanded <- reweight(expanded)
  boot <- percentile(z, function(w) {
    b1 <- refit_expanded(w)[["rural_origin"]]
    c(expanded = b1, change = refit_base(w)[["rural_origin"]] - b1)
  })
  b0 <- coef(base)[["rural_origin"]]
  e <- hc3(expanded)
  teaching_indicator <- rbind(teaching_indicator, data.frame(
    sample = spec$sample, outcome = spec$outcome, province_FE = spec$province, N = nobs(base),
    baseline_B = b0, expanded_B = e$B, expanded_CI_low = e$CI_low, expanded_CI_high = e$CI_high,
    expanded_percentile_low = boot["expanded", 1], expanded_percentile_high = boot["expanded", 2],
    change = b0 - e$B, change_percentile_low = boot["change", 1], change_percentile_high = boot["change", 2]))
}
save_table(teaching_indicator, "teaching_indicator")

# employer and occupation groups for the income sample
inc$sector <- employer_sector(inc$a59j, inc$a59k)
inc$employer <- factor(ifelse(is.na(inc$sector), "Unknown",
                              ifelse(inc$sector != "Public", inc$sector,
                                     ifelse(inc$teaching == 1, "Public teaching", "Other public"))))
# two-digit ISCO groups with fewer than 20 workers are pooled within their one-digit group
two <- substr(inc$isco4, 1, 2)
inc$occupation <- factor(ifelse(as.vector(table(two)[two]) >= 20, two, paste0(substr(two, 1, 1), "x")))
inc$current_rural <- as.numeric(as.numeric(inc$isurban) %in% 2)
groups <- unique(data.frame(two_digit = two, occupation = inc$occupation))
save_table(groups[order(groups$two_digit), ], "occupation_groups")

adjustments <- list("Baseline" = NULL, "Employer" = "employer", "Occupation" = "occupation",
                    "Both" = c("employer", "occupation"),
                    "Both and province" = c("employer", "occupation", "factor(s41)"),
                    "Both, province and residence" = c("employer", "occupation", "factor(s41)", "current_rural"),
                    "One-digit occupation" = "factor(substr(isco4, 1, 1))")
composition <- NULL
composition_change <- NULL
for (outcome in c("isei", "log_income")) {
  fits <- lapply(adjustments, function(a) lm(reformulate(c(controls, a), outcome), data = inc))
  if (outcome == "isei") fits <- fits[1:5]
  for (a in names(fits)) {
    cl <- province_table(fits[[a]], inc)
    cl <- cl[cl$term == "rural_origin", ]
    composition <- rbind(composition, cbind(
      outcome = outcome, adjustment = a, N = nobs(fits[[a]]), hc3(fits[[a]]),
      SE_province = cl$SE_province, province_CI_low = cl$CI_low, province_CI_high = cl$CI_high))
  }
  refit_base <- reweight(fits[["Baseline"]])
  refit_both <- reweight(fits[["Both"]])
  boot <- percentile(inc, function(w) {
    b1 <- refit_both(w)[["rural_origin"]]
    c(adjusted = b1, change = refit_base(w)[["rural_origin"]] - b1)
  })
  b0 <- coef(fits[["Baseline"]])[["rural_origin"]]
  b1 <- coef(fits[["Both"]])[["rural_origin"]]
  composition_change <- rbind(composition_change, data.frame(
    outcome = outcome, baseline_B = b0, both_B = b1, change = b0 - b1,
    percentile_low = boot["change", 1], percentile_high = boot["change", 2]))
}
save_table(composition, "composition")
save_table(composition_change, "composition_change")

cat("Saved teaching and composition tables.\n")
