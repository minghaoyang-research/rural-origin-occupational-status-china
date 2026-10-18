# helpers shared between the analysis and the check scripts

education_tier <- function(code, text) {
  out <- rep(NA_real_, length(code))
  out[code %in% c(9, 10)] <- 1
  out[code %in% c(11, 12)] <- 2
  out[code %in% 13] <- 3
  # A7AA: one 大专 response; 电大(成人教育) and 党校毕业 left unclassified
  out[is.na(code) & trimws(text) %in% "\u5927\u4e13"] <- 1
  out
}

completed_he <- function(tier, status) {
  !is.na(tier) & status %in% 4
}

recode_origin <- function(code) {
  out <- rep(NA_real_, length(code))
  out[code %in% c(1, 2)] <- 1
  out[code %in% c(3, 4, 5)] <- 0
  out
}

recode_parent_education <- function(x) {
  out <- rep(NA_real_, length(x))
  out[x %in% 1] <- 0
  out[x %in% 2] <- 2
  out[x %in% 3] <- 6
  out[x %in% 4] <- 9
  out[x %in% c(5, 6, 7, 8)] <- 12
  out[x %in% c(9, 10)] <- 15
  out[x %in% c(11, 12)] <- 16
  out[x %in% 13] <- 19
  # Other (14) mixes educational backgrounds; leave it missing with 98/99.
  out
}

parent_education_max <- function(father, mother) {
  pmax(father, mother, na.rm = TRUE)
}

# 0 is Armed Forces; keep the leading zeros
pad_isco <- function(x) {
  out <- rep(NA_character_, length(x))
  ok <- is.finite(x) & x >= 0 & x < 10000
  if (any(x[ok] != trunc(x[ok]))) stop("Non-integer ISCO code")
  out[ok] <- sprintf("%04d", as.integer(x[ok]))
  out
}

classify_isco_level <- function(x, levels) {
  out <- rep(NA_character_, length(x))
  for (level in c("unit", "minor", "sub_major", "major")) {
    codes <- levels$code[levels$level == level]
    padded <- paste0(codes, strrep("0", 4L - nchar(codes)))
    out[is.na(out) & x %in% padded] <- level
  }
  if (anyNA(out)) stop("Unknown ISCO codes: ", paste(unique(x[is.na(out)]), collapse = ", "))
  out
}

choose_occupation <- function(current, previous) {
  current <- pad_isco(current)
  previous <- pad_isco(previous)
  code <- current
  source <- ifelse(is.na(current), "none", "current_A59")
  use_previous <- is.na(current) & !is.na(previous)
  code[use_previous] <- previous[use_previous]
  source[use_previous] <- "last_A60"
  data.frame(isco4 = code, occ_source = source)
}

# 9999996 = "above the questionnaire range" (no exact amount given)
known_income <- function(x) {
  !is.na(x) & x >= 0 & x < 9999996
}

# Employer sector from A59J organisation type and A59K ownership.
# A59K is skipped for A59J = 1, 5 and 6, so ownership only matters for enterprises (A59J = 2).
# Unknown organisation type, or an enterprise with unknown ownership, is left missing.
employer_sector <- function(organisation, ownership) {
  organisation <- as.numeric(organisation)
  ownership <- as.numeric(ownership)
  out <- rep(NA_character_, length(organisation))
  out[organisation %in% c(1, 3, 6)] <- "Public"
  out[organisation %in% 2 & ownership %in% 1] <- "State enterprise"
  out[organisation %in% 2 & ownership %in% 2:6] <- "Non-state enterprise and other"
  out[organisation %in% c(4, 5, 7)] <- "Non-state enterprise and other"
  out
}

# province-clustered SEs; t intervals with G-1 df
province_table <- function(fit, data) {
  used <- model.frame(fit)
  rows <- match(rownames(used), rownames(data))
  matched <- model.frame(formula(fit), data = data[rows, , drop = FALSE],
                         na.action = na.pass, xlev = fit$xlevels)
  if (!isTRUE(all.equal(used[names(matched)], matched, tolerance = 0, check.attributes = FALSE)))
    stop("Province data do not match the fitted rows")
  province <- as.numeric(data$s41[rows])
  G <- length(unique(province))
  stopifnot(all(is.finite(province)), G > 1)
  V <- sandwich::vcovCL(fit, cluster = province, type = "HC1")
  b <- coef(fit)
  se <- sqrt(diag(V))[names(b)]
  data.frame(term = names(b), N = nobs(fit), provinces = G,
             B = unname(b), SE_province = unname(se),
             p_province = 2 * pt(abs(b / se), G - 1, lower.tail = FALSE),
             CI_low = b - qt(.975, G - 1) * se,
             CI_high = b + qt(.975, G - 1) * se, row.names = NULL)
}

# one province-bootstrap draw for the adjustment supplement
origin_adjustment_draw <- function(data, w, formula, blocks) {
  controls <- unname(unlist(blocks))
  y <- data$isei
  R <- data$rural_origin
  boot_data <- data
  boot_data$adjustment_weight <- w
  fit <- lm(formula, data = boot_data, weights = adjustment_weight, na.action = na.fail,
            singular.ok = FALSE)
  b <- coef(fit)
  delta <- setNames(numeric(length(controls)), controls)
  for (name in controls) {
    z <- data[[name]]
    delta[name] <- weighted.mean(z[R == 1], w[R == 1]) - weighted.mean(z[R == 0], w[R == 0])
  }
  cterm <- -b[controls] * delta
  cgroup <- setNames(numeric(length(blocks)), names(blocks))
  for (name in names(blocks)) cgroup[name] <- sum(cterm[blocks[[name]]])
  b0 <- weighted.mean(y[R == 1], w[R == 1]) - weighted.mean(y[R == 0], w[R == 0])
  c(raw = b0, adjusted = unname(b["rural_origin"]), increase = sum(cgroup), cgroup,
    education_minus_parental = unname(cgroup["education"] - cgroup["parental"]),
    education_minus_demographics = unname(cgroup["education"] - cgroup["demographics"]))
}
