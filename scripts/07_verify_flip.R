suppressMessages({library(glmnet); library(pROC)})
somersC = function(x,y){ok=!is.na(x)&!is.na(y);x=x[ok];y=y[ok];a=sum(y==1);b=sum(y==0);(mean(rank(x)[y==1])-(a+1)/2)/b}  # Hmisc somers2 C definition
if (requireNamespace("Hmisc",quietly=TRUE)) cat("Hmisc present\n") else cat("Hmisc absent, using its formula\n")
root = Sys.getenv("OSF_DIR", "../upstream/extracted/Individual Data_Analysis_Results")
aud = readRDS("audit.RDS")
for (id in c("004","015","017","059","063","014")) { suppressWarnings({e=new.env(); load(list.files(file.path(root,id),pattern="\\.[Rr][Dd]ata$",full.names=TRUE)[1],envir=e)})
  t=aud$o$targets[aud$o$id==id]; y=e$dat2[[t]]; p=e$dat2$netpred; r=roc(y~p,quiet=TRUE)
  s=readLines(list.files(file.path(root,id),pattern="\\.[Rr]$",full.names=TRUE)[1],warn=FALSE); i=grep("somers2\\(dat2\\$netpred",s)[1]
  cat(sprintf("%s train C %.2f | saved netpred: somers C %.3f, pROC default %.3f dir '%s' | script comment after somers2: %s\n", id, somersC(e$dat1$netpred,e$dat1[[t]]), somersC(p,y), auc(r), r$direction, s[i+1]))
  yt=e$dat1[[t]]; k=!is.na(yt); set.seed(1); f=cv.glmnet(as.matrix(e$mat1)[k,],yt[k],family="binomial",standardize=TRUE,alpha=.5,type.measure="mse")
  q=as.numeric(predict(f,as.matrix(e$mat2),s="lambda.min")); cat(sprintf("     refit now: somers C %.3f  (vars selected %d, cor with saved netpred %.3f, nonzero sd %s)\n", somersC(q,y), sum(coef(f,s="lambda.min")!=0)-1, suppressWarnings(cor(q,p,use="c")), sd(q)>0)) }
