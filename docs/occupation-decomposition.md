# Occupation allocation and reference scores

At the sample-mean reference, teaching is assigned 2.10 of the 3.56 fitted rural ISEI points. The table changes the reference while keeping all 1,613 respondents and the Model 3 predictors fixed.

The sample, urban and rural means are close, between 55.95 and 57.17. I also use references of 50, 70 and 80 to see how far the allocation moves away from those means.

| Reference | Teaching | Nursing and midwifery | Other occupations | Total | Teaching / total |
|---|---:|---:|---:|---:|---:|
| 50 | 2.676 | 0.171 | 0.713 | 3.560 | 75.2% |
| Urban mean (55.954) | 2.144 | 0.122 | 1.294 | 3.560 | 60.2% |
| Sample mean (56.481) | 2.097 | 0.117 | 1.346 | 3.560 | 58.9% |
| Rural mean (57.167) | 2.036 | 0.112 | 1.412 | 3.560 | 57.2% |
| 70 | 0.890 | 0.006 | 2.665 | 3.560 | 25.0% |
| 80 | -0.003 | -0.077 | 3.641 | 3.560 | -0.1% |

Source: [reference-score table](../output/tables/occupation_reference_sensitivity.csv), calculated by [`R/05_allocation_reference.R`](../R/05_allocation_reference.R).

<details>
<summary>Calculation</summary>

For group *g*, fit `(ISEI - c) × group_g` to the Model 3 predictors, including an intercept. Write the rural coefficient as `b_g(c)`, and the rural coefficient from a regression of the 0/1 group indicator on those predictors as `gamma_g`.

```text
b_g(c) = b_g(c0) - (c - c0) × gamma_g
```

Changing the reference subtracts `(c - c0) × group_g` from the outcome. OLS is linear in that outcome, giving the identity above. The teaching membership coefficient is 0.0893, so each additional reference-score point subtracts 0.0893 from its allocation. Across all groups, the membership coefficients sum to zero and the allocations continue to sum to the Model 3 rural coefficient.

</details>
