# 03 Current/most recent non-farm occupation and ISEI

source("R/02_construct_sample.R")
print(packageVersion("ISCO08ConveRsions"))
stopifnot(packageVersion("ISCO08ConveRsions") == "0.2.0")

occupation <- choose_occupation(as.numeric(dat$isco08_a59), as.numeric(dat$isco08_a60))
dat$isco4 <- occupation$isco4
dat$occ_source <- occupation$occ_source
dat$sample_occupation <- dat$sample_age & !is.na(dat$isco4)
dat$sample_origin <- dat$sample_occupation & !is.na(dat$rural_origin)
dat$sample_final <- dat$sample_origin & !is.na(dat$par_edu_yrs)
analysis_sample <- dat[dat$sample_final, ]
if (any(!is.finite(analysis_sample$weight) | analysis_sample$weight <= 0))
  stop("Invalid survey weights")

isco_levels <- read.csv("data/reference/isco08_levels.csv", colClasses = "character")
analysis_sample$coding_level <- classify_isco_level(analysis_sample$isco4, isco_levels)

# map only the occupation actually used in the analysis
code_map <- data.frame(isco4 = sort(unique(analysis_sample$isco4)))
code_map$syntax <- NA_real_
code_map$overview <- NA_real_
for (i in seq_len(nrow(code_map))) {
  code <- code_map$isco4[i]
  code_map$syntax[i] <- as.numeric(ISCO08ConveRsions::isco08toisei08(code))
  code_map$overview[i] <- as.numeric(ISCO08ConveRsions::isco08toisei08_2(code))
}
# 3314 is 63 in the original overview table; the package returns 61
# checked against http://www.harryganzeboom.nl/isco08/isco08_with_isei.pdf
code_map$overview_package <- code_map$overview
code_map$overview[code_map$isco4 == "3314"] <- 63
unmapped <- !is.finite(code_map$syntax) | !is.finite(code_map$overview)
if (any(unmapped)) stop("Missing ISEI scores for: ", paste(code_map$isco4[unmapped], collapse = ", "))
analysis_sample$isei <- code_map$syntax[match(analysis_sample$isco4, code_map$isco4)]
analysis_sample$isei_overview <- code_map$overview[match(analysis_sample$isco4, code_map$isco4)]
sample_flow <- data.frame(
  stage = c("Full CGSS 2017 sample", "Higher-education tier identified", "Highest reported qualification completed",
            "Age 25-60", "Current or most recent non-farm occupation available", "Age-14 origin available",
            "Parental education available (final sample)"),
  N = c(nrow(dat), sum(dat$sample_education), sum(dat$sample_completed), sum(dat$sample_age),
        sum(dat$sample_occupation), sum(dat$sample_origin), nrow(analysis_sample))
)
print(sample_flow, row.names = FALSE)
