# ISCO-08 hierarchy

[ILO's occupation classification CSV](https://www.ilo.org/ilostat-files/ISCO/newdocs-08-2021/ISCO-08/ISCO-08%20EN.csv) is the source of `isco08_levels.csv`.

The source was read as Windows-1252 and restricted to `ISCO_version = ISCO-08`. Distinct codes from its `major`, `sub_major`, `minor` and `unit` columns give 10, 43, 130 and 436 nodes respectively: 619 in total. Codes use their official widths of one, two, three and four digits, including leading zeros for armed forces. The source drops those zeros: 0110 appears there as 110. The table covers the full classification, independently of the CGSS sample.

Read `code` as character data. For the four-character codes used in this project, match official unit codes first; otherwise match broader codes padded with zeros on the right. A final zero alone does not indicate a broad code: 2330 is a unit code.

SHA-256 of the downloaded source CSV:

```text
9afc6377d6ed6738d59aa0476777042e180397400d7dcd932e084045228b4d49
```

# Province draws

`province_draws.csv` holds the 1,999 bootstrap resamples of the 28 interview provinces used by scripts 11 and 12. Each row is one draw and gives how many times each province (`s41` code) was drawn. The draws come from NumPy's PCG64 generator with seed 42, which I used when I first ran these analyses in Python. Script 09 draws its own resamples in R.

# Profile folds

`profile_folds.csv` gives the fold, 0 to 4, of each of the 4,017 workers in the donor pool of script 12, in the order the pool is built from the survey file. The folds were dealt within occupational groups with NumPy (`default_rng(20261031)`). The file holds no survey values.
