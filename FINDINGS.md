# Replication check: Fisher & Soyster (2019)

"Generating Accurate Personalized Predictions of Future Behavior: A Smoking Exemplar"
PsyArXiv preprint, doi 10.31234/osf.io/e24v6. Materials: https://osf.io/nkemg

Checked 2026-11-02, rechecked 2026-11-03 (all scripts rerun, identical results). The authors were contacted and replied before this was made public. The preprint was never published in a journal.

## Bottom line

The published AUCs are inflated by an AUC direction problem. Any model that did worse than chance on future data was reported as if it did better than chance.

- Elastic net: published .75, corrected .69
- Naive Bayes: published .78, corrected .71

Prediction is still clearly above chance after the fix, so the headline numbers are inflated, but the main result is not reversed. About half of the "good" models also look good using time of day alone, which matters as much as the AUC fix.

This looks like an easy mistake to make with a default setting. The authors shared everything, which is the only reason it can be checked.

## Finding 1: below-chance models were flipped

pROC's `roc()` uses `direction = "auto"` by default. It looks at the test labels and picks whichever direction makes AUC at least .50. Confirmed on pROC 1.19.1: fully anti-predictive scores return AUC 1. No script sets `direction`.

Taking `max(AUC, 1 - AUC)` of the true AUCs reproduces Table 3:

| Model | Published mean | True mean | Flipped mean | People matching within .01, flipped | Same, true |
|---|---|---|---|---|---|
| Elastic net | .751 | .689 | .751 | 51 of 52 | 44 of 52 |
| Naive Bayes (RF selection) | .775 | .710 | .774 | 52 of 52 | 45 of 52 |

The published minimums (.50 and .52) were the first clue, since true AUCs go as low as .14. The one elastic net mismatch (participant 49: .65 true, .60 published) isn't explained by flipping and may be a typo.

Elastic net cases with true AUC below .50:

| ID | True EN | Published EN | True NB | Published NB |
|---|---|---|---|---|
| 004 | .26 | .74 | .19 | .81 |
| 014 | .35 | .65 | .60 | .60 |
| 015 | .17 | .83 | .17 | .83 |
| 017 | .27 | .73 | .25 | .75 |
| 020 | .48 | .52 | .70 | .70 |
| 059 | .14 | .86 | .23 | .77 |
| 063 | .20 | .80 | .39 | .61 |

Seven people are below chance for naive Bayes too, though not the same seven.

Verification for participant 004: Hmisc 5.3.0 `somers2` on the saved predictions gives C = .259. A fresh glmnet refit also gives .259 (r = 1.00 with the saved predictions). Training AUC is .91. So the model is real and it reversed on future data.

The scripts record `#AUC = 0.74` after the `somers2` line for this person, though `somers2` gives .259 and doesn't flip. The same is true for all seven below-chance people: the comment after `somers2` always equals the flipped `auc(roc())` value two lines later. The most likely reading is that the value was filled in from the `auc(roc())` output, but only the authors can say.

The saved data are what the authors actually ran. For all seven, the recorded `coords()` output in the script (threshold, specificity, sensitivity) matches pROC on the saved predictions to seven decimals, with pROC choosing `direction = ">"` (`08_comments.R`). So the flip happened in the original analysis, not in my rerun.

That also means the cutoffs for these people describe an inverted rule: "predict smoking when the model's score is *low*." That rule was learned from the test outcomes.

Test sets are small (10 to 33 observations; 004 has 12 with 3 positives), so individual AUCs are noisy. Below-chance results are expected sometimes, which is why they have to stay in the average.

Flipping also biases the mean upward even when there is no signal at all. With each person's test labels shuffled (500 runs), the saved elastic net predictions average .50 in a fixed direction and .62 after flipping (95% of runs .60 to .64). So .62 is the floor a no-signal model would reach under the published method, not .50 (`09_null_flip.R`).

## Finding 2: sensitivity and specificity cutoffs were picked on test data

The scripts call `coords(roc(...), "best")` on the test set, so the cutoff uses the outcomes it's being scored on. Choosing the cutoff on training data instead gives this for elastic net:

| | Published | Cutoff from training data |
|---|---|---|
| Sensitivity | .79 | .61 |
| Specificity | .78 | .69 |

## Finding 3: much of the signal is time of day

Baselines were fit on training data only and scored on true AUC.

| Model | Mean true AUC |
|---|---|
| Naive Bayes (RF selection) | .71 |
| Elastic net | .69 |
| Smoking rate by time of day only | .61 |
| Clock, weekday and cycles only (elastic net) | .61 |
| Current smoking plus clock (elastic net) | .61 |
| Persistence (current smoking only) | .47 |

- Elastic net beats current smoking plus clock by .08 (better in 39 of 52, Wilcoxon p = 8e-5), so the psychological items do add something.
- 15 of the 31 elastic net models at .70 or above also reach .70 on the time-of-day rate alone.
- The two "perfect" participants the paper discusses (38 and 76) get .94 and 1.00 from time of day alone. The paper interprets which psychological variables predicted them, so that interpretation deserves another look.

Corrected AUC is still above chance (EN p = 2e-8, NB p = 3e-9), and it beats the time-of-day rate by .08 for EN and .10 for NB.

## Finding 4: smaller coding errors

These are real errors, but they barely change the scores.

- **Copy-pasted weekday mapping:** 002 and 021 keep "1 = Wednesday (9/20/2017)", but their data start on 9/24 (Sunday) and 9/29 (Friday). All weekday labels are wrong for them.
- **Misaligned rows in 007:** ping labels drift after about row 24, so "ping 3" lands at 7am. 32% of rows disagree with the clock, and weekday labels are wrong in 58%.
- **Effect of correcting weekdays:** EN AUC moves .889 to .867 (002), .883 to .900 (021) and .963 to .985 (007). Ping labels in 007 were not corrected.
- **Median split:** the high-smoking target for 16 people uses the median of the full series, including test data. Not measured.

## What checked out

- 52 participants with sequential train and test splits, as described. Training comes first.
- `difftime` units are hours for all 52, so the 24-hour and 12-hour cycles are valid.
- No target-derived column is used as a predictor. Current smoking is, legitimately.
- Target choice follows a consistent pattern: the high-smoking target is used for people who smoke at nearly every ping.
- Scripts, saved data and comments are complete enough to check.

## Limits

- I used the saved predictions and objects. I didn't rerun all 52 scripts from the raw CSVs, which aren't in the bundle.
- A fresh refit on six people matched closely for three, and differed somewhat for 015, 059 and 063. For 014 it selected no variables, so results depend on glmnet version.
- Baselines use the same small test sets, so person-level differences are noisy.
- I did not recompute the paper's between-person ridge models, or naive Bayes sensitivity and specificity from training cutoffs.
- I didn't check whether later papers reused this code. The preprint itself was never published in a journal. Beck & Jackson (2022) cite this paper, so the .80 figure has been passed on.


## Files

Run from `scripts/` with `Rscript --vanilla <script>`, after setting `OSF_DIR` (see README).

- `01_audit.R`: units, predictor columns, targets
- `02_checks.R`: timestamps, true AUCs, baselines
- `03_detail.R`: weekday cases and target rule
- `04_weekday.R`: weekday correction refit
- `05_claim.R`: cutoffs and ping drift
- `06_direction.R`: flipped AUCs vs Table 3 (`table3.csv`)
- `07_verify_flip.R`: refit check on below-chance people
- `08_comments.R`: script comments vs saved data for below-chance people
- `09_null_flip.R`: what flipping does with shuffled labels

Tested with R 4.6.1, glmnet 5.2, pROC 1.19.1, Hmisc 5.3.0. Set `OSF_DIR` to the extracted `Individual Data_Analysis_Results` folder if it isn't at `../upstream/extracted/`.

## Sources

- https://osf.io/nkemg
- https://psyarxiv.com/e24v6
- https://doi.org/10.1177/09567976221093307 (Beck & Jackson, 2022, which cites the preprint)
