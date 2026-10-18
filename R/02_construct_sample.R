# 02 Education, completion, age, origin and parental education

source("R/01_import_validate.R")
source("R/analysis_helpers.R")

# Numeric copies of the survey items
items <- c("a2", "a31", "a7a", "a7b", "a27h", "a27f", "a89b", "a90b")
for (item in items) dat[[paste0(item, "_num")]] <- as.numeric(dat[[item]])
dat$age <- 2017 - dat$a31_num

dat$edu_lvl <- education_tier(dat$a7a_num, dat$a7aa)
dat$edu_bachelor <- as.numeric(dat$edu_lvl == 2)
dat$edu_postgrad <- as.numeric(dat$edu_lvl == 3)
dat$sample_education <- !is.na(dat$edu_lvl)
# A7B = 4: graduated from the reported highest level
dat$sample_completed <- completed_he(dat$edu_lvl, dat$a7b_num)
dat$sample_age <- dat$sample_completed & !is.na(dat$age) & dat$age >= 25 & dat$age <= 60

dat$female <- rep(NA_real_, nrow(dat))
dat$female[dat$a2_num %in% 1] <- 0
dat$female[dat$a2_num %in% 2] <- 1
dat$cohort <- rep(NA_real_, nrow(dat))
dat$cohort[dat$a31_num %in% 1957:1964] <- 1
dat$cohort[dat$a31_num %in% 1965:1974] <- 2
dat$cohort[dat$a31_num %in% 1975:1984] <- 3
dat$cohort[dat$a31_num %in% 1985:1992] <- 4
dat$cohort2 <- as.numeric(dat$cohort == 2)
dat$cohort3 <- as.numeric(dat$cohort == 3)
dat$cohort4 <- as.numeric(dat$cohort == 4)

# townships (2) grouped with villages (1)
dat$rural_origin <- recode_origin(dat$a27h_num)
dat$rural_origin_f <- recode_origin(dat$a27f_num)

dat$fa_edu_yrs <- recode_parent_education(dat$a89b_num)
dat$mo_edu_yrs <- recode_parent_education(dat$a90b_num)
dat$par_edu_yrs <- parent_education_max(dat$fa_edu_yrs, dat$mo_edu_yrs)
