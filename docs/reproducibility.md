# Reproducing the analysis

Use R 4.4.3 and run the commands below from the repository root. [renv.lock](../renv.lock) records package versions; [session information](session-info.txt) records the environment used for the saved results.

## Main analysis

Obtain CGSS 2017 through the [authorised access route](../data/raw/README.md) and save it locally as `data/raw/CGSS2017.sav`. The survey file is excluded from Git; its checksum is recorded with the data instructions.

Restore the packages, then run the analysis in a fresh process.

```sh
Rscript --vanilla -e 'source("renv/activate.R"); renv::restore(prompt = FALSE)'
Rscript --vanilla -e 'source("renv/activate.R"); source("R/04_run_analysis.R")'
```

The entry point calls the import, sample and scoring scripts, then the allocation, plotting, sample-context and sector scripts. It writes 40 CSVs, four figures and `docs/session-info.txt`. Rerunning replaces these outputs. In RStudio, opening [the project](../rural-origin-and-occupations-china.Rproj) activates the library through `.Rprofile`, with workspace loading and saving disabled.

## Adjustment supplement

The [origin-adjustment analysis](origin-adjustment.md) has a separate entry point.

```sh
Rscript --vanilla -e 'source("renv/activate.R"); source("R/09_origin_adjustment.R")'
```

It rebuilds the sample through scripts 01–03, then runs the same-sample regressions, decomposition and province bootstrap. Outputs go to `output/supplementary/origin-adjustment/`.

## Geographic supplement

```sh
Rscript --vanilla -e 'source("renv/activate.R"); source("R/10_geographic_sorting.R")'
```

This adds the survey's current urban–rural classification to Model 3 on the same 1,613 respondents. Results go to `output/supplementary/geographic-sorting/`.

## Teaching and composition supplement

```sh
Rscript --vanilla -e 'source("renv/activate.R"); source("R/11_teaching_composition.R")'
```

This fits the teaching models by age, sex and qualification route, then adds teaching, occupation and employer terms to Model 3. Results go to `output/supplementary/teaching-composition/`.

## Profile supplement

```sh
Rscript --vanilla -e 'source("renv/activate.R"); source("R/12_local_profiles.R")'
```

This scores occupations by the schooling and earnings of CGSS workers and refits Model 3 on each score. Results go to `output/supplementary/local-profiles/`. Both supplements take their bootstrap draws from [data/reference](../data/reference/README.md).

## Regenerating outputs from saved results

Two scripts regenerate outputs directly from saved tables, without the survey file.

```sh
Rscript --vanilla R/05_allocation_reference.R
Rscript --vanilla R/06_plot_mapping.R
```

They rebuild the reference-score table and mapping-contribution figure. The full pipeline already calls both.
