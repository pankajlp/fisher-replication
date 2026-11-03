# What does flipping do to models with no real signal? Shuffle each person's test labels,
# score the saved elastic net predictions, and compare the true and flipped means.
root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
aud = readRDS("audit.RDS"); ids = aud$o$id
auc = function(s, y) { ok = !is.na(s) & !is.na(y); s=s[ok]; y=y[ok]; n1=sum(y==1); n0=sum(y==0); if (!n1||!n0) return(NA); (sum(rank(s)[y==1]) - n1*(n1+1)/2)/(n1*n0) }
set.seed(2019); B = 500; M = matrix(NA, B, length(ids))
for (j in seq_along(ids)) { id = ids[j]; e = new.env(); suppressWarnings(load(list.files(file.path(root,id), pattern="\\.[Rr][Dd]ata$", full.names=TRUE)[1], envir=e))
  y = e$dat2[[aud$o$targets[j]]]; p = e$dat2$netpred; M[,j] = replicate(B, auc(p, sample(y))) }
tru = rowMeans(M, na.rm=TRUE); fl = rowMeans(pmax(M, 1-M), na.rm=TRUE)
cat(sprintf("Shuffled labels, %d runs x %d people\n  mean AUC, fixed direction: %.3f (95%% of runs %.3f to %.3f)\n  mean AUC, flipped:         %.3f (95%% of runs %.3f to %.3f)\n",
  B, length(ids), mean(tru), quantile(tru,.025), quantile(tru,.975), mean(fl), quantile(fl,.025), quantile(fl,.975)))
