root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
aud = readRDS("audit.RDS"); o = readRDS("checks.RDS")
ss = function(p,y,th) c(sens=mean(p[y==1]>=th), spec=mean(p[y==0]<th))
best = function(p,y){ th=sort(unique(p)); th=c(th,max(th)+1); v=t(sapply(th,function(t) ss(p,y,t))); v[which.max(rowSums(v)),] }
res=list(); drift=list()
for (id in o$id) { suppressWarnings({e=new.env(); load(list.files(file.path(root,id),pattern="\\.[Rr][Dd]ata$",full.names=TRUE)[1],envir=e)})
  t=aud$o$targets[aud$o$id==id]; y1=e$dat1[[t]]; y2=e$dat2[[t]]; k=!is.na(y2)&!is.na(e$dat2$netpred); p=e$dat2$netpred[k]; y=y2[k]
  a=if(length(unique(y))==2) best(p,y) else c(NA,NA)
  ktr=!is.na(y1)&!is.na(e$dat1$netpred); b=if(length(unique(y1[ktr]))==2) best(e$dat1$netpred[ktr],y1[ktr]) else c(NA,NA)
  thtr={pt=e$dat1$netpred[ktr];yt=y1[ktr];th=sort(unique(pt));th=c(th,max(th)+1);v=t(sapply(th,function(h) ss(pt,yt,h)));th[which.max(rowSums(v))]}
  c2=if(length(unique(y))==2) ss(p,y,thtr) else c(NA,NA)
  res[[id]]=data.frame(id,s_test=a[1],sp_test=a[2],s_trainTh=c2[1],sp_trainTh=c2[2])
  d=e$datx; st=strptime(d$start,"%m/%d/%Y %H:%M"); w=which(!is.na(st)); h=st$hour[w]+st$min[w]/60; h[h<4]=h[h<4]+24
  mh=tapply(h,d$ping[w],median); near=as.numeric(names(mh))[apply(abs(outer(h,mh,"-")),1,which.min)]
  drift[[id]]=data.frame(id,bad=mean(near!=d$ping[w])) }
r=do.call(rbind,res); dr=do.call(rbind,drift); options(width=120)
cat("Sens/spec EN, threshold chosen on TEST data: ",round(colMeans(r[,2:3],na.rm=TRUE),3),"\n")
cat("Sens/spec EN, threshold chosen on TRAIN data:",round(colMeans(r[,4:5],na.rm=TRUE),3),"\n")
cat("AUC means en",round(mean(o$en,na.rm=T),3),"nb_rf",round(mean(o$nbs,na.rm=T),3),"nb",round(mean(o$nb,na.rm=T),3),"\n")
cat("best of EN/NB-RF/NB:",round(mean(apply(o[,c("en","nbs","nb")],1,max,na.rm=T)),3)," best of EN/NB-RF:",round(mean(pmax(o$en,o$nbs,na.rm=T)),3),"\n")
cat("perfect AUC EN:",sum(o$en==1,na.rm=T)," best:",sum(apply(o[,c("en","nbs","nb")],1,max,na.rm=T)==1),"; perfect also with ping-rate:",o$id[o$en==1],round(o$simple[which(o$en==1)],2),"\n")
cat("ping label mismatch >5%:\n"); print(dr[dr$bad>.05,],digits=2,row.names=FALSE)
