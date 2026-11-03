suppressMessages(library(glmnet))
root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
aud = readRDS("audit.RDS"); ids = aud$o$id
auc = function(s, y) { ok = !is.na(s) & !is.na(y); s=s[ok]; y=y[ok]; n1=sum(y==1); n0=sum(y==0); if (!n1||!n0) return(NA); (sum(rank(s)[y==1]) - n1*(n1+1)/2)/(n1*n0) }
days = c(Sunday="sun",Monday="mon",Tuesday="tues",Wednesday="wed",Thursday="thur",Friday="fri",Saturday="sat")
R = list()
for (id in ids) { suppressWarnings({ e = new.env(); load(list.files(file.path(root,id), pattern="\\.[Rr][Dd]ata$", full.names=TRUE)[1], envir=e) })
  dat1=e$dat1; dat2=e$dat2; datx=e$datx; t = aud$o$targets[aud$o$id==id]; y1=dat1[[t]]; y2=dat2[[t]]
  cur = sub("fw$","",t)
  # timestamps vs ping and weekday labels
  st = strptime(datx$start, "%m/%d/%Y %H:%M"); ok = !is.na(st)
  wk = weekdays(st[ok]); lab = sapply(which(ok), function(i) { v = c("sun","mon","tues","wed","thur","fri","sat"); h = v[unlist(datx[i,v])==1]; if (length(h)==1) h else NA })
  wrong_day = mean(days[wk] != lab, na.rm=TRUE)
  h = st$hour[ok] + st$min[ok]/60; hr = tapply(h, datx$ping[ok], median)
  mono = all(diff(hr) > 0)
  dayidx = as.numeric(as.Date(st[ok]) - as.Date(st[ok][1])); w = which(ok); expect = (w-1)%/%4 - (w[1]-1)%/%4
  offday = mean(abs(dayidx - expect) > 0 & !(h < 5))  # ignore after-midnight pings
  # saved model test AUCs
  en = auc(dat2$netpred, y2); gl = if (!is.null(e$predfw)) auc(as.numeric(e$predfw), y2) else NA
  nbs = if (!is.null(e$rfnbpred)) auc(e$rfnbpred[,2], y2) else NA; nb = if (!is.null(e$nbpred)) auc(e$nbpred[,2], y2) else NA
  # baselines refit on training data only
  clock = c("midfw","evefw","nightfw"); wkf = c("monfw","tuesfw","wedfw","thursfw","frifw","satfw","sunfw"); cyc = c("cos24","sin24","cos12","sin12")
  fit = function(v) { X1=as.matrix(dat1[,v]); X2=as.matrix(dat2[,v]); o=!is.na(y1); set.seed(1)
    m = tryCatch(cv.glmnet(X1[o,],y1[o],family="binomial",alpha=.5,type.measure="mse"), error=function(e) NULL); if (is.null(m)) return(NA); auc(as.numeric(predict(m,X2,s="lambda.min")), y2) }
  base = fit(c(cur,clock,wkf,cyc)); clk = fit(c(clock,wkf,cyc))
  simple = { p = tapply(y1, dat1$ping, mean, na.rm=TRUE)[as.character(dat2$ping)]; auc(as.numeric(p), y2) }
  R[[id]] = data.frame(id, t, n1=nrow(dat1), n2=nrow(dat2), y_te=mean(y2,na.rm=TRUE), y_tr=mean(y1,na.rm=TRUE), wrong_day, mono, offday, en, gl, nbs, nb, base, clk, simple, persist=auc(dat2[[cur]],y2)) }
o = do.call(rbind,R); saveRDS(o,"checks.RDS"); options(width=170)
print(o[,c(1:2,5:6,7:9,10:17)], digits=2, row.names=FALSE)
cat("\nMEANS\n"); print(round(colMeans(o[,c("en","gl","nbs","nb","base","clk","simple","persist")],na.rm=TRUE),3))
o$best = apply(o[,c("en","gl","nbs","nb")],1,max,na.rm=TRUE)
cat("mean best-of-4:",round(mean(o$best,na.rm=TRUE),3),"  n best>=.7:",sum(o$best>=.7)," en>=.7:",sum(o$en>=.7,na.rm=TRUE)," of",nrow(o),"\n")
cat("EN vs baseline(current+clock) paired: mean diff",round(mean(o$en-o$base,na.rm=TRUE),3)," wilcox p",signif(wilcox.test(o$en,o$base,paired=TRUE)$p.value,3)," EN better in",sum(o$en>o$base,na.rm=TRUE),"of",sum(!is.na(o$en-o$base)),"\n")
cat("people w/ weekday labels wrong >5%:",sum(o$wrong_day>.05,na.rm=TRUE)," all rows wrong:",sum(o$wrong_day>.9,na.rm=TRUE),"; non-monotonic ping hours:",sum(!o$mono),"; offday>5%:",sum(o$offday>.05,na.rm=TRUE),"\n")
