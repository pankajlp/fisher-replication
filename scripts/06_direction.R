o = readRDS("checks.RDS"); t3 = read.csv("table3.csv", colClasses=c(id="character"))
m = merge(o[,c("id","en","nbs","simple")], t3, by="id", suffixes=c("","_pub")); cat("matched",nrow(m),"\n")
fl = function(a) pmax(a, 1-a)
cat(sprintf("EN   published %.3f | recomputed true %.3f | flipped %.3f | abs diff pub vs flipped %.4f, vs true %.4f | exact to .01 flipped %d true %d\n",
 mean(m$en_pub), mean(m$en,na.rm=T), mean(fl(m$en),na.rm=T), mean(abs(m$en_pub-fl(m$en)),na.rm=T), mean(abs(m$en_pub-m$en),na.rm=T), sum(abs(m$en_pub-fl(m$en))<=.011,na.rm=T), sum(abs(m$en_pub-m$en)<=.011,na.rm=T)))
cat(sprintf("NB   published %.3f | recomputed true %.3f | flipped %.3f | abs diff pub vs flipped %.4f, vs true %.4f | exact to .01 flipped %d true %d\n",
 mean(m$nb), mean(m$nbs,na.rm=T), mean(fl(m$nbs),na.rm=T), mean(abs(m$nb-fl(m$nbs)),na.rm=T), mean(abs(m$nb-m$nbs),na.rm=T), sum(abs(m$nb-fl(m$nbs))<=.011,na.rm=T), sum(abs(m$nb-m$nbs)<=.011,na.rm=T)))
cat("people with true EN AUC<.5:",sum(m$en<.5,na.rm=T)," NB:",sum(m$nbs<.5,na.rm=T),"\n")
b = m[m$en<.5 & !is.na(m$en), c("id","en","en_pub","nbs","nb")]; print(b, digits=2, row.names=FALSE)
cat("still mismatched after flip, EN (>.015):\n"); x=m[abs(m$en_pub-fl(m$en))>.015,c("id","en","en_pub")]; print(x,digits=3,row.names=FALSE)
cat("still mismatched after flip, NB (>.015):\n"); x=m[abs(m$nb-fl(m$nbs))>.015,c("id","nbs","nb")]; print(x,digits=3,row.names=FALSE)
cat("t-test true EN vs .5:", signif(t.test(m$en,mu=.5)$p.value,3), " NB:", signif(t.test(m$nbs,mu=.5)$p.value,3), "\n")
cat("\ncorrected distribution\n"); cat("EN >=.8 true:",sum(m$en>=.8,na.rm=T),"pub:",sum(m$en_pub>=.8)," NB>=.8 true:",sum(m$nbs>=.8,na.rm=T),"pub:",sum(m$nb>=.8),"\n")
cat("beats ping-rate baseline: EN mean diff",round(mean(m$en-m$simple,na.rm=T),3),"; NB",round(mean(m$nbs-m$simple,na.rm=T),3),"\n")
