# Results guide

The scripts and saved outputs behind each result are listed below. The last column gives the table in the full version of my paper, *Rural Origin, Occupational Status and Labour Income among Graduates in China*.

| Result | Script | Outputs | Paper |
|---|---|---|---|
| Sample construction | [R/04](../R/04_run_analysis.R) | [sample flow](../output/tables/sample_flow.csv) | Table A1 |
| Descriptive characteristics | [R/11](../R/11_teaching_composition.R) | [descriptives](../output/supplementary/teaching-composition/descriptives.csv), [tier test](../output/supplementary/teaching-composition/tier_origin_test.csv) | Table 1 |
| Models 1 to 4 | [R/04](../R/04_run_analysis.R) | [model coefficients](../output/tables/model_coefficients.csv), [model fit](../output/tables/model_fit.csv), [tier contrasts](../output/tables/within_tier_origin.csv), [interaction tests](../output/tables/interaction_tests.csv) | Table 2 |
| Decomposition | [R/09](../R/09_origin_adjustment.R) | [control groups](../output/supplementary/origin-adjustment/decomposition_groups.csv), [bootstrap](../output/supplementary/origin-adjustment/bootstrap.csv) | Table 3 |
| Teaching | [R/04](../R/04_run_analysis.R), [R/11](../R/11_teaching_composition.R) | [occupation shares](../output/tables/occupation_origin.csv), [adjusted differences](../output/tables/occupation_adjusted.csv), [model coefficients](../output/tables/model_coefficients.csv), [route counts](../output/tables/teaching_route_counts.csv), [route contrasts](../output/supplementary/teaching-composition/route_contrasts.csv) | Table 4 |
| Teaching by age and sex | [R/11](../R/11_teaching_composition.R) | [age and sex differences](../output/supplementary/teaching-composition/teaching_by_age_sex.csv) | Section 4.3 |
| Adding teaching | [R/11](../R/11_teaching_composition.R) | [teaching indicator](../output/supplementary/teaching-composition/teaching_indicator.csv) | Table A4 |
| Occupation and employer | [R/11](../R/11_teaching_composition.R) | [adjusted coefficients](../output/supplementary/teaching-composition/composition.csv), [change](../output/supplementary/teaching-composition/composition_change.csv) | Table 5 |
| Employer sectors | [R/08](../R/08_sector_split.R) | [sector contrasts](../output/tables/sector_contrasts.csv), [sector tests](../output/tables/sector_tests.csv) | Table A3 |
| Occupational profiles | [R/12](../R/12_local_profiles.R) | [profiles](../output/supplementary/local-profiles/profiles.csv) | Tables A5 and A6 |
| Sensitivity | [R/04](../R/04_run_analysis.R) | [model coefficients](../output/tables/model_coefficients.csv), [province models](../output/tables/isei_province.csv), [scales](../output/tables/scale_comparison.csv), [income](../output/tables/income_comparison.csv) | Table A2 |

## Occupation and employer groups

The occupation and employer adjustment uses the 1,347 current workers with positive income. Two-digit ISCO groups with at least 20 of these workers stand alone and the rest are pooled within their one-digit group, giving [24 occupation groups](../output/supplementary/teaching-composition/occupation_groups.csv). Employers are public teaching, other public, state enterprise, non-state and other, and nine workers with an unknown sector.

## Occupational profiles

The profiles use 4,017 CGSS respondents aged 25 to 60 with a current occupation code outside farming (ISCO 6 and 921). Schooling uses the same year values as parental education, counted when the highest qualification was completed or the answer is no schooling or a literacy class (3,600 workers). Earnings are log 2016 labour income for the 3,687 with a positive amount.

A two-digit group stands alone if it has at least 30 workers, 30 schooling values, 20 earnings values and two provinces. Other workers are pooled within their one-digit group ([group counts](../output/supplementary/local-profiles/profile_groups.csv)). The groups are fixed before the folds are assigned. The armed forces have too few donors, so the five graduates coded there are excluded, leaving 1,342 ([counts](../output/supplementary/local-profiles/profile_sample.csv)).

Each worker's score is the group mean among workers in the other four folds, shrunk towards the one-digit mean with the weight of ten workers. Pooled groups take the one-digit mean. The ISEI profile averages the assigned ISEI scores in the same way. The common-donor rows use the 3,310 workers with both schooling and earnings.

Coefficients are divided by each score's standard deviation among the 1,342 graduates. The bootstrap resamples provinces for donors and graduates together, rebuilds the scores in each draw and keeps the groups, folds and standard deviations fixed.

## Bootstrap draws

The bootstrap intervals for the route contrasts, the teaching indicator, the occupation and employer adjustment and the occupational profiles come from analyses I first ran in Python. Scripts 11 and 12 repeat them in R with the province draws and folds from that run ([data/reference](../data/reference/README.md)), so the intervals match. The decomposition uses R's own draws in script 09.

## Two corrections

The first version of the paper says in its Technical Notes that sparse groups were combined within each held-out fold when they had fewer than 20 contributors. The rule is the one above, fixed on the whole pool. Its section 4.3 gives the p value for the three age bands as .067; it is .066.
