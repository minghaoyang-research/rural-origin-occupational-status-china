# CGSS 2017 source data
# 786 variables is what the 2017 release has; older downloads may differ

library(haven)
raw_file <- "data/raw/CGSS2017.sav"
dat <- read_sav(raw_file, user_na = TRUE)
if (nrow(dat) != 12582 || ncol(dat) != 786) stop("Expected 12582 rows and 786 variables")

required <- c("a2", "a31", "a7a", "a7aa", "a7b", "a27h", "a27f",
              "a89b", "a90b", "a53", "a53a", "a53aa", "a58", "isco08_a59", "isco08_a60",
              "weight", "s41", "a7c", "a59c", "a59m", "a8b",
              "a59a", "a59b", "a59j", "a59k", "a89d", "a89g", "a89h",
              "a90d", "a90g", "a90h")
if (!all(required %in% names(dat))) stop("Survey variables needed for the analysis are missing.")
