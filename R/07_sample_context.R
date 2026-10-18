# Supplementary descriptions, called after the main analysis.
# dat = full survey; analysis_sample = graduate sample after all filters

age_eligible <- !is.na(dat$age) & dat$age >= 25 & dat$age <= 60
selection_stages <- list(
  age_eligible = age_eligible,
  reported_HE_tier = age_eligible & dat$sample_education,
  completed_highest_HE = dat$sample_age,
  eligible_occupation = dat$sample_occupation,
  final_sample = dat$sample_final
)
selection_rows <- list()
for (origin in 0:1) {
  origin_rows <- dat$rural_origin %in% origin
  denominator <- sum(age_eligible & origin_rows)
  for (stage in names(selection_stages)) {
    n <- sum(selection_stages[[stage]] & origin_rows)
    selection_rows[[paste(origin, stage)]] <- data.frame(
      origin = c("Urban", "Rural")[origin + 1], stage = stage,
      denominator = denominator, N = n, percent_of_age_group = 100 * n / denominator
    )
  }
}
selection_by_origin <- do.call(rbind, selection_rows)
rownames(selection_by_origin) <- NULL
write.csv(selection_by_origin, "output/tables/selection_by_origin.csv", row.names = FALSE)

# A59J is the organisation type, not bianzhi status (which CGSS doesn't ask directly)
employer_sample <- analysis_sample[analysis_sample$occ_source == "current_A59", ]
employer_type <- as.numeric(employer_sample$a59j)
employer_teaching <- substr(employer_sample$isco4, 1, 2) == "23"
employer_rows <- list()
for (origin in 0:1) for (teaching in c(TRUE, FALSE)) {
  rows <- employer_sample$rural_origin == origin & employer_teaching == teaching
  counts <- c(institution = sum(rows & employer_type %in% 3),
              enterprise = sum(rows & employer_type %in% 2),
              other_or_unreported = sum(rows & !employer_type %in% c(2, 3)))
  employer_rows[[paste(origin, teaching)]] <- data.frame(
    origin = c("Urban", "Rural")[origin + 1],
    occupation = if (teaching) "Teaching" else "Other occupations",
    N = sum(rows), institution_N = counts["institution"],
    enterprise_N = counts["enterprise"], other_or_unreported_N = counts["other_or_unreported"],
    institution_percent = 100 * counts["institution"] / sum(rows)
  )
}
employer_context <- do.call(rbind, employer_rows)
rownames(employer_context) <- NULL
write.csv(employer_context, "output/tables/employer_context.csv", row.names = FALSE)

# Feasibility of the employer and childhood-background items, respecting skips.
context_coverage_row <- function(data, variable, applicable, valid_codes) {
  value <- as.numeric(data[[variable]])
  data.frame(variable = variable, base_N = nrow(data), applicable_N = sum(applicable),
             valid_N = sum(applicable & value %in% valid_codes),
             unknown_N = sum(applicable & !value %in% valid_codes),
             skipped_N = sum(!applicable))
}
context_coverage <- list(
  context_coverage_row(employer_sample, "a59j", rep(TRUE, nrow(employer_sample)), 1:7),
  context_coverage_row(employer_sample, "a59k", !employer_type %in% c(1, 5, 6), 1:6),
  context_coverage_row(employer_sample, "a59b",
                       !as.numeric(employer_sample$a59a) %in% c(1, 2, 5, 7, 8), 1:3)
)
for (parent in c("a89", "a90")) {
  employment <- as.numeric(analysis_sample[[paste0(parent, "d")]])
  organisation <- as.numeric(analysis_sample[[paste0(parent, "g")]])
  has_job_details <- !employment %in% 11:16
  context_coverage <- c(context_coverage, list(
    context_coverage_row(analysis_sample, paste0(parent, "d"), rep(TRUE, nrow(analysis_sample)), 1:17),
    context_coverage_row(analysis_sample, paste0(parent, "g"), has_job_details, 1:7),
    context_coverage_row(analysis_sample, paste0(parent, "h"),
                         has_job_details & !organisation %in% c(1, 5, 6), 1:6)
  ))
}
context_coverage <- do.call(rbind, context_coverage)
write.csv(context_coverage, "output/tables/context_coverage.csv", row.names = FALSE)

cat("Age-eligible respondents:", sum(age_eligible),
    "; origin unclassified:", sum(age_eligible & is.na(dat$rural_origin)),
    "; education tier unclassified:",
    sum(age_eligible & !dat$a7a_num %in% 1:13 & !dat$sample_education),
    "; reported HE with unfinished/unknown status:",
    sum(age_eligible & dat$sample_education & !dat$sample_completed), "\n")
