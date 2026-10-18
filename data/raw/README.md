# CGSS 2017 data

Obtain CGSS 2017 from the [China National Survey Data Archive, project 94525591](https://www.cnsda.org/index.php?id=94525591&r=projects%2Fview). The survey data are not distributed with this repository: [CNSDA's terms](https://www.cnsda.org/doc/CNSDA_Diisclaimer.html) require written permission to provide data to third parties.

The scripts use the original SPSS file with 12,582 respondents and 786 survey variables. Keep its variable names and value labels and save the file as `data/raw/CGSS2017.sav`.

[CGSS2017.sha256](CGSS2017.sha256) records the source-file checksum. From the repository root, check the downloaded file with:

```sh
shasum -a 256 -c data/raw/CGSS2017.sha256
```

Data were provided by the National Survey Research Center at Renmin University of China. The analysis and interpretation are my responsibility. The data and questionnaire are listed in the [references](../../docs/references.md).
