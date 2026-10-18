# Coding rules and calculations that need fitted data.

source("R/analysis_helpers.R")
expect_error <- function(expr) stopifnot(inherits(try(expr, silent = TRUE), "try-error"))

stopifnot(identical(pad_isco(c(0, 110, 2341, 9999)), c("0000", "0110", "2341", "9999")),
          all(is.na(pad_isco(c(NA, -1, 10000)))))
expect_error(pad_isco(1234.8))

levels <- read.csv("data/reference/isco08_levels.csv", colClasses = "character")
stopifnot(identical(classify_isco_level(c("0000", "0100", "0310", "1120", "2330", "2300", "2350"), levels),
                    c("major", "sub_major", "unit", "unit", "unit", "sub_major", "minor")))

stopifnot(identical(recode_parent_education(1:14),
                    c(0, 2, 6, 9, 12, 12, 12, 12, 15, 15, 16, 16, 19, NA_real_)),
          all(is.na(recode_parent_education(c(NA, 98, 99)))))

stopifnot(identical(parent_education_max(c(9, 16, NA, NA), c(6, NA, 16, NA)),
                    c(9, 16, 16, NA_real_)))

tier <- education_tier(c(9, 10, 11, 12, 13, 8, 14, 98, 99, NA, NA, NA, NA, 11),
                       c(rep("", 9), " \u5927\u4e13 ", "\u7535\u5927(\u6210\u4eba\u6559\u80b2)", "\u515a\u6821\u6bd5\u4e1a", NA, "\u5927\u4e13"))
stopifnot(identical(tier, c(1, 1, 2, 2, 3, rep(NA_real_, 4), 1, NA_real_, NA_real_, NA_real_, 2)),
          identical(completed_he(rep(1, 7), c(1, 2, 3, 4, 98, 99, NA)),
                    c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE)),
          identical(recode_origin(c(1:5, 98, 99, NA, 0, -1)),
                    c(1, 1, 0, 0, 0, rep(NA_real_, 5))))

occupation <- choose_occupation(c(2341, NA, -1, 0, NA, -1, 10000, NA),
                                 c(2330, 2330, 2342, 2330, 0, -2, 2351, NA))
stopifnot(identical(occupation$isco4,
                    c("2341", "2330", "2342", "0000", "0000", NA, "2351", NA)),
          identical(occupation$occ_source,
                    c("current_A59", "last_A60", "last_A60", "current_A59", "last_A60",
                      "none", "last_A60", "none")))

income <- c(0, 1, 50000, 9999995, 9999996:9999999, NA, -1)
stopifnot(identical(known_income(income), c(rep(TRUE, 4), rep(FALSE, 6))))

# A59K is skipped for A59J = 1, 5 and 6; enterprises need a known ownership.
stopifnot(identical(employer_sector(c(1, 3, 6, 2, 2, 2, 2, 2, 4, 5, 7, 98, NA),
                                    c(NA, NA, NA, 1, 2, 6, 98, NA, NA, NA, 3, 1, 1)),
                    c("Public", "Public", "Public", "State enterprise",
                      "Non-state enterprise and other", "Non-state enterprise and other",
                      NA, NA, "Non-state enterprise and other", "Non-state enterprise and other",
                      "Non-state enterprise and other", NA, NA)))

trial <- data.frame(
  y = c(3, 5, 2, 8, 4, 7, 3, 9, 5, 10, 4, 8, 6, 9, 5, 11, 7, 12, 6, 10, NA, NA, NA, NA),
  x = rep(c(1, 3, 2, 4), 6), z = rep(1:6, each = 4),
  weight = rep(c(.5, 1, 2, 1.5), 6), s41 = rep(1:6, each = 4))
rownames(trial) <- paste0("person", seq_len(nrow(trial)))
fits <- list(lm(y ~ x + z, data = trial), lm(y ~ x + z, data = trial, weights = weight),
             lm(y ~ x + z, data = trial, subset = x != 4))

for (fit in fits) {
  tab <- province_table(fit, trial[nrow(trial):1, ])
  rows <- match(rownames(model.frame(fit)), rownames(trial))
  se <- sqrt(diag(sandwich::vcovCL(fit, cluster = trial$s41[rows], type = "HC1")))
  stopifnot(isTRUE(all.equal(tab$SE_province, unname(se))))
}

# row labels reused for different respondents
wrong <- trial[order(trial$x, trial$z), ]
rownames(wrong) <- rownames(trial)
expect_error(province_table(fits[[1]], wrong))

# include the covariance between the origin and interaction terms
source("R/sector_helpers.R")
set.seed(817)
sector_trial <- data.frame(y = rnorm(120), rural_origin = rep(rep(0:1, each = 10), 6),
                          sector_f = factor(rep(c("Public", "State", "Other"), each = 40),
                                            levels = c("Public", "State", "Other")),
                          x = rnorm(120), s41 = rep(1:10, 12), weight = runif(120, .5, 2))
sector_trial$teaching <- as.numeric(sector_trial$sector_f == "Public")
for (moderator in c("sector_f", "teaching")) {
  sp <- list(data = sector_trial,
    full = as.formula(paste("~ x + rural_origin *", moderator)),
    reduced = as.formula(paste("~ x + rural_origin +", moderator)),
    interactions = if (moderator == "sector_f") paste0("rural_origin:sector_f", c("State", "Other")) else "rural_origin:teaching",
    groups = if (moderator == "sector_f") c("Public", "State", "Other") else c("Other occupations", "Teaching"))
  for (version in c("base", "province_weighted")) {
    weighted <- version %in% c("weighted", "province_weighted")
    province <- version %in% c("province", "province_weighted")
    estimate <- fit_sector_pair(sp, "y", province, weighted)
    contrasts <- sector_contrast_table(estimate, sp$interactions, sp$groups)
    fit <- estimate$full
    V3 <- sandwich::vcovHC(fit, type = "HC3")
    VC <- sandwich::vcovCL(fit, cluster = sector_trial$s41, type = "HC1")
    # covariance for the rural-minus-urban prediction difference
    for (i in seq_along(sp$groups)) {
      grid <- sector_trial[rep(1, 2), ]
      grid$rural_origin <- 0:1
      if (moderator == "sector_f") grid$sector_f <- factor(rep(sp$groups[i], 2), levels = sp$groups) else
        grid$teaching <- i - 1
      X <- model.matrix(delete.response(terms(fit)), grid, xlev = fit$xlevels)
      L <- X[2, ] - X[1, ]
      stopifnot(abs(contrasts$SE_HC3[i] - sqrt(drop(L %*% V3 %*% L))) < 1e-10,
                abs(contrasts$SE_province[i] - sqrt(drop(L %*% VC %*% L))) < 1e-10)
    }
  }
}
# a province indicator for one respondent makes HC3 undefined
bad <- sp
bad$data$s41[1] <- 99
expect_error(fit_sector_pair(bad, "y", TRUE, FALSE))

# R/09 frequency weights against physically repeated province rows
set.seed(161)
adj <- data.frame(isei = rnorm(120, 50, 10), rural_origin = rep(0:1, 60),
                  tier = sample(1:3, 120, replace = TRUE), par_edu_yrs = rnorm(120, 9, 3),
                  female = rbinom(120, 1, .5), age = sample(25:60, 120, replace = TRUE),
                  province = rep(1:6, each = 20))
adj$edu_bachelor <- as.numeric(adj$tier == 2)
adj$edu_postgrad <- as.numeric(adj$tier == 3)
blocks <- list(education = c("edu_bachelor", "edu_postgrad"), parental = "par_edu_yrs",
               demographics = c("female", "age"))
form <- isei ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin
multiplicities <- rbind(c(2, 0, 1, 1, 0, 2), c(0, 1, 2, 0, 2, 1), c(1, 2, 0, 2, 1, 0))
for (i in 1:nrow(multiplicities)) {
  w <- multiplicities[i, adj$province]
  actual <- origin_adjustment_draw(adj, w, form, blocks)
  expanded <- adj[rep(seq_len(nrow(adj)), times = w), ]
  full <- lm(form, data = expanded)
  short <- lm(isei ~ rural_origin, data = expanded)
  component <- numeric(3)
  for (j in 1:3) {
    terms <- blocks[[j]]
    slopes <- sapply(terms, function(term)
      coef(lm(reformulate("rural_origin", term), data = expanded))["rural_origin"])
    component[j] <- -sum(coef(full)[terms] * slopes)
  }
  b0 <- unname(coef(short)["rural_origin"])
  b1 <- unname(coef(full)["rural_origin"])
  expected <- c(b0, b1, b1 - b0, component, component[1] - component[2:3])
  stopifnot(max(abs(actual - expected)) < 1e-8)
}

cat("Synthetic-data helper checks passed.\n")
