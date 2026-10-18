# Measurement and sample

## Sample

Starting from the full CGSS 2017, I keep respondents between 25 and 60 (age computed as `2017 - A31`; no birthday recorded) who completed their highest reported higher-education qualification, have a current or most recent non-farm occupation that maps to ISEI, an age-14 origin response, and usable education for at least one parent. That leaves 1,613. The [sample flow](../output/tables/sample_flow.csv) shows each step.

## Education

The main models pool adult and regular qualifications into three tiers. Junior college is the reference.

| Tier | A7A codes |
|---|---|
| Junior college | 9 (adult), 10 (regular) |
| Bachelor | 11 (adult), 12 (regular) |
| Postgraduate | 13 |

Completion means A7B=4 (毕业) for the highest qualification reported in A7A.

At ages 25–60 this excludes 37 still studying, five dropouts, five who attended without graduating and one unknown. [Completion counts](../output/tables/completion_status.csv) show origin and occupation-code availability before the occupation, origin and parental-education filters. A7A does not identify a lower completed qualification for someone reporting an unfinished higher level.

One respondent has no A7A code but writes 大专 in the open-ended A7AA field. I count this as junior college. The other text responses, 电大(成人教育) and 党校毕业, do not identify a degree tier, so I leave them unclassified.

The education-route model separates the five A7A categories, with regular junior college as the reference. It leaves out the 大专 respondent because the route is unknown. Postgraduate education has only code 13, with no route distinction. The regular-education restriction keeps codes 10, 12 and 13 (N=1,121).

## Selection into the graduate sample

The [selection table](../output/tables/selection_by_origin.csv) starts with all 7,715 respondents in that age range. Twenty have no classifiable A27H origin, leaving denominators of 5,565 rural and 2,130 urban respondents. The nested stages are an identifiable higher-education tier; A7B=4 for that tier; an eligible non-farm occupation; and the final sample with parental education.

The percentages are unweighted, with all age-eligible respondents of known origin in each denominator, including those with unfinished or unclassified education and those who skip A7B.

## Occupational status

Occupational status is measured from the current or most recent non-farm occupation reported in 2017. I prefer the current main occupation (A59), available for 1,435 respondents. The other 178 report a previous non-farm occupation in A60, with 175 not currently working and three farming (A58=5 and 2 respectively; see [sample composition](../output/tables/sample_composition.csv)). The current-occupation-only model leaves these respondents out.

For ISEI I use `ISCO08ConveRsions::isco08toisei08()` (v0.2.0), which follows the more recently revised SPSS syntax modules. The alternative, `isco08toisei08_2()`, uses the overview table ([Ganzeboom, 2010b; Schwitter, 2023](references.md)).

For overview ISCO 3314 the package returns 61 but the [original table](http://www.harryganzeboom.nl/isco08/isco08_with_isei.pdf) has 63. I use 63. The [crosswalk](../output/tables/isei_mapping.csv) keeps the package values in `overview_package` and the scores actually used.

For SIOPS prestige scores ([Treiman, 1977](references.md)) I use `ISCO08ConveRsions::isco08tosiops08()`. This and the syntax ISEI function follow [Ganzeboom and Treiman's ISMF conversion tools](references.md). The [scale comparison](../output/tables/scale_comparison.csv) fits Model 3 on all 1,613 respondents for each scale and reports the rural coefficient in raw units and divided by the outcome's sample standard deviation.

The conversion takes four-digit ISCO strings, including leading zeros such as `0000` for Armed Forces. Negative survey codes are missing. I match each recorded code to the [ILO hierarchy](../data/reference/README.md) to tell unit groups from broader occupational groups ([coding table](../output/tables/occupation_coding.csv)). A separate check refits Model 3 under both ISEI mappings using only unit-group records.

## Social origin

Rural and urban origin use registered place at age 14 (A27H). The main models group villages (1) and townships (2) as rural; county seats (3), suburbs (4) and city districts (5) are urban. I also fit a model with separate village and township categories. In Model 7 I use residence at age 14 (A27F) with the same split, to see whether residence gives a different rural-origin estimate from registered place.

Hao, Hu and Lo ([2014](references.md)) distinguish hukou status from pre-tertiary school location. This project uses A27H registered place at age 14, a separate measure.

## Parental education

I recode the father's (A89B) and mother's (A90B) education into approximate years of schooling.

| Source category | Years |
|---|---:|
| 1: no schooling | 0 |
| 2: traditional private school or literacy class | 2 |
| 3: primary school | 6 |
| 4: junior secondary | 9 |
| 5-8: upper secondary or vocational school | 12 |
| 9-10: junior college | 15 |
| 11-12: bachelor | 16 |
| 13: postgraduate | 19 |
| 14, 98, 99, missing | Missing |

I take whichever parent has the higher usable value, or the single usable value when only one is available. If neither is available, the respondent is excluded.

## Current organisation and parental employment

The [employer description](../output/tables/employer_context.csv) uses the 1,435 members of the main sample with current A59 occupations. All have A58=1 (currently working in non-farm employment). Teaching uses the same ISCO prefix 23 as the main analysis. It tabulates A59J=3 (事业单位, public institution), A59J=2 (enterprise), and all remaining or unreported types, by origin and teaching. Each share divides by all current workers in that origin/occupation group. The five unknown/refused A59J responses are included in the residual category. These are unweighted counts.

The [item-coverage table](../output/tables/context_coverage.csv) separates respondents directed to each question from those who supplied a valid answer.

| Item | Categories used to identify a valid response | Routing |
|---|---|---|
| A59J, current organisation type | 1 government; 2 enterprise; 3 public institution; 4 social organisation/community committee; 5 no unit/self-employed; 6 military; 7 other | Current non-farm workers |
| A59K, current ownership | 1 state/state-controlled; 2 collective; 3 private; 4 Hong Kong/Macao/Taiwan; 5 foreign; 6 other | Skipped for A59J=1, 5, 6 |
| A59B, written contract | 1 none; 2 indefinite term; 3 fixed term | Skipped for A59A=1, 2, 5, 7, 8 |
| A89D/A90D, parental employment at respondent age 14 | 1–17, including employment, farming, non-employment and deceased | All main-sample respondents |
| A89G/A90G, parental organisation type | Same 1–7 categories as A59J | Skipped when parental D=11–16 |
| A89H/A90H, parental ownership | Same 1–6 categories as A59K | Also skipped when parental G=1, 5, 6 |

Unknown/refused values (98/99) and system missing are excluded from `valid_N`; routed skips have their own column. A59J provides the organisation type for almost all current workers. Personal *bianzhi* is not recorded.

Parental ownership is only available for 819 fathers and 681 mothers. Most unavailable values come from questionnaire skips based on parental employment status or organisation type. Adding both ownership measures as controls would shrink the sample considerably, so the main models stick with parental education.

## Employer sector

The sector comparison in [R/08_sector_split.R](../R/08_sector_split.R) combines A59J and A59K into three sectors for current non-farm workers.

| Sector | Definition |
|---|---|
| Public | A59J = 1 government, 3 public institution or 6 military |
| State enterprise | A59J = 2 enterprise with A59K = 1 state-owned or state-controlled |
| Non-state enterprise and other | A59J = 2 with A59K = 2–6; A59J = 4 social organisation or community committee, 5 no unit or self-employed, 7 other |

Sector is missing for 11 of 1,435 current workers and 9 of 1,347 positive-income workers because organisation type or enterprise ownership is unknown. The samples with known sector therefore contain 1,424 and 1,338 respondents ([sector flow](../output/tables/sector_flow.csv)). The coding is in `employer_sector()` in [analysis_helpers.R](../R/analysis_helpers.R).

The [support table](../output/tables/sector_support.csv) identifies interview provinces containing both origins within each sector. In state enterprises, the income sample covers 17 such provinces.

Both log 2016 labour income and ISEI use the 1,338 positive-income workers with a known sector. Each model adds sector indicators and rural-origin-by-sector interactions to the Model 3 controls, with public employment as the reference. I fit this model with and without interview-province indicators, then repeat both with survey weights. The other control slopes are shared across sectors.

A sector's rural–urban gap adds its interaction to the rural-origin coefficient. Standard errors use the full covariance matrix, including the covariance between these terms.

The teaching models replace sector with a teaching indicator (ISCO 23), using all 1,347 positive-income workers and then the 463 public-sector workers. Within the public sector, one province contains a single respondent. A province indicator would fit that person exactly, leaving HC3 undefined; these fits therefore omit province indicators while retaining province-clustered intervals.

The saved outputs contain [coefficients](../output/tables/sector_coefficients.csv) other than province terms, [within-group differences](../output/tables/sector_contrasts.csv), [joint tests and leverage](../output/tables/sector_tests.csv), and [teaching-by-sector counts](../output/tables/sector_teaching.csv).

Occupation-code tables omit respondent counts and origin breakdowns, with counts reported for broader groups. Employer and sector exports combine small categories or missing reasons.

## Models and inference

The seven primary models use unweighted OLS on the same sample. HC3 standard errors allow for unequal residual variance; the tables also retain classical results. Junior college, male and urban origin are the reference categories.

| Model | Variables added / specification |
|---|---|
| 1 | Education tier, female and age |
| 2 | Model 1 plus parental education |
| 3 | Model 2 plus rural origin |
| 4 | Model 3 plus education-by-origin interactions |
| 5 | Model 3 with cohort indicators replacing age |
| 6 | Model 5 plus education-by-cohort interactions |
| 7 | Model 3 with A27F replacing A27H |

For Model 4, the rural-minus-urban gap at junior college is the rural-origin coefficient. The bachelor and postgraduate gaps add the corresponding education-by-origin interaction. Their confidence intervals use the full HC3 covariance matrix.

Models 5 and 6 use birth cohorts 1957-64 (reference), 1965-74, 1975-84 and 1985-92. With one survey year, cohort is confounded with age and career stage.

Weighted fits use the supplied `weight`. Province-clustered standard errors use HC1 and interview province (`s41`, 28 provinces). Classical and HC3 intervals and t tests use residual degrees of freedom; province-clustered results use G − 1 (27 here). Joint F tests use q numerator degrees of freedom for q interactions, with the denominator following the same rule.

The [ISEI province comparison](../output/tables/isei_province.csv) adds interview-province indicators to Model 3 and repeats the fits with survey weights, keeping the full (N=1,613) and current-occupation (N=1,435) samples fixed. Province is recorded at the 2017 interview, including for respondents reporting a previous job.

The file has province, city and county codes (`s41`-`s43`). How these map to the design strata or the street-level sampling units in the largest cities is unclear from the available documentation. The [Cycle II sampling plan](https://www.sinoss.net/uploadfile/2011/1114/20111114090957644.pdf) places some strata across provincial boundaries and uses streets as PSUs in the certainty cities, so the weighted and province-clustered comparisons do not reconstruct the actual design.

## Occupations and qualification dates

For the occupation check I drop teaching professionals (ISCO 23), nursing and midwifery professionals (222) and their associate professionals (322), then refit Model 3 under both ISEI mappings on the remaining 1,361 respondents. The separate [occupation allocation](occupation-decomposition.md) retains the full sample. The occupation tables also separate university (ISCO 231), secondary (233) and primary (2341) teaching.

Some teaching records retain broader [ISCO categories](https://isco.ilo.org/en/isco-08/). Code `2300` identifies teaching professionals at the sub-major-group level, and `2350` identifies other teaching professionals at the minor-group level. I keep these codes and use their entries in each conversion table, without assigning a more specific school level. [Teaching codes](../output/tables/teaching_codes.csv) gives each code's name, coding level and all three scores.

Two linear probability models use the Model 3 controls on the full sample, with teaching and nursing/midwifery each coded 100/0 so the coefficients read as adjusted percentage-point differences.

For teaching, I also restrict the sample to the 1,435 current non-farm workers, add interview-province indicators, then apply `weight` to that specification. [Teaching checks](../output/tables/teaching_checks.csv) report HC3 and province-clustered intervals.

The [qualification-category comparison](../output/tables/teaching_routes.csv) uses 1,612 respondents with a known A7A category. The two fits pool or separate adult and regular junior-college and bachelor's qualifications; postgraduate education stays separate. Both control for sex, age and parental education and estimate a single rural-origin coefficient across qualification categories. I repeat them for 1,435 current workers with province indicators and survey weights ([category counts](../output/tables/teaching_route_counts.csv)).

The timing gap is `A7C - (2017 - A59M)`, the year of the highest completed qualification minus estimated entry into the current workplace. A59M is tenure rounded upward, so I allow a one-year margin. Gaps below -1 count as qualification before entry, -1 to +1 as close together, and above +1 as qualification after entry.

The timing sample has 1,369 current workers with a qualification year between birth and 2017 and tenure no longer than their age. I also check a narrower sample requiring qualification at age 17 or older and estimated entry into the current workplace at 15 or older. This removes 16 records. Both sets of counts are kept in [qualification_timing.csv](../output/tables/qualification_timing.csv), under `reported_dates` and `age_screen`.

Replacing A59M with A59c gives a second gap based on cumulative years worked since the first non-farm job. A59c is also rounded upward and uses the same date rules. The `matched_*` rows compare the two gaps on respondents with both durations; `consistent_*` additionally requires cumulative work years to be at least current-employer tenure. Counts for each screen are in the timing table.

Cumulative working years omit employment breaks, and current-employer tenure can begin after a school move. A7C dates the highest award, including upgrades from an earlier degree. None of these items dates the first teaching appointment.

## Income

Income is annual personal labour income for 2016 (A8B). Of the 1,435 with a current occupation, 1,347 report a usable positive amount. Code 9999996 denotes an amount above the questionnaire range. The one such response is excluded and counted separately in the sample flow.

I fit log income and ISEI with the Model 3 predictors on these 1,347, then add interview-province indicators (`s41`), then repeat both with survey weights. HC3 and province-clustered intervals are in the table.

[Income availability](../output/tables/income_availability.csv) groups all 1,435 current workers by origin and teaching occupation, separating positive income, zero income and unavailable exact amounts.

Usual weekly hours in 2017 come from A53aa for respondents who worked in the preceding week (A53=4), and A53a for those temporarily away from work (A53=2 or 3). I keep values from 1 to 168, leaving 1,318 income respondents. Both fits use the Model 3 predictors and province indicators on these respondents; one adds log weekly hours. Results are in [income_hours.csv](../output/tables/income_hours.csv).
