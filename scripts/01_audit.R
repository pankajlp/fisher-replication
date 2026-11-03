root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
ids = list.dirs(root, recursive = FALSE, full.names = FALSE); cat("participants:", length(ids), "\n")
rows = list(); cols = list()
for (id in ids) {
  d = file.path(root, id); rd = list.files(d, pattern="\\.[Rr][Dd]ata$", full.names=TRUE); rs = list.files(d, pattern="\\.[Rr]$", full.names=TRUE)
  if (!length(rd) || !length(rs)) { cat(id, "missing rd/rs", length(rd), length(rs), "\n"); next }
  e = new.env(); load(rd[1], envir=e); src = readLines(rs[1], warn=FALSE)
  get1 = function(n) if (exists(n, envir=e, inherits=FALSE)) get(n, envir=e) else NULL
  dat1 = get1("dat1"); dat2 = get1("dat2"); data = get1("data"); datx = get1("datx")
  if (is.null(dat1)) { cat(id,"no dat1; objs:",head(ls(e),12),"\n"); next }
  # units difftime would pick for this person's timestamps
  st = if (!is.null(data) && "start" %in% names(data)) strptime(data$start, "%m/%d/%Y %H:%M") else NULL
  unit = if (!is.null(st)) units(diff(as.POSIXct(st[!is.na(st)]))) else NA
  gapmin = if (!is.null(st)) min(as.numeric(diff(as.POSIXct(st[!is.na(st)])), units="mins")) else NA
  # column index lines
  m = grep("^\\s*mat1\\s*=\\s*as.matrix\\(", src, value=TRUE)
  allc = c()
  for (l in m) { ex = sub(".*dat1\\[,(c\\(.*\\))\\]\\).*", "\\1", l); ix = tryCatch(eval(parse(text=ex)), error=function(x) NULL); if (!is.null(ix)) allc = c(allc, names(dat1)[ix]) }
  allc = unique(allc); cols[[id]] = allc
  y = grep("glmnet\\(mat1,dat1\\$(\\w+)", src, value=TRUE); ty = unique(sub(".*dat1\\$(\\w+).*","\\1",y))
  bad = grep("fw$|^cig|^filter|even|netpred", allc, value=TRUE); bad = setdiff(bad, c("mornfw","midfw","evefw","nightfw","monfw","tuesfw","wedfw","thursfw","frifw","satfw","sunfw"))
  auc = grep("AUC|auc", src, value=TRUE)
  rows[[id]] = data.frame(id=id, n1=nrow(dat1), n2=nrow(dat2), unit=unit, gapmin=gapmin, targets=paste(ty,collapse=","), nfeat=length(allc), flagged=paste(bad,collapse=","), ins=sum(grepl("InsertRow\\(", src)), nmods=sum(grepl("somers2\\(", src)), ybal=round(mean(dat2[[ty[1]]],na.rm=TRUE),2))
}
o = do.call(rbind, rows); options(width=170); print(o, row.names=FALSE)
cat("\nunit table:"); print(table(o$unit, useNA="a"))
cat("\nall column names used anywhere, with frequency:\n"); print(sort(table(unlist(cols)), decreasing=TRUE))
saveRDS(list(o=o, cols=cols), "audit.RDS")
