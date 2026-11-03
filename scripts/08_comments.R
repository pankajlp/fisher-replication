# Do the commented outputs in the authors' scripts match what the saved data give now?
# coords() comments match pROC's auto direction, while somers2() on the same data gives 1 - AUC,
# so the "#AUC" comments after somers2 can't be somers2's own output for the below-chance people.
suppressMessages({library(pROC); library(Hmisc)})
root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
aud = readRDS("audit.RDS")
cat("Hmisc", as.character(packageVersion("Hmisc")), " pROC", as.character(packageVersion("pROC")), "\n")
for (id in c("004","014","015","017","020","059","063")) {
  e = new.env(); suppressWarnings(load(list.files(file.path(root,id), pattern="\\.[Rr][Dd]ata$", full.names=TRUE)[1], envir=e))
  t = aud$o$targets[aud$o$id==id]; y = e$dat2[[t]]; p = e$dat2$netpred
  r = roc(y~p, quiet=TRUE); c0 = coords(r, "best", ret=c("threshold","specificity","sensitivity"))
  s = readLines(list.files(file.path(root,id), pattern="\\.[Rr]$", full.names=TRUE)[1], warn=FALSE)
  i = grep("coords\\(\\(roc\\(dat2\\$[A-Za-z]+~dat2\\$netpred", s)[1]
  cat(sprintf("%s somers2 C %.3f | pROC auto: dir '%s' AUC %.3f, best thr %.4f spec %.3f sens %.3f\n     script comment: %s\n",
    id, somers2(p,y)[1], r$direction, auc(r), c0$threshold[1], c0$specificity[1], c0$sensitivity[1], trimws(s[i+2])))
}
