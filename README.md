# Recheck of Fisher & Soyster (2019) smoking prediction preprint

Pankaj Kumar, November 2026. Independent work, not connected to any employer.

A reanalysis of Fisher & Soyster (2019), "Generating Accurate Personalized Predictions of Future Behavior: A Smoking Exemplar" (PsyArXiv, doi 10.31234/osf.io/e24v6), using the authors' public materials at osf.io/nkemg.

Main finding: AUCs below .50 were inverted before averaging (pROC's default `direction = "auto"`), which raises the mean elastic net AUC from .69 to .75 and naive Bayes from .71 to .78. Prediction is still above chance after correction. Full write-up in `FINDINGS.md`.

The authors were contacted before this was made public. Thanks to them for sharing data, code and results for every participant, which is what made this check possible.

## Running it

1. Download "Bundled Indivdual data_code_results for R.zip" from osf.io/nkemg and unzip it.
2. Point `OSF_DIR` at the `Individual Data_Analysis_Results` folder inside it.
3. From `scripts/`, run in order:

```
export OSF_DIR="/path/to/Individual Data_Analysis_Results"
Rscript --vanilla 01_audit.R      # writes audit.RDS, used by the rest
Rscript --vanilla 02_checks.R     # true AUCs and baselines, writes checks.RDS
Rscript --vanilla 06_direction.R  # flipped AUCs vs Table 3 (table3.csv)
Rscript --vanilla 07_verify_flip.R
Rscript --vanilla 08_comments.R
Rscript --vanilla 09_null_flip.R  # about a minute
```

03, 04 and 05 cover the weekday mapping, ping drift and training-data cutoffs. They need 01 and 02 to have run first.

Tested with R 4.6.1, glmnet 5.2, pROC 1.19.1 and Hmisc 5.3.0. A full run takes a few minutes.

`table3.csv` is Table 3 of the preprint, typed in by hand. Corrections welcome via an issue.

## The key check in one line

For any participant, compare `auc(roc(y ~ p))` with `auc(roc(y, p, direction = "<"))`, or with `somers2(p, y)["C"]`. They differ whenever the model ranked the test data the wrong way round.
