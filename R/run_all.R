# rebuild every output: the main analysis, the four supplements and the README figure
# each script runs in a fresh R process, as in docs/reproducibility.md
# Rscript --vanilla R/run_all.R

scripts <- c("04_run_analysis", "09_origin_adjustment", "10_geographic_sorting",
             "11_teaching_composition", "12_local_profiles", "13_plot_rural_coefficient")
for (script in scripts) {
  code <- sprintf('source("renv/activate.R"); source("R/%s.R")', script)
  status <- system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", "-e", shQuote(code, type = "cmd")))
  if (status != 0) stop(script, " did not finish")
}
