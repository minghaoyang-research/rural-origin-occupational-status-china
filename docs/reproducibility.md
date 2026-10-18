# Reproducing and checking the analysis

Use R 4.4.3 and run the commands below from the repository root. [renv.lock](../renv.lock) records package versions; [session information](session-info.txt) records the environment used for the saved results.

## Data and environment

Obtain CGSS 2017 through the [authorised access route](../data/raw/README.md) and save it locally as `data/raw/CGSS2017.sav`. The survey file is excluded from Git; its checksum is recorded with the data instructions.

Restore the packages, then run the analysis in a fresh process.

```sh
Rscript --vanilla -e 'source("renv/activate.R"); renv::restore(prompt = FALSE)'
Rscript --vanilla -e 'source("renv/activate.R"); source("R/04_run_analysis.R")'
```

The entry point calls the import, sample and scoring scripts, then the allocation, plotting, sample-context and sector scripts. It writes 40 CSVs, four figures and `docs/session-info.txt`. Rerunning replaces these outputs. In RStudio, opening [the project](../rural-origin-and-occupations-china.Rproj) activates the library through `.Rprofile`, with workspace loading and saving disabled.

## Checks without the survey file

```sh
Rscript --vanilla tools/check_results.R
Rscript --vanilla -e 'source("renv/activate.R"); source("tools/check_helpers.R")'
```

The first checks the main sample counts and inference, coefficient contrasts, occupation allocations and adjustment decomposition against the saved tables. The second tests coding, province row matching, contrast standard errors and bootstrap frequency weights on constructed data. Run both after the main analysis and the two supplements below.

Two scripts can also regenerate outputs directly from saved tables.

```sh
Rscript --vanilla R/05_allocation_reference.R
Rscript --vanilla R/06_plot_mapping.R
```

They rebuild the reference-score table and mapping-contribution figure. The full pipeline already calls both.

## Adjustment supplement

The [origin-adjustment analysis](origin-adjustment.md) has a separate entry point.

```sh
Rscript --vanilla -e 'source("renv/activate.R"); source("R/09_origin_adjustment.R")'
```

It rebuilds the sample through scripts 01–03, then runs the same-sample regressions, decomposition and province bootstrap. Outputs go to `output/supplementary/origin-adjustment/`; the main tables and figures are unchanged.

## Geographic supplement

```sh
Rscript --vanilla -e 'source("renv/activate.R"); source("R/10_geographic_sorting.R")'
```

This adds the survey's current urban–rural classification to Model 3 on a matched sample. Results go to `output/supplementary/geographic-sorting/`.
