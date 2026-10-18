# Rural Origin, Teaching and Occupational Status among Graduates in China

*Research extension by Minghao Yang*

The positive rural coefficient in CGSS 2017 was not what I expected. Rural respondents are much less likely to report a completed higher-education qualification, and rural graduates in the sample are more concentrated at junior-college level. The occupational-score coefficient grows after adjustment for qualification tier, parental schooling, sex and age.

## Sample selection

Rural origin means village or township registration at age 14. County seats, suburbs and city districts form the urban category.

Of the 7,715 respondents in the 25–60 age window, 7,695 have a classifiable origin. The counts at each stage are below.

| Stage | Rural origin, N | % of 5,565 | Urban origin, N | % of 2,130 |
|---|---:|---:|---:|---:|
| Reports an identifiable higher-education tier | 743 | 13.4 | 1,019 | 47.8 |
| Has completed that highest qualification | 723 | 13.0 | 991 | 46.5 |
| Also has an eligible non-farm occupation | 702 | 12.6 | 933 | 43.8 |
| Final analytical sample | 701 | 12.6 | 912 | 42.8 |

Source: [selection_by_origin.csv](../output/tables/selection_by_origin.csv). Unweighted counts; completion refers to the highest reported qualification.

Most rural respondents are outside this graduate comparison. I read the positive coefficient against that large completion gap. Hout (1988) found little general status association between occupational origins and destinations among US graduates, even though people from higher-status families were more likely to graduate. In their study of Chinese men, Wu and Treiman (2007) found that selection into urban hukou made mobility among urban-hukou holders appear more open.

## Models and adjustment

The sample comprises 1,613 respondents who completed their highest reported higher-education qualification, whether junior college, a bachelor's or a postgraduate award, and have a current occupation (1,435 respondents) or a most recent non-farm job (178). Model 3 uses unweighted OLS. It regresses ISEI, scored with the syntax conversion in `ISCO08ConveRsions` (Schwitter, 2023), on qualification tier, rural origin, sex, approximate age and the higher available parental-schooling value, with junior college as the reference tier. Teaching participation uses a linear probability model with the same controls; weighted fits are reported as sensitivity checks.

The raw ISEI regression and Model 3 use the same 1,613 people. Adjustment raises the rural coefficient from 1.21 to 3.56 because the lower qualification levels, parental schooling and ages of rural graduates pull their raw occupational-score gap downwards, given the positive Model 3 slopes for each of these characteristics. To divide this 2.35-point rise, I multiply each rural–urban mean difference by its full-model slope, reverse the sign and add the terms within each control group.

| Control group | Increase in the rural coefficient |
|---|---:|
| Qualification tier | 0.98 |
| Parental schooling | 0.76 |
| Sex and age | 0.61 |

Education accounts for less than half of the rise. Brand and Xie (2010) found larger earnings gains from college among US adults less likely to complete it. Testing whether rural-origin students in China also gain more from higher education would require nongraduates as well as graduates and a way to address selection into higher education.

Parental schooling has the largest component when increments are averaged over the [six entry orders](origin-adjustment.md#entry-order).

**Table 1. Adjusted rural-minus-urban differences**

| Outcome and specification | N | Estimate | 95% confidence interval |
|---|---:|---:|---|
| ISEI, main controls | 1,613 | 3.56 points | 1.75 to 5.37, HC3 |
| ISEI, plus province indicators and survey weights | 1,613 | 2.81 points | 0.64 to 4.98, province clustered |
| Teaching, main controls | 1,613 | 8.93 percentage points | 5.22 to 12.64, HC3 |
| ISEI, positive-income sample | 1,347 | 3.46 points | 1.48 to 5.43, HC3 |
| Log 2016 labour income, same sample | 1,347 | −0.103 | −0.187 to −0.019, HC3 |

All rows use the Model 3 controls. Province indicators and clusters use interview location (28 provinces; see [measurement](measurement.md#models-and-inference)). Sources: [model coefficients](../output/tables/model_coefficients.csv), [province models](../output/tables/isei_province.csv), [teaching](../output/tables/occupation_adjusted.csv) and [income](../output/tables/income_comparison.csv).

## Teaching and employer sector

The excess teaching share is mostly in primary and secondary schools, with teaching recorded for 17.8% of rural graduates and 10.2% of urban graduates. With province indicators and weights among current workers, the adjusted teaching gap is 5.71 percentage points, with a province-clustered interval of 0.12–11.31.

Table 2 puts the teaching shares beside the Model 4 estimates of the ISEI gap within each tier. Both point estimates rise across tiers.

**Table 2. Teaching shares and adjusted ISEI gaps by qualification**

| Qualification | Rural teachers / N | Urban teachers / N | Teaching gap (pp) | ISEI gap (95% HC3 CI) |
|---|---:|---:|---:|---|
| Junior college | 46/338 | 27/358 | 6.1 | 2.15 (−0.54 to 4.84) |
| Bachelor | 63/322 | 54/476 | 8.2 | 4.46 (1.93 to 6.98) |
| Postgraduate | 16/41 | 12/78 | 23.6 | 6.65 (1.69 to 11.61) |

Teaching shares are unadjusted; Model 4 uses the full graduate sample and controls for sex, age and parental schooling. The rural postgraduate group has 41 respondents. I would not infer a tier gradient in the ISEI gap from this sample (interaction test, HC3 p = .216). Sources: [qualification counts](../output/tables/teaching_route_counts.csv), [full tier denominators](../output/tables/education_origin.csv) and [Model 4](../output/tables/within_tier_origin.csv).

Public institutions (*shiye danwei*) employ 100 of 114 current rural teachers and 65 of 84 urban teachers, while outside teaching their shares are almost equal at 15.2% and 15.9%. Table 3 broadens the comparison to all occupations within each sector, using 1,338 positive-income current workers with a known sector and the Model 3 controls.

**Table 3. Rural ISEI gaps within employer sectors**

| Sector | Adjusted gap | 95% HC3 interval |
|---|---:|---:|
| Public | 6.08 | 3.42 to 8.73 |
| State enterprise | 1.50 | −3.55 to 6.54 |
| Non-state enterprise and other | 0.01 | −2.70 to 2.72 |

Source: [sector contrasts](../output/tables/sector_contrasts.csv). The baseline joint test gives p = .005 under HC3 and .052 with province clustering.

The public point estimate stays largest with province indicators and weights. I want to trace how the teachers entered these public institutions.

## Occupational scores and income

School teaching scores highly in both ISEI conversions, and the rural coefficient is close to 0.2 outcome SD under either mapping. In the [occupation allocation](occupation-decomposition.md), shifting the reference from the sample mean to 80 reduces the teaching allocation from 2.10 points to roughly zero, with the sample and model otherwise unchanged.

People with the same occupation code receive the same ISEI score even if their salaries or hours differ, making Torche's (2011) distinction between occupational allocation and pay within occupations particularly relevant.

Among the same 1,347 positive-income workers, the rural ISEI coefficient is positive and the income coefficient negative. Adding province indicators brings the income estimate towards zero, with a province-clustered interval of −0.138 to 0.011. Weighted estimates are also negative, with intervals spanning zero. Wang et al. (2024) report an adjusted rural premium in monthly first-job wages for the 2010–2015 graduating cohorts, using hukou at college entry. The CGSS workers here are at different career stages, with annual labour income for 2016 and occupations reported in 2017.

## Conclusion

I keep the raw estimate beside Model 3 because rural graduates' lower credentials and parental schooling are themselves part of the inequality I want to describe.

Bernardi and Ballarino (2016) examine the link between social origin and occupational destination after education is taken into account. Model 3 approaches this issue through registered place at age 14. Adding the survey's current urban or rural classification raises the coefficient from 3.56 to 3.77 on the same sample; it also rises in the province fixed-effect and weighted models. Where graduate employment outside teaching is scarce, local job opportunities could help account for the concentration of rural graduates in teaching.

Teacher training and recruitment may help explain how rural graduates became concentrated in public-institution teaching. Later study offers another route into the graduate sample for teachers who began work without a higher-education qualification. In the proposed [county study](discussion.md), I would link first higher-education certificates to first appointments to see how often entry into teaching preceded entry into the graduate population.

## References

Bernardi, Fabrizio, and Gabriele Ballarino, eds. 2016. *Education, Occupation and Social Origin: A Comparative Analysis of the Transmission of Socio-Economic Inequalities*. Cheltenham: Edward Elgar. [doi:10.4337/9781785360459](https://doi.org/10.4337/9781785360459).

Brand, Jennie E., and Yu Xie. 2010. “Who Benefits Most from College? Evidence for Negative Selection in Heterogeneous Economic Returns to Higher Education.” *American Sociological Review* 75(2):273–302. [Article](https://doi.org/10.1177/0003122410363567).

Hout, Michael. 1988. “More Universalism, Less Structural Mobility: The American Occupational Structure in the 1980s.” *American Journal of Sociology* 93(6):1358–1400. [Article](https://doi.org/10.1086/228904).

National Survey Research Center, Renmin University of China. n.d. *Chinese General Social Survey 2017* [data set]. China National Survey Data Archive, project 94525591. [Data record](https://www.cnsda.org/index.php?id=94525591&r=projects%2Fview).

Schwitter, Nicole. 2023. *ISCO08ConveRsions: Converts ISCO-08 to Job Prestige Scores, ISCO-88 and Job Name*. R package version 0.2.0. [CRAN](https://CRAN.R-project.org/package=ISCO08ConveRsions).

Torche, Florencia. 2011. “Is a College Degree Still the Great Equalizer? Intergenerational Mobility across Levels of Schooling in the United States.” *American Journal of Sociology* 117(3):763–807. [doi:10.1086/661904](https://doi.org/10.1086/661904).

Wang, Huan, Claire Cousineau, Matthew Boswell, and Hongbin Li. 2024. “Estimating the Impact of Rural Hukou Status on Earnings for College Graduates in China.” *The China Quarterly* 259:677–695. [Article](https://doi.org/10.1017/S0305741024000274).

Wu, Xiaogang, and Donald J. Treiman. 2007. “Inequality and Equality under Chinese Socialism: The Hukou System and Intergenerational Occupational Mobility.” *American Journal of Sociology* 113(2):415–445. [Article](https://doi.org/10.1086/518905).

