# 08 employer sector and teaching
# called from 04 after the income models
source("R/sector_helpers.R")

sector_levels <- c("Public", "State enterprise", "Non-state enterprise and other")
sector_samples <- list(current = d_current, income = d_income)
for (name in names(sector_samples)) {
  tmp <- sector_samples[[name]]
  tmp$sector <- employer_sector(tmp$a59j, tmp$a59k)
  tmp$sector_f <- factor(tmp$sector, levels = sector_levels)
  tmp$teaching <- as.numeric(substr(tmp$isco4, 1, 2) == "23")
  sector_samples[[name]] <- tmp
}
sector_samples$known <- subset(sector_samples$income, !is.na(sector))
sector_samples$public <- subset(sector_samples$known, sector == "Public")

sector_flow <- NULL
sector_support <- NULL
for (sample_name in c("Current A59 occupation", "Positive 2016 labour income")) {
  if (sample_name == "Current A59 occupation") {
    tmp <- sector_samples$current
  } else {
    tmp <- sector_samples$income
  }
  sector_flow <- rbind(sector_flow, data.frame(
    sample = sample_name, stage = c("All", "Sector unknown", "Sector known"),
    N = c(nrow(tmp), sum(is.na(tmp$sector)), sum(!is.na(tmp$sector)))))

  tmp <- tmp[!is.na(tmp$sector), ]
  for (sector in sector_levels) {
    rows <- tmp$sector == sector
    province <- as.numeric(tmp$s41[rows])
    origin <- tmp$rural_origin[rows]
    common <- intersect(unique(province[origin == 1]), unique(province[origin == 0]))
    for (group in 0:1) {
      members <- origin == group
      sector_support <- rbind(sector_support, data.frame(
        sample = sample_name, sector = sector, origin = c("Urban", "Rural")[group + 1],
        N = sum(members), provinces_N = length(unique(province[members])),
        common_provinces_N = length(common)))
    }
  }
}


# teaching inside and outside the public sector
income_known <- sector_samples$known
income_known$public <- as.numeric(income_known$sector == "Public")
sector_teaching <- NULL
for (group in 0:1) {
  for (public in 1:0) {
    for (teaching in 1:0) {
      rows <- income_known$rural_origin == group & income_known$public == public &
        income_known$teaching == teaching
      sector_teaching <- rbind(sector_teaching, data.frame(
        origin = c("Urban", "Rural")[group + 1],
        sector = if (public == 1) "Public" else "Outside the public sector",
        occupation = if (teaching == 1) "Teaching" else "Other occupations", N = sum(rows)))
    }
  }
}


# public is the sector reference; non-teachers are the teaching reference
sector_outcomes <- c("Log 2016 labour income" = "log_income", ISEI = "isei")
sector_fits <- list()
sector_coefficients <- NULL
sector_contrasts <- NULL
sector_tests <- NULL
for (model_name in c("sector", "teaching", "teaching_within_public")) {
  versions <- c("base", "province", "base_weighted", "province_weighted")
  if (model_name == "sector") {
    spec <- list(data = sector_samples$known,
      full = ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin * sector_f,
      reduced = ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin + sector_f,
      interactions = paste0("rural_origin:sector_f", sector_levels[-1]), groups = sector_levels)
  } else {
    tmp <- sector_samples$income
    if (model_name == "teaching_within_public") {
      tmp <- sector_samples$public
      # single-person province in this subset, province FE omitted
      versions <- c("base", "base_weighted")
    }
    spec <- list(data = tmp,
      full = ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin * teaching,
      reduced = ~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin + teaching,
      interactions = "rural_origin:teaching", groups = c("Other occupations", "Teaching"))
  }

  for (outcome_label in names(sector_outcomes)) {
    for (version in versions) {
      province <- version %in% c("province", "province_weighted")
      weighted <- version %in% c("base_weighted", "province_weighted")
      estimate <- fit_sector_pair(spec, sector_outcomes[[outcome_label]], province, weighted)
      record <- list(outcome = outcome_label, model = model_name, version = version,
        weighted = weighted, province_FE = province, groups = spec$groups,
        interactions = spec$interactions, estimate = estimate)
      sector_fits[[paste(model_name, outcome_label, version)]] <- record

      tab <- sector_result_tables(record)
      sector_coefficients <- rbind(sector_coefficients, tab$coefficients)
      sector_contrasts <- rbind(sector_contrasts, tab$contrasts)
      sector_tests <- rbind(sector_tests, tab$tests)
    }
  }
}

sector_outputs <- list(sector_flow = sector_flow, sector_support = sector_support,
  sector_teaching = sector_teaching, sector_coefficients = sector_coefficients,
  sector_contrasts = sector_contrasts, sector_tests = sector_tests)
for (nm in names(sector_outputs)) {
  rownames(sector_outputs[[nm]]) <- NULL
  write.csv(sector_outputs[[nm]], file.path("output/tables", paste0(nm, ".csv")), row.names = FALSE)
}
cat("Sector model sample:", nrow(sector_samples$known),
    "; public-sector sample:", nrow(sector_samples$public), "\n")
