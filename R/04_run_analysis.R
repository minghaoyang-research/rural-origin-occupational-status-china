# 04 Models, occupation checks and income comparisons

source("R/03_construct_isei.R")

d <- as.data.frame(analysis_sample)
d$bach_x_rural <- d$edu_bachelor * d$rural_origin
d$post_x_rural <- d$edu_postgrad * d$rural_origin
d$bach_x_c2 <- d$edu_bachelor * d$cohort2
d$bach_x_c3 <- d$edu_bachelor * d$cohort3
d$bach_x_c4 <- d$edu_bachelor * d$cohort4
d$post_x_c2 <- d$edu_postgrad * d$cohort2
d$post_x_c3 <- d$edu_postgrad * d$cohort3
d$post_x_c4 <- d$edu_postgrad * d$cohort4

# same respondents for Models 1-7
stopifnot(all(complete.cases(d[c("isei", "edu_bachelor", "edu_postgrad", "female", "age",
                                "par_edu_yrs", "rural_origin", "rural_origin_f",
                                "cohort2", "cohort3", "cohort4")])))

primary_models <- list(
  Model1 = lm(isei ~ edu_bachelor + edu_postgrad + female + age, data = d),
  Model2 = lm(isei ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs, data = d),
  Model3 = lm(isei ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin, data = d),
  Model4 = lm(isei ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin +
                bach_x_rural + post_x_rural, data = d),
  Model5 = lm(isei ~ edu_bachelor + edu_postgrad + female + par_edu_yrs + rural_origin +
                cohort2 + cohort3 + cohort4, data = d),
  Model6 = lm(isei ~ edu_bachelor + edu_postgrad + female + par_edu_yrs + rural_origin +
                cohort2 + cohort3 + cohort4 + bach_x_c2 + bach_x_c3 + bach_x_c4 +
                post_x_c2 + post_x_c3 + post_x_c4, data = d),
  Model7 = lm(isei ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin_f, data = d)
)

vcov_hc3 <- function(fit) sandwich::vcovHC(fit, type = "HC3")
coefficient_table <- function(fit, version, model) {
  b <- coef(fit)
  cm <- coef(summary(fit))
  hc <- sqrt(diag(vcov_hc3(fit)))
  cm <- cm[match(names(b), rownames(cm)), , drop = FALSE]
  hc <- hc[match(names(b), names(hc))]
  critical <- qt(.975, df.residual(fit))
  data.frame(version = version, model = model, term = names(b), N = nobs(fit),
             B = unname(b), SE_classical = cm[, 2], p_classical = cm[, 4],
             SE_HC3 = unname(hc), p_HC3 = 2 * pt(abs(b / hc), df.residual(fit), lower.tail = FALSE),
             CI_low = b - critical * hc, CI_high = b + critical * hc, row.names = NULL)
}

clustered_table <- function(fit, data, version, model = "Model3", keep = names(coef(fit))) {
  tab <- coefficient_table(fit, version, model)
  tab <- tab[tab$term %in% keep, ]
  cl <- province_table(fit, data)
  cl <- cl[match(tab$term, cl$term), c("provinces", "SE_province", "p_province", "CI_low", "CI_high")]
  names(cl)[4:5] <- c("province_CI_low", "province_CI_high")
  cbind(tab, cl)
}
rural_columns <- c("B", "SE_HC3", "p_HC3", "CI_low", "CI_high",
                   "provinces", "SE_province", "p_province", "province_CI_low", "province_CI_high")
primary_coefs <- lapply(names(primary_models), function(m) coefficient_table(primary_models[[m]], "primary", m))

model_fit <- data.frame(model = names(primary_models), N = sapply(primary_models, nobs),
                        R2 = sapply(primary_models, function(m) summary(m)$r.squared),
                        adjusted_R2 = sapply(primary_models, function(m) summary(m)$adj.r.squared))

composition <- rbind(
  data.frame(measure = "education", category = c("Junior college", "Bachelor", "Postgraduate"),
             N = as.integer(table(d$edu_lvl))),
  data.frame(measure = "origin", category = c("Urban", "Rural"), N = as.integer(table(d$rural_origin))),
  data.frame(measure = "sex", category = c("Male", "Female"), N = as.integer(table(d$female))),
  data.frame(measure = "occupation", category = c("Current A59", "Most recent A60"), N = as.integer(table(d$occ_source))),
  data.frame(measure = "A58 among A60 respondents", category = c("Currently farming", "Not currently working"),
             N = c(sum(d$occ_source == "last_A60" & as.numeric(d$a58) %in% 2),
                   sum(d$occ_source == "last_A60" & as.numeric(d$a58) %in% 5)))
)

# reported HE at ages 25-60, before completion and the remaining sample filters
reported_he <- dat[dat$sample_education & !is.na(dat$age) & dat$age >= 25 & dat$age <= 60, ]
completion <- factor(reported_he$a7b_num, levels = c(1, 2, 3, 4, 98, 99),
                     labels = c("Studying", "Dropped out", "Attended without graduating", "Graduated",
                                "Do not know", "Refused"))
completion_status <- list()
for (status in levels(completion)) {
  rows <- completion %in% status
  completion_status[[status]] <- data.frame(
    status = status, N = sum(rows),
    rural_N = sum(rows & reported_he$rural_origin %in% 1),
    urban_N = sum(rows & reported_he$rural_origin %in% 0),
    origin_missing_N = sum(rows & is.na(reported_he$rural_origin)),
    nonfarm_code_N = sum(rows & !is.na(reported_he$isco4)),
    teaching_code_N = sum(rows & substr(reported_he$isco4, 1, 2) %in% "23"))
}
completion_status <- do.call(rbind, completion_status)
stopifnot(!anyNA(completion))
rownames(completion_status) <- NULL
education_origin <- as.data.frame(table(education = d$edu_lvl, origin = d$rural_origin))
education_origin$mean_isei <- NA_real_
education_origin$sd_isei <- NA_real_
for (i in seq_len(nrow(education_origin))) {
  cell <- d$edu_lvl == education_origin$education[i] & d$rural_origin == education_origin$origin[i]
  education_origin$mean_isei[i] <- mean(d$isei[cell])
  education_origin$sd_isei[i] <- sd(d$isei[cell])
}
education_origin$education_label <- c("Junior college", "Bachelor", "Postgraduate")[as.integer(education_origin$education)]
education_origin$origin_label <- c("Urban", "Rural")[as.integer(education_origin$origin)]

origin_summary <- data.frame(origin = c("Urban", "Rural"), N = as.integer(table(d$rural_origin)),
                             mean_parent_education = as.numeric(tapply(d$par_edu_yrs, d$rural_origin, mean)),
                             mean_isei = as.numeric(tapply(d$isei, d$rural_origin, mean)))

cohort_education <- as.data.frame(table(cohort = d$cohort, education = d$edu_lvl))
cohort_education$cohort_label <- c("1957-64", "1965-74", "1975-84", "1985-92")[as.integer(cohort_education$cohort)]
cohort_education$education_label <- c("Junior college", "Bachelor", "Postgraduate")[as.integer(cohort_education$education)]

# refit Model 3 with overview ISEI
overview <- d
overview$isei <- overview$isei_overview
ov_m3 <- update(primary_models$Model3, data = overview)

# SIOPS prestige
code_map$siops <- NA_real_
for (i in seq_len(nrow(code_map))) {
  code_map$siops[i] <- as.numeric(ISCO08ConveRsions::isco08tosiops08(code_map$isco4[i]))
}
d$siops <- code_map$siops[match(d$isco4, code_map$isco4)]
stopifnot(all(is.finite(d$siops)))
siops_m3 <- update(primary_models$Model3, siops ~ ., data = d)

scale_comparison <- rbind(
  coefficient_table(primary_models$Model3, "ISEI syntax", "Model3"),
  coefficient_table(ov_m3, "ISEI overview", "Model3"),
  coefficient_table(siops_m3, "SIOPS", "Model3")
)
scale_comparison <- scale_comparison[scale_comparison$term == "rural_origin",
  c("version", "N", "B", "SE_HC3", "p_HC3", "CI_low", "CI_high")]
names(scale_comparison)[1] <- "scale"
scale_comparison$outcome_mean <- c(mean(d$isei), mean(d$isei_overview), mean(d$siops))
scale_comparison$outcome_sd <- c(sd(d$isei), sd(d$isei_overview), sd(d$siops))
for (column in c("B", "SE_HC3", "CI_low", "CI_high"))
  scale_comparison[[paste0(column, "_SD")]] <- scale_comparison[[column]] / scale_comparison$outcome_sd

d_current <- d[d$occ_source == "current_A59", ]
current_m3 <- update(primary_models$Model3, data = d_current)

exclude_other_m3 <- update(primary_models$Model3,
                           data = d[!(d$a89b_num %in% 14 | d$a90b_num %in% 14), ])

weighted_m3 <- update(primary_models$Model3, data = d, weights = weight)

# restriction to explicit ISCO unit groups
d_unit <- d[d$coding_level == "unit", ]
unit_m3 <- update(primary_models$Model3, data = d_unit)
unit_ov <- update(primary_models$Model3, isei_overview ~ ., data = d_unit)
# totals by coding level
coding_group <- ifelse(d$coding_level == "unit", "unit", "broader")
occupation_coding <- do.call(rbind, lapply(c("unit", "broader"), function(group) {
  rows <- coding_group == group
  data.frame(coding_group = group, code_count = length(unique(d$isco4[rows])),
             N = sum(rows), rural_N = sum(rows & d$rural_origin == 1),
             urban_N = sum(rows & d$rural_origin == 0),
             current_N = sum(rows & d$occ_source == "current_A59"),
             last_N = sum(rows & d$occ_source == "last_A60"))
}))

# adult and regular qualifications
d$education_route <- factor(d$a7a_num, levels = c(10, 9, 12, 11, 13),
                            labels = c("Regular junior college", "Adult junior college",
                                       "Regular bachelor", "Adult bachelor", "Postgraduate"))
routes_m3 <- lm(isei ~ education_route + female + age + par_edu_yrs + rural_origin,
                data = d[!is.na(d$education_route), ])
regular_m3 <- update(primary_models$Model3, data = d[d$a7a_num %in% c(10, 12, 13), ])
d$origin3 <- factor(ifelse(d$a27h_num == 1, "Village", ifelse(d$a27h_num == 2, "Township", "Urban")),
                    levels = c("Urban", "Village", "Township"))
township_m3 <- lm(isei ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + origin3, data = d)

province_results <- rbind(
  cbind(specification = "unweighted", province_table(primary_models$Model3, d)),
  cbind(specification = "weighted", province_table(weighted_m3, d))
)

# rural coefficient: full/current sample, weights and interview-province controls
isei_province_models <- list(
  full_unweighted = primary_models$Model3,
  full_unweighted_province = update(primary_models$Model3, . ~ . + factor(s41),
                                    data = d, na.action = na.fail),
  full_weighted = weighted_m3,
  full_weighted_province = update(weighted_m3, . ~ . + factor(s41),
                                  data = d, na.action = na.fail),
  current_unweighted = current_m3,
  current_unweighted_province = update(current_m3, . ~ . + factor(s41),
                                       data = d_current, na.action = na.fail),
  current_weighted = update(current_m3, data = d_current, weights = weight,
                            na.action = na.fail),
  current_weighted_province = update(current_m3, . ~ . + factor(s41),
                                     data = d_current, weights = weight, na.action = na.fail)
)
isei_province <- do.call(rbind, lapply(names(isei_province_models), function(version) {
  fit <- isei_province_models[[version]]
  sample <- if (startsWith(version, "full_")) "full" else "current"
  sample_data <- if (sample == "full") d else d_current
  tab <- clustered_table(fit, sample_data, version, keep = "rural_origin")
  cbind(data.frame(version = version, sample = sample, weighted = !is.null(fit$weights),
                   province_FE = "factor(s41)" %in% attr(terms(fit), "term.labels"), N = nobs(fit),
                   residual_df = df.residual(fit)), tab[rural_columns])
}))
rownames(isei_province) <- NULL

# Rural-minus-urban differences from Model 4
fit <- primary_models$Model4
b <- coef(fit); V <- vcov_hc3(fit)
B <- unname(c(b["rural_origin"], b["rural_origin"] + b["bach_x_rural"],
              b["rural_origin"] + b["post_x_rural"]))
se <- sqrt(c(V["rural_origin", "rural_origin"],
             V["rural_origin", "rural_origin"] + V["bach_x_rural", "bach_x_rural"] +
               2 * V["rural_origin", "bach_x_rural"],
             V["rural_origin", "rural_origin"] + V["post_x_rural", "post_x_rural"] +
               2 * V["rural_origin", "post_x_rural"]))
within_tier <- data.frame(version = "primary", tier = 1:3, B = B, SE_HC3 = se,
                          CI_low = B - qt(.975, df.residual(fit)) * se,
                          CI_high = B + qt(.975, df.residual(fit)) * se,
                          p_HC3 = 2 * pt(abs(B / se), df.residual(fit), lower.tail = FALSE))
within_tier$tier_label <- c("Junior college", "Bachelor", "Postgraduate")

# cohort interactions under alternative scores and current-only
ov_m5 <- update(primary_models$Model5, data = overview)
ov_m6 <- update(primary_models$Model6, data = overview)
current_m5 <- update(primary_models$Model5, data = d_current)
current_m6 <- update(primary_models$Model6, data = d_current)

interaction_test <- function(reduced, full, version, test) {
  a <- anova(reduced, full)
  h <- lmtest::waldtest(reduced, full, vcov = vcov_hc3, test = "F")
  data.frame(version = version, test = test, F_classical = a$F[2], p_classical = a$`Pr(>F)`[2],
             F_HC3 = h$F[2], p_HC3 = h$`Pr(>F)`[2])
}
interaction_tests <- rbind(
  interaction_test(primary_models$Model3, primary_models$Model4, "primary", "Model3_vs_Model4"),
  interaction_test(primary_models$Model5, primary_models$Model6, "primary", "Model5_vs_Model6"),
  interaction_test(ov_m5, ov_m6, "overview", "Model5_vs_Model6"),
  interaction_test(current_m5, current_m6, "current_only", "Model5_vs_Model6")
)

m6 <- primary_models$Model6
early_post <- d$cohort == 1 & d$edu_postgrad == 1
fit_diagnostics <- data.frame(version = "primary", model = "Model6", N = nobs(m6),
                              max_leverage = max(hatvalues(m6)),
                              earliest_postgrad_N = sum(early_post),
                              residual_SD = sigma(m6),
                              postgrad_SE_classical = unname(coef(summary(m6))["edu_postgrad", 2]),
                              postgrad_SE_HC3 = unname(sqrt(vcov_hc3(m6)["edu_postgrad", "edu_postgrad"])))

# occupation groups: ISCO 23 = teaching, 222/322 = nursing/midwifery
d$occ_group <- ifelse(substr(d$isco4, 1, 2) == "23", "Teaching",
               ifelse(substr(d$isco4, 1, 3) %in% c("222", "322"), "Nursing and midwifery", "Other"))
other_occ <- d$occ_group == "Other"
other_m3 <- update(primary_models$Model3, data = d[other_occ, ])
other_ov <- update(primary_models$Model3, data = overview[other_occ, ])

# teaching and nursing LPMs: 0/100 makes the coefficients percentage-point differences
d$teaching_pct <- 100 * (d$occ_group == "Teaching")
d$nursing_pct <- 100 * (d$occ_group == "Nursing and midwifery")
teach_lpm <- update(primary_models$Model3, teaching_pct ~ ., data = d)
nurse_lpm <- update(primary_models$Model3, nursing_pct ~ ., data = d)

occ_adjusted <- rbind(
  cbind(occupation = "Teaching", coefficient_table(teach_lpm, "primary", "Model3 controls")),
  cbind(occupation = "Nursing and midwifery", coefficient_table(nurse_lpm, "primary", "Model3 controls"))
)
occ_adjusted <- occ_adjusted[occ_adjusted$term == "rural_origin",
                c("occupation", "N", "B", "SE_HC3", "p_HC3", "CI_low", "CI_high")]
names(occ_adjusted)[3] <- "adjusted_difference_pp"

# occupation allocation at the sample, urban and rural mean scores
m3 <- primary_models$Model3
b_rural <- coef(m3)[["rural_origin"]]
refs <- c("Sample mean" = mean(d$isei),
          "Urban mean" = mean(d$isei[d$rural_origin == 0]),
          "Rural mean" = mean(d$isei[d$rural_origin == 1]))
occupation_contributions <- list()
for (reference in names(refs)) {
  for (group in c("Teaching", "Nursing and midwifery", "Other")) {
    tmp <- d
    tmp$part <- (d$isei - refs[[reference]]) * (d$occ_group == group)
    fit <- update(m3, part ~ ., data = tmp, na.action = na.fail)
    occupation_contributions[[paste(reference, group)]] <- data.frame(
      reference = reference, reference_score = refs[[reference]], occupation = group,
      group_N = sum(d$occ_group == group), model_N = nobs(fit),
      B = coef(fit)[["rural_origin"]])
  }
  occupation_contributions[[paste(reference, "Total")]] <- data.frame(
    reference = reference, reference_score = refs[[reference]], occupation = "Total",
    group_N = nrow(d), model_N = nobs(m3), B = b_rural)
}
occupation_contributions <- do.call(rbind, occupation_contributions)
rownames(occupation_contributions) <- NULL
occupation_contributions$share_of_total <- occupation_contributions$B / b_rural

# current teaching with province FE and weights
teaching_current <- d[d$occ_source == "current_A59", ]
teach_current <- update(teach_lpm, data = teaching_current)
teach_province <- update(teach_current, . ~ . + factor(s41))
teach_weighted <- update(teach_province, weights = weight)
teaching_models <- list(
  "Full sample" = teach_lpm,
  "Current occupation" = teach_current,
  "Current occupation + province" = teach_province,
  "Current occupation + province, weighted" = teach_weighted
)
teaching_checks <- list()
for (i in seq_along(teaching_models)) {
  fit <- teaching_models[[i]]
  cluster_data <- if (i == 1) d else teaching_current
  tab <- clustered_table(fit, cluster_data, names(teaching_models)[i], "Teaching", "rural_origin")
  teaching_checks[[i]] <- tab[c("version", "N", rural_columns)]
}
teaching_checks <- do.call(rbind, teaching_checks)
names(teaching_checks)[c(1, 3)] <- c("specification", "adjusted_difference_pp")
rownames(teaching_checks) <- NULL

# separate adult and regular qualifications
teaching_routes_data <- d[!is.na(d$education_route), ]
teaching_routes_current <- teaching_routes_data[teaching_routes_data$occ_source == "current_A59", ]
teach_tiers <- update(teach_lpm, data = teaching_routes_data, na.action = na.fail)
teach_routes <- lm(teaching_pct ~ education_route + female + age + par_edu_yrs + rural_origin,
                   data = teaching_routes_data, na.action = na.fail)
teaching_route_models <- list(
  full_three_tiers = teach_tiers,
  full_five_categories = teach_routes,
  current_three_tiers = update(teach_weighted, data = teaching_routes_current, na.action = na.fail),
  current_five_categories = update(teach_routes, . ~ . + factor(s41),
                                   data = teaching_routes_current, weights = weight, na.action = na.fail)
)
teaching_routes <- list()
for (i in seq_along(teaching_route_models)) {
  fit <- teaching_route_models[[i]]
  current <- startsWith(names(teaching_route_models)[i], "current_")
  route_data <- if (current) teaching_routes_current else teaching_routes_data
  tab <- clustered_table(fit, route_data, "highest qualification", "Teaching", "rural_origin")
  teaching_routes[[i]] <- cbind(
    data.frame(sample = if (current) "current" else "full",
               education = if (i %% 2 == 1) "three_tiers" else "five_categories",
               weighted = current, province_FE = current, N = nobs(fit), residual_df = df.residual(fit)),
    tab[rural_columns])
}
teaching_routes <- do.call(rbind, teaching_routes)
names(teaching_routes)[names(teaching_routes) == "B"] <- "adjusted_difference_pp"
rownames(teaching_routes) <- NULL

teaching_route_counts <- list()
for (sample in c("full", "current")) {
  route_data <- if (sample == "full") teaching_routes_data else teaching_routes_current
  for (route in levels(d$education_route)) {
    z <- route_data[route_data$education_route == route, ]
    teaching_route_counts[[paste(sample, route)]] <- data.frame(
      sample = sample, qualification = if (route == "Postgraduate") "Postgraduate (route unspecified)" else route,
      N = nrow(z), rural_N = sum(z$rural_origin == 1), urban_N = sum(z$rural_origin == 0),
      rural_teachers = sum(z$rural_origin == 1 & z$teaching_pct == 100),
      urban_teachers = sum(z$rural_origin == 0 & z$teaching_pct == 100))
  }
}
teaching_route_counts <- do.call(rbind, teaching_route_counts)
rownames(teaching_route_counts) <- NULL

occ_origin <- as.data.frame(table(occupation = d$occ_group, origin = d$rural_origin))
occ_origin$percent <- 100 * occ_origin$Freq / as.numeric(table(d$rural_origin)[as.character(occ_origin$origin)])
occ_origin$origin_label <- c("Urban", "Rural")[as.integer(occ_origin$origin)]

# detailed occupation counts
occ_detail_groups <- list(
  "University teaching" = substr(d$isco4, 1, 3) == "231",
  "Secondary teaching" = substr(d$isco4, 1, 3) == "233",
  "Primary teaching" = d$isco4 == "2341",
  "Other teaching" = substr(d$isco4, 1, 2) == "23" & !substr(d$isco4, 1, 3) %in% c("231", "233") & d$isco4 != "2341",
  "Nursing and midwifery" = substr(d$isco4, 1, 3) %in% c("222", "322")
)
occ_details <- do.call(rbind, lapply(names(occ_detail_groups), function(g) {
  z <- d[occ_detail_groups[[g]], ]
  data.frame(occupation = g, N = nrow(z), rural_N = sum(z$rural_origin == 1),
             urban_N = sum(z$rural_origin == 0), female_percent = 100 * mean(z$female))
}))

# keep the recorded teaching codes, including the broader 2300 and 2350 groups
teaching_names <- c("2300" = "Teaching professionals, unspecified",
                    "2310" = "University and higher education teachers",
                    "2320" = "Vocational education teachers",
                    "2330" = "Secondary education teachers",
                    "2341" = "Primary school teachers",
                    "2342" = "Early childhood educators",
                    "2350" = "Other teaching professionals, unspecified",
                    "2354" = "Other music teachers",
                    "2355" = "Other arts teachers",
                    "2356" = "Information technology trainers")
teaching_codes <- do.call(rbind, lapply(sort(unique(d$isco4[d$occ_group == "Teaching"])), function(code) {
  scores <- code_map[code_map$isco4 == code, ]
  data.frame(isco4 = code, occupation = unname(teaching_names[code]),
             coding_level = if (code == "2300") "Sub-major group" else
               if (code == "2350") "Minor group" else "Unit group",
             syntax = scores$syntax, overview = scores$overview, siops = scores$siops)
}))
# standardise both outcomes for the mapping-swap comparison
standard <- d
standard$isei <- as.numeric(scale(d$isei))
standard$isei_overview <- as.numeric(scale(d$isei_overview))
std_m3 <- update(primary_models$Model3, data = standard)
std_ov <- update(std_m3, isei_overview ~ ., data = standard)

# swap one group at a time, keeping raw and standardised comparisons
map_groups <- c(occ_detail_groups, list("Other occupations" = d$occ_group == "Other"))
base_b <- coef(primary_models$Model3)
map_b <- matrix(NA_real_, nrow = length(base_b), ncol = length(map_groups),
                dimnames = list(names(base_b), names(map_groups)))
map_z <- map_b
for (k in seq_along(map_groups)) {
  swapped <- d
  rows <- map_groups[[k]]
  swapped$isei[rows] <- d$isei_overview[rows]
  map_b[, k] <- coef(update(primary_models$Model3, data = swapped)) - base_b
  swapped <- standard
  swapped$isei[rows] <- standard$isei_overview[rows]
  map_z[, k] <- coef(update(std_m3, data = swapped)) - coef(std_m3)
}

map_contrib <- data.frame(
  occupation = names(map_groups), N = as.integer(sapply(map_groups, sum)),
  rural_change = unname(map_b["rural_origin", ]),
  female_change = unname(map_b["female", ]),
  rural_change_SD = unname(map_z["rural_origin", ]),
  female_change_SD = unname(map_z["female", ])
)
map_contrib <- rbind(map_contrib,
  data.frame(occupation = "Total", N = nrow(d),
             rural_change = sum(map_contrib$rural_change),
             female_change = sum(map_contrib$female_change),
             rural_change_SD = sum(map_contrib$rural_change_SD),
             female_change_SD = sum(map_contrib$female_change_SD)))

# qualification timing: highest qualification against entry into the current workplace
# approximate: A59M is rounded upward, A7C reflects the highest reported qualification,
# and employer changes are unobserved
year_qualified <- as.numeric(d$a7c)
tenure <- as.numeric(d$a59m)
work_years <- as.numeric(d$a59c)
timing_ok <- d$occ_source == "current_A59" & year_qualified %in% 1900:2017 &
             tenure %in% 0:60 & tenure <= d$age & year_qualified >= d$a31_num
timing_ok[is.na(timing_ok)] <- FALSE
cumulative_ok <- d$occ_source == "current_A59" & year_qualified %in% 1900:2017 &
                 work_years %in% 0:60 & work_years <= d$age & year_qualified >= d$a31_num
cumulative_ok[is.na(cumulative_ok)] <- FALSE
both_dates <- timing_ok & cumulative_ok
consistent_dates <- both_dates & work_years >= tenure
consistent_dates[is.na(consistent_dates)] <- FALSE
timing_sets <- list(
  reported_dates = timing_ok,
  age_screen = timing_ok & year_qualified - d$a31_num >= 17 & d$age - tenure >= 15,
  cumulative_work = cumulative_ok,
  matched_employer = both_dates,
  matched_cumulative = both_dates,
  consistent_employer = consistent_dates,
  consistent_cumulative = consistent_dates
)
timing_groups <- list(
  "All current workers" = rep(TRUE, nrow(d)),
  "Adult HE" = d$a7a_num %in% c(9, 11),
  "Regular HE" = d$a7a_num %in% c(10, 12),
  "Postgraduate" = d$a7a_num %in% 13,
  "Teaching: adult HE" = d$occ_group == "Teaching" & d$a7a_num %in% c(9, 11),
  "Teaching: regular HE or postgraduate" = d$occ_group == "Teaching" & d$a7a_num %in% c(10, 12, 13)
)
qual_timing <- list()
for (check in names(timing_sets)) for (g in names(timing_groups)) {
  cumulative <- check %in% c("cumulative_work", "matched_cumulative", "consistent_cumulative")
  duration <- if (cumulative) work_years else tenure
  year_gap <- year_qualified - (2017 - duration)
  rows <- timing_sets[[check]] & timing_groups[[g]]
  gap <- year_gap[rows]
  origin <- d$rural_origin[rows]
  qual_timing[[paste(check, g)]] <- data.frame(
             date_screen = check, time_basis = if (cumulative) "A59c cumulative work" else "A59m current employer",
             group = g, N = length(gap), qualification_earlier = sum(gap < -1),
             within_one_year = sum(abs(gap) <= 1), qualification_later = sum(gap > 1),
             rural_N = sum(origin == 1), rural_later = sum(origin == 1 & gap > 1),
             urban_N = sum(origin == 0), urban_later = sum(origin == 0 & gap > 1))
}
qual_timing <- do.call(rbind, qual_timing)
rownames(qual_timing) <- NULL

# compare later qualifications by origin within each teaching route
qual_timing$fisher_p <- NA_real_
for (i in which(grepl("^Teaching:", qual_timing$group))) {
  teacher_dates <- qual_timing[i, ]
  timing_counts <- rbind(
    Rural = c(teacher_dates$rural_later, teacher_dates$rural_N - teacher_dates$rural_later),
    Urban = c(teacher_dates$urban_later, teacher_dates$urban_N - teacher_dates$urban_later)
  )
  colnames(timing_counts) <- c("Qualification later", "Other timing")
  qual_timing$fisher_p[i] <- fisher.test(timing_counts)$p.value
}

# 2016 labour income for current workers
income <- as.numeric(d_current$a8b)
# 9999996: above questionnaire range
observed_income <- known_income(income)
income_flow <- data.frame(
  stage = c("Primary sample", "Current A59 occupation",
            "Amount or above-range response",
            "Known nonnegative amount", "Positive labour income"),
  N = c(nrow(d), nrow(d_current), sum(observed_income | income %in% 9999996),
        sum(observed_income), sum(observed_income & income > 0)))

# income availability by origin and occupation
income_groups <- list(All = rep(TRUE, nrow(d_current)),
                      Teaching = substr(d_current$isco4, 1, 2) == "23",
                      "Other occupations" = substr(d_current$isco4, 1, 2) != "23")
income_availability <- list()
for (origin in 0:1) {
  for (group in names(income_groups)) {
    rows <- d_current$rural_origin == origin & income_groups[[group]]
    income_availability[[length(income_availability) + 1]] <- data.frame(
      origin = c("Urban", "Rural")[origin + 1], occupation = group, N = sum(rows),
      positive_N = sum(rows & observed_income & income > 0),
      zero_N = sum(rows & income %in% 0),
      no_exact_amount_N = sum(rows & !observed_income))
  }
}
income_availability <- do.call(rbind, income_availability)

d_income <- d_current[observed_income & income > 0, ]
d_income$log_income <- log(as.numeric(d_income$a8b))
inc_m3 <- update(primary_models$Model3, log_income ~ ., data = d_income)
isei_inc <- update(primary_models$Model3, data = d_income)
inc_prov <- update(inc_m3, . ~ . + factor(s41), data = d_income)
isei_prov <- update(isei_inc, . ~ . + factor(s41), data = d_income)

# extract just the Model 3 terms from regressions that also have province FEs
income_table <- function(fit, outcome, version, keep_terms, data) {
  cbind(outcome = outcome, clustered_table(fit, data, version, keep = keep_terms))
}
inc_terms <- names(coef(inc_m3))
income_models <- list(
  positive_income_current = list("Log 2016 labour income" = inc_m3, ISEI = isei_inc),
  positive_income_province = list("Log 2016 labour income" = inc_prov, ISEI = isei_prov),
  positive_income_current_weighted = list("Log 2016 labour income" = update(inc_m3, weights = weight),
                                          ISEI = update(isei_inc, weights = weight)),
  positive_income_province_weighted = list("Log 2016 labour income" = update(inc_prov, weights = weight),
                                           ISEI = update(isei_prov, weights = weight))
)
income_results <- list()
for (version in names(income_models)) for (outcome in names(income_models[[version]])) {
  fit <- income_models[[version]][[outcome]]
  income_results[[paste(version, outcome)]] <- income_table(fit, outcome, version, inc_terms, d_income)
}
income_results <- do.call(rbind, income_results)

# usual weekly hours in 2017; follow the A53 skips
d_income$weekly_hours <- NA_real_
worked_last_week <- as.numeric(d_income$a53) %in% 4
temporarily_away <- as.numeric(d_income$a53) %in% c(2, 3)
d_income$weekly_hours[worked_last_week] <- as.numeric(d_income$a53aa)[worked_last_week]
d_income$weekly_hours[temporarily_away] <- as.numeric(d_income$a53a)[temporarily_away]
hours_sample <- d_income[d_income$weekly_hours %in% 1:168, ]
hours_sample$log_hours <- log(hours_sample$weekly_hours)
inc_hours_base <- update(inc_prov, data = hours_sample)
inc_hours <- update(inc_hours_base, . ~ . + log_hours)
hours_results <- rbind(
  income_table(inc_hours_base, "Log 2016 labour income", "Province controls, hours sample",
               inc_terms, hours_sample),
  income_table(inc_hours, "Log 2016 labour income", "Province controls + log 2017 weekly hours",
               c(inc_terms, "log_hours"), hours_sample)
)

coefficient_results <- rbind(
  do.call(rbind, primary_coefs),
  coefficient_table(ov_m3, "overview", "Model3"),
  coefficient_table(ov_m6, "overview", "Model6"),
  coefficient_table(current_m3, "current_only", "Model3"),
  coefficient_table(current_m6, "current_only", "Model6"),
  coefficient_table(weighted_m3, "weighted", "Model3"),
  coefficient_table(unit_m3, "unit_codes", "Model3"),
  coefficient_table(unit_ov, "unit_codes_overview", "Model3"),
  coefficient_table(exclude_other_m3, "exclude_parent_other", "Model3"),
  coefficient_table(routes_m3, "education_routes", "Model3"),
  coefficient_table(regular_m3, "regular_he", "Model3"),
  coefficient_table(township_m3, "township_separate", "Model3"),
  coefficient_table(other_m3, "outside_teaching_nursing", "Model3"),
  coefficient_table(other_ov, "outside_teaching_nursing_overview", "Model3")
)

out_dir <- "output/tables"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
outputs <- list(sample_flow = sample_flow, sample_composition = composition, completion_status = completion_status,
                education_origin = education_origin, cohort_education = cohort_education,
                model_coefficients = coefficient_results, model_diagnostics = fit_diagnostics,
                interaction_tests = interaction_tests, within_tier_origin = within_tier,
                model_fit = model_fit, occupation_origin = occ_origin, occupation_adjusted = occ_adjusted,
                occupation_contributions = occupation_contributions,
                teaching_checks = teaching_checks, teaching_codes = teaching_codes,
                teaching_routes = teaching_routes, teaching_route_counts = teaching_route_counts,
                occupation_coding = occupation_coding,
                province_cluster = province_results, isei_province = isei_province,
                origin_summary = origin_summary, occupation_details = occ_details,
                income_comparison = income_results, income_sample_flow = income_flow,
                income_availability = income_availability, income_hours = hours_results,
                qualification_timing = qual_timing,
                isei_mapping = code_map, mapping_contributions = map_contrib,
                scale_comparison = scale_comparison)
for (nm in names(outputs)) write.csv(outputs[[nm]], file.path(out_dir, paste0(nm, ".csv")), row.names = FALSE)
source("R/05_allocation_reference.R")

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
png("output/figures/model3_mapping.png", width = 1800, height = 1000, res = 180)
par(mar = c(5, 10, 4, 2))
plot_terms <- c("female", "rural_origin", "edu_bachelor", "edu_postgrad")
plot_syntax <- coefficient_results[coefficient_results$version == "primary" & coefficient_results$model == "Model3", ]
plot_overview <- coefficient_results[coefficient_results$version == "overview" & coefficient_results$model == "Model3", ]
plot_syntax <- plot_syntax[match(plot_terms, plot_syntax$term), ]; plot_overview <- plot_overview[match(plot_terms, plot_overview$term), ]
for (column in c("B", "CI_low", "CI_high")) {
  plot_syntax[[column]] <- plot_syntax[[column]] / sd(d$isei)
  plot_overview[[column]] <- plot_overview[[column]] / sd(d$isei_overview)
}
plot(NA, xlim = range(c(plot_syntax$CI_low, plot_overview$CI_low, plot_syntax$CI_high, plot_overview$CI_high)) + c(-.05, .05),
     ylim = c(.5, 4.8), yaxt = "n", xlab = "Coefficient (outcome SDs; 95% HC3 CI)", ylab = "",
     main = "Model 3 under two ISEI mappings")
axis(2, at = 1:4, labels = c("Female vs male", "Rural vs urban origin", "Bachelor\n(vs junior college)", "Postgraduate\n(vs junior college)"), las = 1, cex.axis = .9)
abline(v = 0, col = "grey70", lty = 2)
segments(plot_syntax$CI_low, (1:4) + .1, plot_syntax$CI_high, (1:4) + .1, col = "black", lwd = 2)
points(plot_syntax$B, (1:4) + .1, pch = 16, col = "black")
segments(plot_overview$CI_low, (1:4) - .1, plot_overview$CI_high, (1:4) - .1, col = "grey55", lwd = 2)
points(plot_overview$B, (1:4) - .1, pch = 17, col = "grey55")
legend("topright", c("Syntax", "Overview"), col = c("black", "grey55"),
       pch = c(16, 17), lty = 1, bty = "n", cex = .9)
dev.off()

png("output/figures/origin_by_education.png", width = 1600, height = 850, res = 180)
par(mar = c(5, 8, 3, 1))
plot(NA, xlim = range(c(within_tier$CI_low, within_tier$CI_high)) + c(-.5, .5),
     ylim = c(.5, 3.5), yaxt = "n", ylab = "",
     xlab = "Rural - urban ISEI difference (95% HC3 CI)",
     main = "Model 4: rural-urban differences within education tiers")
axis(2, at = 3:1, labels = c("Junior college", "Bachelor", "Postgraduate"), las = 1)
abline(v = 0, lty = 2, col = "grey70")
segments(within_tier$CI_low, 3:1, within_tier$CI_high, 3:1)
points(within_tier$B, 3:1, pch = 16)
dev.off()

source("R/06_plot_mapping.R")

teaching_share <- occ_origin[occ_origin$occupation == "Teaching", ]
origin_n <- as.integer(table(d$rural_origin)[as.character(teaching_share$origin)])
png("output/figures/teaching_by_origin.png", width = 1400, height = 900, res = 180)
par(mar = c(6, 5, 4, 1))
bar_positions <- barplot(teaching_share$percent, names.arg = paste(teaching_share$origin_label, "origin"),
                          ylim = c(0, 25), col = "grey40", border = NA,
                          ylab = "Teaching occupation (%)", main = "Teaching among rural and urban graduates")
text(bar_positions, teaching_share$percent + 2,
     sprintf("%.1f%%\n(%d / %d)", teaching_share$percent, teaching_share$Freq, origin_n), cex = .95)
mtext("Current or most recent non-farm occupation", side = 1, line = 3, cex = .8)
mtext(sprintf("CGSS 2017; unweighted, N = %s", format(nrow(d), big.mark = ",")),
      side = 1, line = 4, cex = .8)
dev.off()

source("R/07_sample_context.R")
source("R/08_sector_split.R")

writeLines(capture.output(sessionInfo()), "docs/session-info.txt")
