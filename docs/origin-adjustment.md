# Adjustment of the rural-origin coefficient

*Supplementary analysis of Model 3.*

This calculation breaks down the increase from the raw rural–urban gap to Model 3 in the [research note](research-note.md#models-and-adjustment). Both fits use the same 1,613 respondents, 701 rural and 912 urban.

## Calculation

The calculation uses the omitted-variable formula, developed more generally by Gelbach (2016) for decomposing coefficient changes. For each control, multiply its rural-minus-urban mean difference by its Model 3 coefficient and reverse the sign. For example, rural graduates have 2.66 fewer years of parental schooling on average; multiplied by the Model 3 slope of 0.285, this gives a 0.76-point increase in the rural coefficient. Summing across all controls gives the full 2.35-point increase.

Junior-college qualifications account for 48.2% of rural graduates and 39.3% of urban graduates. The gaps in bachelor's and postgraduate shares contribute almost equally to the increase, because the smaller postgraduate share gap is multiplied by a much larger Model 3 coefficient. Parental schooling averages 8.21 years among rural graduates and 10.87 among urban graduates. Rural graduates are also younger, and age accounts for most of the demographic component. The [term table](../output/supplementary/origin-adjustment/decomposition_terms.csv) contains each mean, coefficient and product.

With an intercept and binary rural origin, residuals average to zero in each origin group, leaving the raw gap equal to the adjusted coefficient plus the control coefficients multiplied by their group-mean differences.

## Entry order

Adding qualification tier first raises the rural coefficient by 0.92 points. After parental schooling the same step gives 0.10. With sex and age already in, it gives 1.20. The steps differ because the controls are correlated.

The script fits all eight combinations of the three control groups, always including rural origin and using the same respondents. The [model table](../output/supplementary/origin-adjustment/models.csv) gives HC3 and province-clustered intervals. The six paths are in [sequences.csv](../output/supplementary/origin-adjustment/sequences.csv); [order_summary.csv](../output/supplementary/origin-adjustment/order_summary.csv) gives the smallest, largest and average step for each block across those paths.

| Control group | Full-model allocation | Average over six orders |
|---|---:|---:|
| Qualification tier | 0.982 | 0.641 |
| Parental schooling | 0.760 | 0.873 |
| Sex and age | 0.606 | 0.833 |

The full-model allocation uses Model 3 slopes regardless of entry order. Each sequential step uses the slopes estimated with the controls already included, so averaging the six paths gives a different allocation.

## Sensitivity

The three components stay positive with survey weights, the overview ISEI conversion and a restriction to current occupations. With weights, the raw gap is only 0.17 and the adjusted gap is 3.21. Among current workers, the demographic component falls to 0.24. The [four versions](../output/supplementary/origin-adjustment/sensitivity.csv) each hold the sample and weights fixed between the raw and adjusted fits.

Resampling the 28 [interview provinces](measurement.md#models-and-inference) with replacement gives an approximate 95% percentile interval of 1.57–2.93 for the total increase (1,999 draws; seed 42). The [bootstrap intervals](../output/supplementary/origin-adjustment/bootstrap.csv) for education minus either other component cross zero.

## Running the supplement

Run the [supplement command](reproducibility.md#adjustment-supplement) from a fresh R process. Script 09 rebuilds the sample through scripts 01–03 and writes to `output/supplementary/origin-adjustment/`.

Gelbach, Jonah B. 2016. “When Do Covariates Matter? And Which Ones, and How Much?” *Journal of Labor Economics* 34(2):509–543. [Article](https://doi.org/10.1086/683668).
