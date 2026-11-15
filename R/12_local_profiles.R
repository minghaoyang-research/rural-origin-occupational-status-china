# occupations scored by the schooling and earnings of CGSS workers

source("R/03_construct_isei.R")
out <- "output/supplementary/local-profiles"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
save_table <- function(x, name) write.csv(x, file.path(out, paste0(name, ".csv")), row.names = FALSE)

# donors: ages 25-60 with a current occupation code, leaving out farming codes (6 and 921)
code <- pad_isco(as.numeric(dat$isco08_a59))
aged <- !is.na(dat$age) & dat$age >= 25 & dat$age <= 60 & !is.na(code)
pool <- which(aged & substr(code, 1, 1) != "6" & substr(code, 1, 3) != "921")
donor <- data.frame(row = pool, isco4 = code[pool], province = as.numeric(dat$s41[pool]))
income <- as.numeric(dat$a8b[pool])
donor$earnings <- ifelse(known_income(income) & income > 0, log(income), NA)
# years for the highest qualification, counted when it was completed or the answer is no schooling or a literacy class
finished <- dat$a7b_num[pool] %in% 4 | dat$a7a_num[pool] %in% 1:2
donor$schooling <- ifelse(finished, recode_parent_education(dat$a7a_num[pool]), NA)
codes <- unique(donor$isco4)
scores_isei <- sapply(codes, function(x) as.numeric(ISCO08ConveRsions::isco08toisei08(x)))
donor$isei <- unname(scores_isei[donor$isco4])
both <- !is.na(donor$schooling) & !is.na(donor$earnings)

# a two-digit group stands alone with 30 workers, 30 schooling values, 20 earnings values and two provinces;
# the rest are pooled within their one-digit group
size <- function(z) c(workers = nrow(z), schooling = sum(!is.na(z$schooling)),
                      earnings = sum(!is.na(z$earnings)), provinces = length(unique(z$province)))
enough <- function(n) n["schooling", ] >= 30 & n["earnings", ] >= 20 & n["provinces", ] >= 2
donor$major <- substr(donor$isco4, 1, 1)
two <- substr(donor$isco4, 1, 2)
by_two <- sapply(split(donor, two), size)
donor$group <- ifelse(two %in% colnames(by_two)[by_two["workers", ] >= 30 & enough(by_two)], two, donor$major)
# pooled workers draw on their whole one-digit group; the armed forces have too few donors and are left out
supported <- enough(sapply(split(donor, donor$major), size))[donor$major]
# folds were dealt within groups when the analysis was first run; they are read back in pool order
donor$fold <- read.csv("data/reference/profile_folds.csv")$fold
stopifnot(tapply(donor$fold, donor$group, function(f) diff(range(tabulate(f + 1, 5)))) <= 1)

# income sample in supported groups
d <- as.data.frame(analysis_sample)
d$donor <- match(which(dat$sample_final), donor$row)
income <- as.numeric(d$a8b)
paired <- d$occ_source == "current_A59" & known_income(income) & income > 0
target <- d[paired & supported[d$donor], ]

# group mean of a measure outside the worker's own fold, shrunk towards the one-digit mean
# with the weight of ten workers; pooled groups take the one-digit mean
profile <- function(measure, w = 1, common = FALSE) {
  use <- !is.na(measure) & (!common | both)
  w <- w * use
  x <- ifelse(use, measure, 0)
  outside <- function(v, by) {
    sums <- tapply(v, list(by, donor$fold), sum)
    sums[is.na(sums)] <- 0
    rowSums(sums) - sums
  }
  n <- outside(w, donor$group)
  parent <- (outside(w * x, donor$major) / outside(w, donor$major))[substr(rownames(n), 1, 1), ]
  score <- (outside(w * x, donor$group) + 10 * parent) / (n + 10)
  pooled <- nchar(rownames(n)) == 1
  score[pooled, ] <- parent[pooled, ]
  score[cbind(donor$group, as.character(donor$fold))][target$donor]
}
scores <- function(w = 1) cbind(
  "ISEI" = target$isei,
  "ISEI profile" = profile(donor$isei, w),
  "Schooling" = profile(donor$schooling, w),
  "Earnings" = profile(donor$earnings, w),
  "ISEI profile, common donors" = profile(donor$isei, w, TRUE),
  "Schooling, common donors" = profile(donor$schooling, w, TRUE),
  "Earnings, common donors" = profile(donor$earnings, w, TRUE))

# rural coefficient with the Model 3 controls for each score
X <- model.matrix(~ edu_bachelor + edu_postgrad + female + age + par_edu_yrs + rural_origin, target)
rural <- function(Y, w = rep(1, nrow(X)))
  lm.wfit(X[w > 0, ], Y[w > 0, ], w[w > 0])$coefficients["rural_origin", ]
Y <- scores()
B <- rural(Y)
SD <- apply(Y, 2, sd)

# province bootstrap on the saved draws: donors and graduates are resampled together,
# scores are rebuilt in each draw, and the standard deviations stay fixed
draws <- province_draws()
donor_province <- match(donor$province, as.numeric(colnames(draws)))
target_province <- match(as.numeric(target$s41), as.numeric(colnames(draws)))
boot <- t(apply(draws, 1, function(m) rural(scores(m[donor_province]), m[target_province]) / SD))
interval <- function(v) quantile(v, c(.025, .975))
limits <- apply(boot, 2, interval)

estimates <- data.frame(quantity = names(B), N = nrow(target), B = B, SD = SD, B_SD = B / SD,
                        percentile_low = limits[1, ], percentile_high = limits[2, ])
pairs <- rbind(c("ISEI", "Schooling"), c("ISEI", "Earnings"), c("Schooling", "Earnings"),
               c("ISEI profile", "Schooling"), c("ISEI profile", "Earnings"),
               c("ISEI profile, common donors", "Schooling, common donors"),
               c("ISEI profile, common donors", "Earnings, common donors"),
               c("Schooling, common donors", "Earnings, common donors"))
for (i in seq_len(nrow(pairs))) {
  a <- pairs[i, 1]
  b <- pairs[i, 2]
  limits <- interval(boot[, a] - boot[, b])
  estimates <- rbind(estimates, data.frame(quantity = paste(a, "minus", b), N = nrow(target), B = NA, SD = NA,
                                           B_SD = B[[a]] / SD[[a]] - B[[b]] / SD[[b]],
                                           percentile_low = limits[1], percentile_high = limits[2]))
}
save_table(estimates, "profiles")

shown <- ifelse(nchar(donor$group) == 2, donor$group, "pooled")
groups <- t(sapply(split(donor, shown), size))
save_table(data.frame(group = rownames(groups), groups, both = as.vector(tapply(both, shown, sum))),
           "profile_groups")
save_table(data.frame(
  stage = c("Ages 25-60 with a current occupation code", "Donor pool", "Donors with schooling",
            "Donors with earnings", "Donors with both", "Income sample", "Income sample in supported groups"),
  N = c(sum(aged), nrow(donor), sum(!is.na(donor$schooling)), sum(!is.na(donor$earnings)), sum(both),
        sum(paired), nrow(target))), "profile_sample")

print(estimates[c("quantity", "B_SD", "percentile_low", "percentile_high")], row.names = FALSE)
cat("Saved profile tables.\n")
