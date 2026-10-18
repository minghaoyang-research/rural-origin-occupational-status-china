# how the teaching allocation changes at different reference scores
# can run standalone: Rscript --vanilla R/05_allocation_reference.R

allocation <- read.csv("output/tables/occupation_contributions.csv")
membership <- read.csv("output/tables/occupation_adjusted.csv")
models <- read.csv("output/tables/model_coefficients.csv")
base <- allocation[allocation$reference == "Sample mean", ]
base_reference <- unique(base$reference_score)
total <- models$B[models$version == "primary" & models$model == "Model3" &
                    models$term == "rural_origin"]
stopifnot(length(base_reference) == 1, length(total) == 1)

# The membership models use 0/100 outcomes, so convert percentage points to proportions.
gamma <- setNames(membership$adjusted_difference_pp / 100, membership$occupation)
gamma <- c(gamma, Other = -sum(gamma), Total = 0)
refs <- c("Reference 50" = 50,
          "Urban mean" = unique(allocation$reference_score[allocation$reference == "Urban mean"]),
          "Sample mean" = base_reference,
          "Rural mean" = unique(allocation$reference_score[allocation$reference == "Rural mean"]),
          "Reference 70" = 70, "Reference 80" = 80)
reference_results <- lapply(names(refs), function(label) {
  shift <- refs[[label]] - base_reference
  b <- base$B - shift * unname(gamma[base$occupation])
  data.frame(reference = label, reference_score = refs[[label]], occupation = base$occupation,
             model_N = base$model_N, membership_B = unname(gamma[base$occupation]), B = b,
             share_of_total = if (total == 0) NA_real_ else b / total)
})
reference_results <- do.call(rbind, reference_results)
write.csv(reference_results, "output/tables/occupation_reference_sensitivity.csv", row.names = FALSE)
cat("Saved occupation_reference_sensitivity.csv.\n")
