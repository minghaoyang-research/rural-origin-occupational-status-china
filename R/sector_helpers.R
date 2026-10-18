# sector model fitting and inference tables (used in 08_sector_split)

fit_sector_pair <- function(spec, outcome, province, weighted) {
  data <- spec$data
  formulas <- list(full = spec$full, reduced = spec$reduced)
  fits <- list()
  for (name in names(formulas)) {
    formula <- update(formulas[[name]], paste(outcome, "~ ."))
    if (province) formula <- update(formula, . ~ . + factor(s41))
    if (weighted) {
      fits[[name]] <- lm(formula, data = data, weights = weight, na.action = na.fail, singular.ok = FALSE)
    } else {
      fits[[name]] <- lm(formula, data = data, na.action = na.fail, singular.ok = FALSE)
    }
  }
  full <- fits$full
  if (any(1 - hatvalues(full) <= sqrt(.Machine$double.eps)))
    stop("HC3 is undefined at leverage one")
  province_id <- as.numeric(data$s41)
  G <- length(unique(province_id))
  stopifnot(all(is.finite(province_id)), G > 1)
  V_hc3 <- sandwich::vcovHC(full, type = "HC3")
  # province-clustered HC1
  V_province <- sandwich::vcovCL(full, cluster = province_id, type = "HC1")
  c(fits, list(V_hc3 = V_hc3, V_province = V_province, provinces = G))
}

# coefficient and group intervals
sector_inference <- function(b, hc3, province, df, G) {
  result <- data.frame(B = unname(b), SE_HC3 = unname(hc3),
    p_HC3 = 2 * pt(abs(b / hc3), df, lower.tail = FALSE),
    CI_low = b - qt(.975, df) * hc3, CI_high = b + qt(.975, df) * hc3,
    provinces = G, SE_province = unname(province),
    p_province = 2 * pt(abs(b / province), G - 1, lower.tail = FALSE),
    province_CI_low = b - qt(.975, G - 1) * province,
    province_CI_high = b + qt(.975, G - 1) * province, row.names = NULL)
  result
}

# rural coefficient plus the interaction for each group
sector_contrast_table <- function(estimate, interactions, groups) {
  b <- coef(estimate$full)
  df <- df.residual(estimate$full)
  G <- estimate$provinces
  V3 <- estimate$V_hc3
  VC <- estimate$V_province
  tab <- NULL
  for (i in seq_along(groups)) {
    terms <- "rural_origin"
    var_hc3 <- V3["rural_origin", "rural_origin"]
    var_province <- VC["rural_origin", "rural_origin"]
    if (i > 1) {
      term <- interactions[i - 1]
      terms <- c(terms, term)
      var_hc3 <- var_hc3 + V3[term, term] + 2 * V3["rural_origin", term]
      var_province <- var_province + VC[term, term] + 2 * VC["rural_origin", term]
    }
    B <- sum(b[terms])
    row <- sector_inference(B, sqrt(var_hc3), sqrt(var_province), df, G)
    tab <- rbind(tab, cbind(group = groups[i], N = nobs(estimate$full), residual_df = df, row))
  }
  tab
}

sector_result_tables <- function(record) {
  estimate <- record$estimate
  full <- estimate$full
  b <- coef(full)
  cm <- coef(summary(full))[names(b), , drop = FALSE]
  hc <- sqrt(diag(estimate$V_hc3))[names(b)]
  cl <- sqrt(diag(estimate$V_province))[names(b)]
  df <- df.residual(full)
  G <- estimate$provinces
  metadata <- data.frame(outcome = record$outcome, model = record$model,
                         weighted = record$weighted, province_FE = record$province_FE)
  coefficients <- cbind(version = record$version, term = names(b), N = nobs(full),
    B = unname(b), SE_classical = cm[, 2], p_classical = cm[, 4],
    sector_inference(b, hc, cl, df, G)[-1])
  coefficients <- coefficients[!grepl("^factor\\(s41\\)", coefficients$term), ]
  coefficients <- cbind(metadata, residual_df = df, coefficients)
  contrasts <- cbind(metadata[c("outcome", "model")], version = record$version,
    metadata[c("weighted", "province_FE")],
    sector_contrast_table(estimate, record$interactions, record$groups))

  classical <- anova(estimate$reduced, full)
  hc3 <- lmtest::waldtest(estimate$reduced, full, vcov = estimate$V_hc3, test = "F")
  clustered <- lmtest::waldtest(estimate$reduced, full, vcov = estimate$V_province, test = "F")
  q <- abs(clustered$Df[2])
  tests <- cbind(metadata, data.frame(N = nobs(full), residual_df = df, df1 = q,
    max_leverage = max(hatvalues(full)), F_classical = classical$F[2],
    p_classical = classical$`Pr(>F)`[2], F_HC3 = hc3$F[2], p_HC3 = hc3$`Pr(>F)`[2],
    F_province = clustered$F[2],
    p_province = pf(clustered$F[2], q, G - 1, lower.tail = FALSE), provinces = G))
  list(coefficients = coefficients, contrasts = contrasts, tests = tests)
}
