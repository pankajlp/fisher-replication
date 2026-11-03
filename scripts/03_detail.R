root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
o = readRDS("checks.RDS")
cat("means after fix:\n"); print(round(colMeans(o[,c("en","gl","nbs","nb","base","clk","simple","persist")],na.rm=TRUE),3))
cat("offday>5%:", sum(o$offday>.05,na.rm=TRUE), " ids:", o$id[o$offday>.05], "\n")
cat("clock-rate-only AUC>=.8:", sum(o$simple>=.8,na.rm=TRUE), "; EN>=.7 where simple also >=.7:", sum(o$en>=.7 & o$simple>=.7,na.rm=TRUE), "of", sum(o$en>=.7,na.rm=TRUE), "\n")
cat("EN vs ping-rate: mean diff", round(mean(o$en-o$simple,na.rm=TRUE),3), " better in", sum(o$en>o$simple,na.rm=TRUE), "of", sum(!is.na(o$en-o$simple)), "\n")
for (id in c("002","021","007")) { suppressWarnings({e=new.env(); load(list.files(file.path(root,id),pattern="\\.[Rr][Dd]ata$",full.names=TRUE)[1],envir=e)})
  d=e$datx; s=readLines(list.files(file.path(root,id),pattern="\\.[Rr]$",full.names=TRUE)[1],warn=FALSE)
  cat("\n---",id,"\n"); print(grep("Wednesday|Monday|Tuesday|Thursday|Friday|Saturday|Sunday|day=|InsertRow",s,value=TRUE))
  st=strptime(d$start,"%m/%d/%Y %H:%M"); i=which(!is.na(st))[c(1:3,5,9,20,40,60)]
  print(data.frame(row=i,start=d$start[i],real=weekdays(st[i]),day=d$day[i],ping=d$ping[i],mon=d$mon[i],wed=d$wed[i],sat=d$sat[i],sun=d$sun[i]))}
# target rule: which target for whom
tb = do.call(rbind, lapply(o$id, function(id){ suppressWarnings({e=new.env(); load(list.files(file.path(root,id),pattern="\\.[Rr][Dd]ata$",full.names=TRUE)[1],envir=e)})
  d=rbind(e$dat1[,"cigs",drop=FALSE],e$dat2[,"cigs",drop=FALSE]); data.frame(id,t=o$t[o$id==id],p_any=mean(d$cigs>0,na.rm=TRUE),med=median(d$cigs,na.rm=TRUE))}))
print(aggregate(cbind(p_any,med)~t,tb,function(x) round(c(min=min(x),mean=mean(x),max=max(x)),2)))
