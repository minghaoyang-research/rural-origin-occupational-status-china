# ISCO-08 hierarchy

[ILO's occupation classification CSV](https://www.ilo.org/ilostat-files/ISCO/newdocs-08-2021/ISCO-08/ISCO-08%20EN.csv) is the source of `isco08_levels.csv`.

The source was read as Windows-1252 and restricted to `ISCO_version = ISCO-08`. Distinct codes from its `major`, `sub_major`, `minor` and `unit` columns give 10, 43, 130 and 436 nodes respectively: 619 in total. Codes retain their official widths of one, two, three and four digits, including leading zeros for armed forces. The table covers the full classification, independently of the CGSS sample.

Read `code` as character data. For the four-character codes used in this project, match official unit codes first; otherwise match broader codes padded with zeros on the right. A final zero alone does not indicate a broad code: 2330 is a unit code.

SHA-256 of the downloaded source CSV:

```text
9afc6377d6ed6738d59aa0476777042e180397400d7dcd932e084045228b4d49
```
