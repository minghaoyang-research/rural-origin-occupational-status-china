# rural coefficient with current urban/rural classification

source("R/03_construct_isei.R")
d <- as.data.frame(analysis_sample)

out <- "output/supplementary/geographic-sorting"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
save_table <- function(x, name)
  write.csv(x, file.path(out, paste0(name, ".csv")), row.names = FALSE)

# isurban: 1 urban, 2 rural
d$current_rural <- NA_real_
d$current_rural[as.numeric(d$isurban) %in% 1] <- 0
d$current_rural[as.numeric(d$isurban) %in% 2] <- 1
d_sort <- d[!is.na(d$current_rural), ]

m3_full <- lm(isei ~ edu_bachelor + edu_postgrad + female + age +
                par_edu_yrs + rural_origin, data = d, na.action = na.fail)
m3_restricted <- update(m3_full, data = d_sort)
m3_sorting <- update(m3_restricted, . ~ . + current_rural)

hc3_row <- function(fit, label) {
  b <- coef(fit)
  V <- sandwich::vcovHC(fit, type = "HC3")
  se <- sqrt(diag(V))
  r <- "rural_origin"
  df <- df.residual(fit)
  data.frame(model = label, N = nobs(fit),
             B_rural = unname(b[r]),
             SE_HC3 = unname(se[r]),
             CI_low = unname(b[r] - qt(.975, df) * se[r]),
             CI_high = unname(b[r] + qt(.975, df) * se[r]),
             p_HC3 = 2 * pt(abs(b[r] / se[r]), df, lower.tail = FALSE))
}

hc3 <- rbind(
  hc3_row(m3_full, "Model 3 (full sample)"),
  hc3_row(m3_restricted, "Model 3 (sorting sample)"),
  hc3_row(m3_sorting, "Model 3 + current residence"))

# province-clustered SEs

prov_row <- function(fit, data, label) {
  cl <- province_table(fit, data)
  cl <- cl[cl$term == "rural_origin", ]
  data.frame(model = label, provinces = cl$provinces,
             SE_province = cl$SE_province,
             province_CI_low = cl$CI_low,
             province_CI_high = cl$CI_high,
             p_province = cl$p_province)
}

prov <- rbind(
  prov_row(m3_full, d, "Model 3 (full sample)"),
  prov_row(m3_restricted, d_sort, "Model 3 (sorting sample)"),
  prov_row(m3_sorting, d_sort, "Model 3 + current residence"))

combined <- merge(hc3, prov, by = "model")
save_table(combined, "sorting_test")

# interview-province indicators

m3_prov <- update(m3_restricted, . ~ . + factor(s41))
m3_sort_prov <- update(m3_sorting, . ~ . + factor(s41))

hc3_prov <- rbind(
  hc3_row(m3_prov, "Model 3 + province FE"),
  hc3_row(m3_sort_prov, "Model 3 + current residence + province FE"))

prov_prov <- rbind(
  prov_row(m3_prov, d_sort, "Model 3 + province FE"),
  prov_row(m3_sort_prov, d_sort, "Model 3 + current residence + province FE"))

combined_prov <- merge(hc3_prov, prov_prov, by = "model")
save_table(combined_prov, "sorting_test_province")

# survey weights
m3_wt <- update(m3_restricted, weights = as.numeric(weight))
m3_sort_wt <- update(m3_sorting, weights = as.numeric(weight))

hc3_wt <- rbind(
  hc3_row(m3_wt, "Model 3 weighted"),
  hc3_row(m3_sort_wt, "Model 3 + current residence weighted"))

prov_wt <- rbind(
  prov_row(m3_wt, d_sort, "Model 3 weighted"),
  prov_row(m3_sort_wt, d_sort, "Model 3 + current residence weighted"))

combined_wt <- merge(hc3_wt, prov_wt, by = "model")
save_table(combined_wt, "sorting_test_weighted")

change <- hc3$B_rural[3] - hc3$B_rural[2]
pct <- 100 * change / hc3$B_rural[2]

# all coefficients for the sorting model
all_coefs <- data.frame(
  term = names(coef(m3_sorting)),
  B = unname(coef(m3_sorting)),
  SE_HC3 = unname(sqrt(diag(sandwich::vcovHC(m3_sorting, type = "HC3")))))
save_table(all_coefs, "sorting_model_coefficients")

save_table(data.frame(
  full_sample_N = nrow(d),
  sorting_sample_N = nrow(d_sort),
  missing_isurban = sum(is.na(d$current_rural)),
  rural_origin_N = sum(d_sort$rural_origin == 1),
  urban_origin_N = sum(d_sort$rural_origin == 0),
  current_rural_N = sum(d_sort$current_rural == 1),
  current_urban_N = sum(d_sort$current_rural == 0),
  B_baseline = hc3$B_rural[2],
  B_sorting = hc3$B_rural[3],
  change = change,
  pct_change = pct), "verification")

writeLines(capture.output(sessionInfo()),
           file.path(out, "session-info.txt"))
