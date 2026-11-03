suppressMessages(library(glmnet))
root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
aud = readRDS("audit.RDS"); o = readRDS("checks.RDS")
auc = function(s,y){ok=!is.na(s)&!is.na(y);s=s[ok];y=y[ok];a=sum(y==1);b=sum(y==0);if(!a||!b)return(NA);(sum(rank(s)[y==1])-a*(a+1)/2)/(a*b)}
map = c(Sunday="sunfw",Monday="monfw",Tuesday="tuesfw",Wednesday="wedfw",Thursday="thursfw",Friday="frifw",Saturday="satfw")
for (id in c("002","021","007")) { suppressWarnings({e=new.env(); load(list.files(file.path(root,id),pattern="\\.[Rr][Dd]ata$",full.names=TRUE)[1],envir=e)})
  d=e$datx; st=strptime(d$start,"%m/%d/%Y %H:%M"); w=which(!is.na(st))
  dd=as.numeric(diff(as.POSIXct(st[w])),units="hours"); ri=diff(w)
  cat("\n",id,": rows with timestamp",length(w),"of",nrow(d)," max gap hrs",round(max(dd),1)," first date",d$start[w[1]]," last",d$start[w[length(w)]],"\n")
  if (id=="007") { v=c("sun","mon","tues","wed","thur","fri","sat"); lab=sapply(w,function(i) v[which(unlist(d[i,v])==1)[1]]); real=c(Sunday="sun",Monday="mon",Tuesday="tues",Wednesday="wed",Thursday="thur",Friday="fri",Saturday="sat")[weekdays(st[w])]
    bad=which(lab!=real); cat("first wrong row",w[bad[1]],d$start[w[bad[1]]],"label",lab[bad[1]],"; wrong rows",length(bad),"; ping vs hour after that:\n"); print(table(d$ping[w[bad]], floor(st$hour[w[bad]]/6)*6))
    print(d[w[bad[1:4]]+c(-1,0,1,2)*0,c("start","ping","day")]) }
  # refit EN with true target weekday
  t=aud$o$targets[aud$o$id==id]; fix=function(D){ ts=strptime(D$start,"%m/%d/%Y %H:%M"); nxt=weekdays(ts+ifelse(D$ping==3,12*3600,0)); for(k in map) D[[k]]=as.numeric(map[nxt]==k); D }
  a=fix(e$dat1); b=fix(e$dat2); wk=unname(map); m1=as.matrix(e$mat1); m2=as.matrix(e$mat2); m1[,intersect(colnames(m1),wk)]=as.matrix(a[,intersect(colnames(m1),wk)]); m2[,intersect(colnames(m2),wk)]=as.matrix(b[,intersect(colnames(m2),wk)])
  y=e$dat1[[t]]; k=!is.na(y); set.seed(1); f=cv.glmnet(m1[k,],y[k],family="binomial",standardize=TRUE,alpha=.5,type.measure="mse")
  cat("published-pipeline EN AUC",round(o$en[o$id==id],3)," with corrected weekdays",round(auc(as.numeric(predict(f,m2,s="lambda.min")),e$dat2[[t]]),3),"\n") }
