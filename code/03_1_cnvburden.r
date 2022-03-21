## read in command line arguments
args <- commandArgs(TRUE)
wdir <- args[1] 
input <- args[2] 
gene_file <- args[3]
phefile <- args[4] 
output <- "CNVburden"
perm <- 100

phe <- read.table(phefile,h=T)
phe$matchID <- paste(phe$FID,':',phe$IID,sep='')
phe$aff <- phe$AFF - 1

##get intersection of fam file and phe
fam <- read.table(paste0(input, ".fam"))
colnames(fam) <- c("FID", "IID", "Within-family_ID_of_father", "Within-family_ID_of_mother", "sex", "affect")
fam$matchID <- paste(fam$FID, ':',fam$IID,sep='')
combined <- merge(fam, phe, by='matchID')
## PLINK permutation count (currently ignoring PLINK p-values)
perm <- 100 

## change to working directory
setwd(wdir)

## dataset - sort by sizes
dat <- unique(sort(combined$CNV_platform))
data_name <- c('combined',as.character(dat))

##set the start of datasets loop
startpoint=1
if(length(data_name)==2){
	startpoint = 2
}
## write out PLINK ID files 
for (i in 2:length(data_name)) {
    ID <- combined[combined$CNV_platform==data_name[i],2:3]
    write.table(ID,paste(data_name[i],'.ID',sep=''),col=F,row=F,quo=F,sep='\t')
}

type_name <- c('allCNV','del','dup')
region_name <- c('allregions','novelregions')
size_name <- c('>20kb','>100kb','>200kb','>300kb','>400kb','>500kb','>600kb') 
freq_name <- c('Allfreq','singleton','2-5','6-10','11-20','21-40','41-80','81+')

# CNV burden filters
data <- c('',paste(' --keep ', wdir,'/',data_name[2:length(data_name)],'.ID',sep=''))

type <- c('',
          '--cnv-del',
          '--cnv-dup')

region <- c('','--cnv-exclude hg19_implicated_CNV.txt --cnv-region-overlap 0.01')

size <- c('',
          '--cnv-kb 100',
          '--cnv-kb 200',
          '--cnv-kb 300',
          '--cnv-kb 400',
          '--cnv-kb 500',
          '--cnv-kb 600') 

freq <- c('',
          '--cnv-freq-method2 0.5 --cnv-freq-exclude-above 1',
          '--cnv-freq-method2 0.5 --cnv-freq-exclude-above 5 --cnv-freq-exclude-below 2',
          '--cnv-freq-method2 0.5 --cnv-freq-exclude-above 10 --cnv-freq-exclude-below 6',
          '--cnv-freq-method2 0.5 --cnv-freq-exclude-above 20 --cnv-freq-exclude-below 11',
          '--cnv-freq-method2 0.5 --cnv-freq-exclude-above 40 --cnv-freq-exclude-below 21',
          '--cnv-freq-method2 0.5 --cnv-freq-exclude-above 80 --cnv-freq-exclude-below 41',
          '--cnv-freq-method2 0.5 --cnv-freq-exclude-below 81')

## PART 2: Variables: Descriptives and Statistics

## Note: we can get gene count numbers with --cnv-count

## Files:
##  - .cnv.indiv
##  - .cnv.grp.summary
##  - .cnv.summary.mperm
##  - .cnv with gene annotation
tmp_data <- list()
X <- 0 ## loop COUNTER
data_set <- NA; region_set <- NA; CNV_type <- NA; CNV_freq <- NA; CNV_size <- NA
## PLINK descriptives and stats:

plink_AFF_CNV <- NA; plink_AFF_RATE <- NA; plink_AFF_PROP <- NA; plink_AFF_TOTKB <- NA; plink_AFF_AVGKB <- NA; plink_AFF_GRATE <- NA; plink_AFF_GPROP <- NA; plink_AFF_GRICH <- NA


COUNT_rate <- NA; COUNT_cas_rate <- NA; COUNT_con_rate <- NA; COUNT_cascon_ratio <- NA; COUNT_glm_OR <- NA; COUNT_glm_se <- NA; COUNT_glm_tval <- NA; COUNT_glm_pval <- NA; COUNT_perm_pval <- NA; COUNT_glm_lowerCI <- NA; COUNT_glm_upperCI <- NA
NGENE_rate <- NA; NGENE_cas_rate <- NA; NGENE_con_rate <- NA; NGENE_cascon_ratio <- NA; NGENE_glm_OR <- NA; NGENE_glm_se <- NA; NGENE_glm_tval <- NA; NGENE_glm_pval <- NA; NGENE_perm_pval <- NA; NGENE_glm_lowerCI <- NA; NGENE_glm_upperCI <- NA

NSEG <- NA; NSEG_GENIC <- NA; NSEG_NONGENIC <- NA

COUNT_rate <- NA; COUNT_cas_rate <- NA; COUNT_con_rate <- NA; COUNT_cascon_ratio <- NA; COUNT_glm_OR <- NA; COUNT_glm_se <- NA; COUNT_glm_tval <- NA; COUNT_glm_pval <- NA; COUNT_perm_pval <- NA; COUNT_glm_lowerCI <- NA; COUNT_glm_upperCI <- NA
NGENE_rate <- NA; NGENE_cas_rate <- NA; NGENE_con_rate <- NA; NGENE_cascon_ratio <- NA; NGENE_glm_OR <- NA; NGENE_glm_se <- NA; NGENE_glm_tval <- NA; NGENE_glm_pval <- NA; NGENE_perm_pval <- NA; NGENE_glm_lowerCI <- NA; NGENE_glm_upperCI <- NA
KB_rate <- NA; KB_cas_rate <- NA; KB_con_rate <- NA; KB_cascon_ratio <- NA; KB_glm_OR <- NA; KB_glm_se <- NA; KB_glm_tval <- NA; KB_glm_pval <- NA; KB_perm_pval <- NA; KB_glm_lowerCI <- NA; KB_glm_upperCI <- NA
## NSEG
NSEG_rate <- NA; NSEG_cas_rate <- NA; NSEG_con_rate <- NA; NSEG_cascon_ratio <- NA; NSEG_glm_OR <- NA; NSEG_glm_se <- NA; NSEG_glm_tval <- NA; NSEG_glm_pval <- NA; NSEG_perm_pval <- NA; NSEG_glm_lowerCI <- NA; NSEG_glm_upperCI <- NA 

## GENIC CNV
NSEG_GENIC_rate <- NA; NSEG_GENIC_cas_rate <- NA; NSEG_GENIC_con_rate <- NA; NSEG_GENIC_cascon_ratio <- NA; NSEG_GENIC_glm_OR <- NA; NSEG_GENIC_glm_se <- NA; NSEG_GENIC_glm_tval <- NA; NSEG_GENIC_glm_pval <- NA; NSEG_GENIC_perm_pval <- NA; NSEG_GENIC_glm_lowerCI <- NA; NSEG_GENIC_glm_upperCI <- NA
KB_GENIC_rate <- NA; KB_GENIC_cas_rate <- NA; KB_GENIC_con_rate <- NA; KB_GENIC_cascon_ratio <- NA; KB_GENIC_glm_OR <- NA; KB_GENIC_glm_se <- NA; KB_GENIC_glm_tval <- NA; KB_GENIC_glm_pval <- NA; KB_GENIC_perm_pval <- NA; KB_GENIC_glm_lowerCI <- NA; KB_GENIC_glm_upperCI <- NA

## NONGENIC CNV
NSEG_NONGENIC_rate <- NA; NSEG_NONGENIC_cas_rate <- NA; NSEG_NONGENIC_con_rate <- NA; NSEG_NONGENIC_cascon_ratio <- NA; NSEG_NONGENIC_glm_OR <- NA; NSEG_NONGENIC_glm_se <- NA; NSEG_NONGENIC_glm_tval <- NA; NSEG_NONGENIC_glm_pval <- NA; NSEG_NONGENIC_perm_pval <- NA; NSEG_NONGENIC_glm_lowerCI <- NA; NSEG_NONGENIC_glm_upperCI <- NA
KB_NONGENIC_rate <- NA; KB_NONGENIC_cas_rate <- NA; KB_NONGENIC_con_rate <- NA; KB_NONGENIC_cascon_ratio <- NA; KB_NONGENIC_glm_OR <- NA; KB_NONGENIC_glm_se <- NA; KB_NONGENIC_glm_tval <- NA; KB_NONGENIC_glm_pval <- NA; KB_NONGENIC_perm_pval <- NA; KB_NONGENIC_glm_lowerCI <- NA; KB_NONGENIC_glm_upperCI <- NA


## FILTER sets:
#for(a in 1:1){
for(a in startpoint:length(data_name)){
#for(b in 1:length(type_name)){
for(b in 1:1){
for(c in 1:1){
for(d in 1:1){
#for(c in 1:length(region_name)){
#for(d in 1:length(freq_name)){
for(e in 1:1){
#for(e in 1:length(size_name)){
## PART 3: CNV burden loop

## getting full count of burden analyses
X <- X+1
tot <- length(data_name)*length(type_name)*length(region_name)*length(freq_name)*length(size_name)

## PART 3.1: Setting up burden loop

## create temporary subdirectory within working directory (will not overwrite existing directory)
system('mkdir -p burden_loop')


## assign specific loop parameters
data2 <- data[a]
## combining CNV type and region filtering
type2 <- type[b]
region2 <- region[c]
freq2 <- freq[d]
size2 <- size[e]

data_set[X] <- data_name[a]
CNV_type[X] <- type_name[b]
region_set[X] <- region_name[c]
CNV_freq[X] <- freq_name[d]
CNV_size[X] <- size_name[e]

## write out status report
cat('iteration =',X,'of',tot,'\n','data_set',a,'=',data_name[a],'\n','CNV_type',b,'=',type_name[b],'\n','region_set',c,'=',region_name[c],'\n','CNV_freq',d,'=',freq_name[d],'\n','CNV_size',e,'=',size_name[e],'\n',file=paste(output,".status",sep=''),append=F)

## PART 3.2: Applying PLINK filters


## =============== Filter by data, CNV type, and CNV regions first

  system(paste("plink --noweb --cfile ",input," ",data2," ",type2," ",region2," --cnv-write --out burden_loop/type_loop",sep=""))
  ## gene cnv-make-map
  system("plink --noweb --cfile burden_loop/type_loop --cnv-make-map --out burden_loop/type_loop")


  ## --- Frequency pruning    
  system(paste("plink --noweb --cfile burden_loop/type_loop ",freq2," --cnv-write --out burden_loop/freq_loop",sep=""))
  ## gene cnv-make-map
  system("plink --noweb --cfile burden_loop/freq_loop --cnv-make-map --out burden_loop/freq_loop")

  ## --- Size pruning
  system(paste("plink --noweb --cfile burden_loop/freq_loop ",size2," --cnv-write --out burden_loop/size_loop",sep=""))
  system("plink --noweb --cfile burden_loop/size_loop --cnv-make-map --out burden_loop/size_loop")
 
  ## Adding gene/exon count separately

  system(paste("plink --noweb --cfile burden_loop/size_loop --cnv-indiv-perm --mperm ",perm," --cnv-count ",gene_file," --out burden_loop/burden_loop",sep=""))


## PART 3.3: Checking CNV burden coverage

## Check if any segments were matched
cnv <- read.table('burden_loop/size_loop.cnv',h=T)


## PART 3.4: Reading PLINK burden results

if (nrow(cnv) > 0) {
  
## == PLINK results
plink_sum <- read.table("burden_loop/burden_loop.cnv.grp.summary",h=T)
plink_emp <- read.table("burden_loop/burden_loop.cnv.summary.mperm",h=T)

## PART 3.5: CNV burden analysis in R

indiv <- read.table("burden_loop/burden_loop.cnv.indiv",h=T)
indiv$matchID <- paste(indiv$FID,':',indiv$IID,sep='')

cnv <- read.table("burden_loop/size_loop.cnv",h=T)
cnv$matchID <- paste(cnv$FID,':',cnv$IID,sep='')
cnv$bp <- cnv$BP2 - cnv$BP1

## split into genic and non-genic CNVs
genic <- subset(cnv,cnv$SCORE > 0)
nongenic <- subset(cnv,cnv$SCORE == 0)

# -- sum genes for each individual
gene.cnt <- tapply(cnv$SCORE,factor(cnv$matchID),sum)
indiv$NGENE <- 0
# Apply changes only to indexed subset
indx <- match(names(gene.cnt),indiv$matchID)
indiv$NGENE <- replace(indiv$NGENE,indx,gene.cnt)

## -- sum genic CNV count and KB for each individual
genic.tbl <- table(genic$matchID)
indiv$GENIC_CNV_COUNT <- 0
indx <- match(names(genic.tbl),indiv$matchID)
indiv$GENIC_CNV_COUNT <- replace(indiv$GENIC_CNV_COUNT,indx,genic.tbl)

genic.tbl <- tapply(genic$bp,genic$matchID,sum)/1000
indiv$GENIC_KB <- 0
indx <- match(names(genic.tbl),indiv$matchID)
indiv$GENIC_KB <- replace(indiv$GENIC_KB,indx,genic.tbl)


## -- sum non-genic CNV count and KB for each individual
nongenic.tbl <- table(nongenic$matchID)
indiv$NONGENIC_CNV_COUNT <- 0
indx <- match(names(nongenic.tbl),indiv$matchID)
indiv$NONGENIC_CNV_COUNT <- replace(indiv$NONGENIC_CNV_COUNT,indx,nongenic.tbl)

nongenic.tbl <- tapply(nongenic$bp,nongenic$matchID,sum)/1000
indiv$NONGENIC_KB <- 0
indx <- match(names(nongenic.tbl),indiv$matchID)
indiv$NONGENIC_KB <- replace(indiv$NONGENIC_KB,indx,nongenic.tbl)

## -- merge with phenotype
comrg <- merge(indiv,phe,by='matchID')
#comrg_cnv <- comrg[comrg$NSEG > 0,]
#comrg_genic <- comrg[comrg$GENIC_CNV_COUNT > 0,]
#comrg_nongenic <- comrg[comrg$NONGENIC_CNV_COUNT > 0,]
comrg_cnv <- comrg
comrg_genic <- comrg
comrg_nongenic <- comrg

#write.table(comrg, paste(sep='',wdir,'/',output,data_set[X],region_set[X],CNV_type[X],CNV_freq[X],CNV_size[X],'.comrg.txt'),col=T,row=F,quo=F,sep='\t')
#write.table(comrg_cnv, paste(sep='',wdir,'/',output,data_set[X],region_set[X],CNV_type[X],CNV_freq[X],CNV_size[X],'.comrg_cnv.txt'),col=T,row=F,quo=F,sep='\t')

NSEG[X] <- sum(comrg$NSEG)
NSEG_GENIC[X] <- sum(comrg$GENIC_CNV_COUNT)
NSEG_NONGENIC[X] <- sum(comrg$NONGENIC_CNV_COUNT)

## ==== avg. COUNT per CNV (sanity check on NGENE)
COUNT_rate[X] <- mean(comrg_cnv$COUNT)
COUNT_cas_rate[X] <- mean(comrg_cnv$COUNT[comrg_cnv$PHE==2])
COUNT_con_rate[X] <- mean(comrg_cnv$COUNT[comrg_cnv$PHE==1])
COUNT_cascon_ratio[X] <- COUNT_cas_rate[X]/COUNT_con_rate[X]

if(sum(comrg_cnv$aff==0)==0 | sum(comrg_cnv$aff==1)==0){
  COUNT_glm_OR[X] <- NA
  COUNT_glm_se[X] <- NA
  COUNT_glm_tval[X] <- NA
  COUNT_glm_pval[X] <- NA
  COUNT_glm_lowerCI[X] <- NA
  COUNT_glm_upperCI[X] <- NA }


if(sum(comrg_cnv$aff==0) > 0 & sum(comrg_cnv$aff==1) > 0){

if (data_set[X]=='combined') { COUNT.lm <- glm(aff ~ COUNT + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg_cnv,family='binomial') }
if (data_set[X]!='combined') { COUNT.lm <- glm(aff ~ COUNT + SEX + C1 + C2 + C3 + C4 + C5,data=comrg_cnv,family='binomial') }

COUNT.mod <- summary(COUNT.lm)
COUNT_glm_OR[X] <- exp(COUNT.mod$coefficients[2,1])    
COUNT_glm_se[X] <- COUNT.mod$coefficients[2,2]  
COUNT_glm_tval[X] <- COUNT.mod$coefficients[2,3]
COUNT_glm_pval[X] <- COUNT.mod$coefficients[2,4]
COUNT_glm_lowerCI[X] <- exp(COUNT.mod$coefficients[2,1] - (1.96*COUNT_glm_se[X]))
COUNT_glm_upperCI[X] <- exp(COUNT.mod$coefficients[2,1] + (1.96*COUNT_glm_se[X])) }

## ==== Genes covered
NGENE_rate[X] <- mean(comrg_cnv$NGENE)
NGENE_cas_rate[X] <- mean(comrg_cnv$NGENE[comrg_cnv$PHE==2])
NGENE_con_rate[X] <- mean(comrg_cnv$NGENE[comrg_cnv$PHE==1])
NGENE_cascon_ratio[X] <- NGENE_cas_rate[X]/NGENE_con_rate[X]

if(sum(comrg_cnv$aff==0)==0 | sum(comrg_cnv$aff==1)==0){
  NGENE_glm_OR[X] <- NA
  NGENE_glm_se[X] <- NA
  NGENE_glm_tval[X] <- NA
  NGENE_glm_pval[X] <- NA
  NGENE_glm_lowerCI[X] <- NA
  NGENE_glm_upperCI[X] <- NA }

if(sum(comrg_cnv$aff==0) > 0 & sum(comrg_cnv$aff==1) > 0){

if (data_set[X]=='combined') { NGENE.lm <- glm(aff ~ NGENE + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg_cnv,family='binomial') }
if (data_set[X]!='combined') { NGENE.lm <- glm(aff ~ NGENE + SEX + C1 + C2 + C3 + C4 + C5,data=comrg_cnv,family='binomial') }

NGENE.mod <- summary(NGENE.lm)
NGENE_glm_OR[X] <- exp(NGENE.mod$coefficients[2,1])    
NGENE_glm_se[X] <- NGENE.mod$coefficients[2,2]
NGENE_glm_tval[X] <- NGENE.mod$coefficients[2,3]
NGENE_glm_pval[X] <- NGENE.mod$coefficients[2,4]
NGENE_glm_lowerCI[X] <- exp(NGENE.mod$coefficients[2,1] - (1.96*NGENE_glm_se[X]))
NGENE_glm_upperCI[X] <- exp(NGENE.mod$coefficients[2,1] + (1.96*NGENE_glm_se[X])) }

## ==== CNV Count
NSEG_rate[X] <- mean(comrg$NSEG)
NSEG_cas_rate[X] <- mean(comrg$NSEG[comrg$PHE==2])
NSEG_con_rate[X] <- mean(comrg$NSEG[comrg$PHE==1])
NSEG_cascon_ratio[X] <- NSEG_cas_rate[X]/NSEG_con_rate[X]

if (data_set[X]=='combined') { NSEG.lm <- glm(aff ~ NSEG + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg,family='binomial') }
if (data_set[X]!='combined') { NSEG.lm <- glm(aff ~ NSEG + SEX + C1 + C2 + C3 + C4 + C5,data=comrg,family='binomial') }

NSEG.mod <- summary(NSEG.lm)
if(nrow(NSEG.mod$coefficients)==1){
  NSEG_glm_OR[X] <- NA
  NSEG_glm_se[X] <- NA
  NSEG_glm_tval[X] <- NA
  NSEG_glm_pval[X] <- NA
  NSEG_glm_lowerCI[X] <- NA
  NSEG_glm_upperCI[X] <- NA }
if(nrow(NSEG.mod$coefficients) > 1){
NSEG_glm_OR[X] <- exp(NSEG.mod$coefficients[2,1])    
NSEG_glm_se[X] <- NSEG.mod$coefficients[2,2]
NSEG_glm_tval[X] <- NSEG.mod$coefficients[2,3]
NSEG_glm_pval[X] <- NSEG.mod$coefficients[2,4]
NSEG_glm_lowerCI[X] <- exp(NSEG.mod$coefficients[2,1] - (1.96*NSEG_glm_se[X]))
NSEG_glm_upperCI[X] <- exp(NSEG.mod$coefficients[2,1] + (1.96*NSEG_glm_se[X])) }


## ==== overall KB burden
KB_rate[X] <- mean(comrg_cnv$KB)
KB_cas_rate[X] <- mean(comrg_cnv$KB[comrg_cnv$PHE==2])
KB_con_rate[X] <- mean(comrg_cnv$KB[comrg_cnv$PHE==1])
KB_cascon_ratio[X] <- KB_cas_rate[X]/KB_con_rate[X]

if(sum(comrg_cnv$aff==1)==0 | sum(comrg_cnv$aff==1)==0){
  KB_glm_OR[X] <- NA
  KB_glm_se[X] <- NA
  KB_glm_tval[X] <- NA
  KB_glm_pval[X] <- NA
  KB_glm_lowerCI[X] <- NA
  KB_glm_upperCI[X] <- NA }

if(sum(comrg_cnv$aff==1) > 0 & sum(comrg_cnv$aff==1) > 0){

if (data_set[X]=='combined') { KB.lm <- glm(aff ~ KB + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg_cnv,family='binomial') }
if (data_set[X]!='combined') { KB.lm <- glm(aff ~ KB + SEX + C1 + C2 + C3 + C4 + C5,data=comrg_cnv,family='binomial') }

KB.mod <- summary(KB.lm)
KB_glm_OR[X] <- exp(KB.mod$coefficients[2,1])    
KB_glm_se[X] <- KB.mod$coefficients[2,2]
KB_glm_tval[X] <- KB.mod$coefficients[2,3]
KB_glm_pval[X] <- KB.mod$coefficients[2,4]
KB_glm_lowerCI[X] <- exp(KB.mod$coefficients[2,1] - (1.96*KB_glm_se[X]))
KB_glm_upperCI[X] <- exp(KB.mod$coefficients[2,1] + (1.96*KB_glm_se[X])) }


## ==== GENIC CNV Count
NSEG_GENIC_rate[X] <- mean(comrg$GENIC_CNV_COUNT)
NSEG_GENIC_cas_rate[X] <- mean(comrg$GENIC_CNV_COUNT[comrg$PHE==2])
NSEG_GENIC_con_rate[X] <- mean(comrg$GENIC_CNV_COUNT[comrg$PHE==1])
NSEG_GENIC_cascon_ratio[X] <- NSEG_GENIC_cas_rate[X]/NSEG_GENIC_con_rate[X]

if (data_set[X]=='combined') { NSEG_GENIC.lm <- glm(aff ~ GENIC_CNV_COUNT + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg,family='binomial') }
if (data_set[X]!='combined') { NSEG_GENIC.lm <- glm(aff ~ GENIC_CNV_COUNT + SEX + C1 + C2 + C3 + C4 + C5,data=comrg,family='binomial') }

NSEG_GENIC.mod <- summary(NSEG_GENIC.lm)
if(nrow(NSEG_GENIC.mod$coefficients)==1){
  NSEG_GENIC_glm_OR[X] <- NA
  NSEG_GENIC_glm_se[X] <- NA
  NSEG_GENIC_glm_tval[X] <- NA
  NSEG_GENIC_glm_pval[X] <- NA
  NSEG_GENIC_glm_lowerCI[X] <- NA
  NSEG_GENIC_glm_upperCI[X] <- NA }
if(nrow(NSEG_GENIC.mod$coefficients) > 1){
NSEG_GENIC_glm_OR[X] <- exp(NSEG_GENIC.mod$coefficients[2,1])    
NSEG_GENIC_glm_se[X] <- NSEG_GENIC.mod$coefficients[2,2]
NSEG_GENIC_glm_tval[X] <- NSEG_GENIC.mod$coefficients[2,3]
NSEG_GENIC_glm_pval[X] <- NSEG_GENIC.mod$coefficients[2,4]
NSEG_GENIC_glm_lowerCI[X] <- exp(NSEG_GENIC.mod$coefficients[2,1] - (1.96*NSEG_GENIC_glm_se[X]))
NSEG_GENIC_glm_upperCI[X] <- exp(NSEG_GENIC.mod$coefficients[2,1] + (1.96*NSEG_GENIC_glm_se[X])) }


## ==== NONGENIC CNV Count
NSEG_NONGENIC_rate[X] <- mean(comrg$NONGENIC_CNV_COUNT)
NSEG_NONGENIC_cas_rate[X] <- mean(comrg$NONGENIC_CNV_COUNT[comrg_nongenic$PHE==2])
NSEG_NONGENIC_con_rate[X] <- mean(comrg$NONGENIC_CNV_COUNT[comrg_nongenic$PHE==1])
NSEG_NONGENIC_cascon_ratio[X] <- NSEG_NONGENIC_cas_rate[X]/NSEG_NONGENIC_con_rate[X]

if(sum(comrg$aff==1)==0 | sum(comrg$aff==1)==0){
  NSEG_NONGENIC_glm_OR[X] <- NA
  NSEG_NONGENIC_glm_se[X] <- NA
  NSEG_NONGENIC_glm_tval[X] <- NA
  NSEG_NONGENIC_glm_pval[X] <- NA
  NSEG_NONGENIC_glm_lowerCI[X] <- NA
  NSEG_NONGENIC_glm_upperCI[X] <- NA }

if(sum(comrg$aff==1) > 0 & sum(comrg$aff==1) > 0){

if (data_set[X]=='combined') { NSEG_NONGENIC.lm <- glm(aff ~ NONGENIC_CNV_COUNT + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg,family='binomial') }
if (data_set[X]!='combined') { NSEG_NONGENIC.lm <- glm(aff ~ NONGENIC_CNV_COUNT + SEX + C1 + C2 + C3 + C4 + C5,data=comrg,family='binomial') }

NSEG_NONGENIC.mod <- summary(NSEG_NONGENIC.lm)
NSEG_NONGENIC_glm_OR[X] <- exp(NSEG_NONGENIC.mod$coefficients[2,1])    
NSEG_NONGENIC_glm_se[X] <- NSEG_NONGENIC.mod$coefficients[2,2]
NSEG_NONGENIC_glm_tval[X] <- NSEG_NONGENIC.mod$coefficients[2,3]
NSEG_NONGENIC_glm_pval[X] <- NSEG_NONGENIC.mod$coefficients[2,4]
NSEG_NONGENIC_glm_lowerCI[X] <- exp(NSEG_NONGENIC.mod$coefficients[2,1] - 1.96*(NSEG_NONGENIC_glm_se[X]))
NSEG_NONGENIC_glm_upperCI[X] <- exp(NSEG_NONGENIC.mod$coefficients[2,1] + 1.96*(NSEG_NONGENIC_glm_se[X])) }

  
## ==== NONGENIC KB burden
KB_NONGENIC_rate[X] <- mean(comrg_nongenic$NONGENIC_KB)
KB_NONGENIC_cas_rate[X] <- mean(comrg_nongenic$NONGENIC_KB[comrg_nongenic$PHE==2])
KB_NONGENIC_con_rate[X] <- mean(comrg_nongenic$NONGENIC_KB[comrg_nongenic$PHE==1])
KB_NONGENIC_cascon_ratio[X] <- KB_NONGENIC_cas_rate[X]/KB_NONGENIC_con_rate[X]

if(sum(comrg_nongenic$aff==1)==0 | sum(comrg_genic$aff==1)==0){
  KB_NONGENIC_glm_OR[X] <- NA
  KB_NONGENIC_glm_se[X] <- NA
  KB_NONGENIC_glm_tval[X] <- NA
  KB_NONGENIC_glm_pval[X] <- NA
  KB_NONGENIC_glm_lowerCI[X] <- NA
  KB_NONGENIC_glm_upperCI[X] <- NA }


if(sum(comrg_nongenic$aff==1) > 0 & sum(comrg_nongenic$aff==1) > 0){

if (data_set[X]=='combined') { KB_NONGENIC.lm <- glm(aff ~ NONGENIC_KB + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg_nongenic,family='binomial') }
if (data_set[X]!='combined') { KB_NONGENIC.lm <- glm(aff ~ NONGENIC_KB + SEX + C1 + C2 + C3 + C4 + C5,data=comrg_nongenic,family='binomial') }

KB_NONGENIC.mod <- summary(KB_NONGENIC.lm)
KB_NONGENIC_glm_OR[X] <- exp(KB_NONGENIC.mod$coefficients[2,1])    
KB_NONGENIC_glm_se[X] <- KB_NONGENIC.mod$coefficients[2,2]
KB_NONGENIC_glm_tval[X] <- KB_NONGENIC.mod$coefficients[2,3]
KB_NONGENIC_glm_pval[X] <- KB_NONGENIC.mod$coefficients[2,4]
KB_NONGENIC_glm_lowerCI[X] <- exp(KB_NONGENIC.mod$coefficients[2,1] - (1.96*KB_NONGENIC_glm_se[X]))
KB_NONGENIC_glm_upperCI[X] <- exp(KB_NONGENIC.mod$coefficients[2,1] + (1.96*KB_NONGENIC_glm_se[X])) }


## ==== GENIC KB burden
KB_GENIC_rate[X] <- mean(comrg_genic$GENIC_KB)
KB_GENIC_cas_rate[X] <- mean(comrg_genic$GENIC_KB[comrg_genic$PHE==2])
KB_GENIC_con_rate[X] <- mean(comrg_genic$GENIC_KB[comrg_genic$PHE==1])
KB_GENIC_cascon_ratio[X] <- KB_GENIC_cas_rate[X]/KB_GENIC_con_rate[X]

if(sum(comrg_genic$aff==1)==0 | sum(comrg_genic$aff==1)==0){
  KB_GENIC_glm_OR[X] <- NA
  KB_GENIC_glm_se[X] <- NA
  KB_GENIC_glm_tval[X] <- NA
  KB_GENIC_glm_pval[X] <- NA
  KB_GENIC_glm_lowerCI[X] <- NA
  KB_GENIC_glm_upperCI[X] <- NA }

if(sum(comrg_genic$aff==1) > 0 & sum(comrg_genic$aff==1) > 0){

if (data_set[X]=='combined') { KB_GENIC.lm <- glm(aff ~ GENIC_KB + SEX + CNV_platform + C1 + C2 + C3 + C4 + C5,data=comrg_genic,family='binomial') }
if (data_set[X]!='combined') { KB_GENIC.lm <- glm(aff ~ GENIC_KB + SEX + C1 + C2 + C3 + C4 + C5,data=comrg_genic,family='binomial') }

KB_GENIC.mod <- summary(KB_GENIC.lm)
KB_GENIC_glm_OR[X] <- exp(KB_GENIC.mod$coefficients[2,1])    
KB_GENIC_glm_se[X] <- KB_GENIC.mod$coefficients[2,2] 
KB_GENIC_glm_tval[X] <- KB_GENIC.mod$coefficients[2,3]
KB_GENIC_glm_pval[X] <- KB_GENIC.mod$coefficients[2,4]
KB_GENIC_glm_lowerCI[X] <- exp(KB_GENIC.mod$coefficients[2,1] - (1.96*KB_GENIC_glm_se[X]))
KB_GENIC_glm_upperCI[X] <- exp(KB_GENIC.mod$coefficients[2,1] + (1.96*KB_GENIC_glm_se[X])) }




} ## End of mapped segments analysis 

tmp_data[[X]] <- cbind.data.frame(data_set=data_set[X],
                              region_set=region_set[X],
                              CNV_type=CNV_type[X],
                              CNV_freq=CNV_freq[X],
                              CNV_size=CNV_size[X],
                              COUNT_con_rate=COUNT_con_rate[X],
			      COUNT_cas_rate=COUNT_cas_rate[X],
                              COUNT_glm_OR=COUNT_glm_OR[X],
                              COUNT_glm_se=COUNT_glm_se[X],
                              COUNT_glm_tval=COUNT_glm_tval[X],
                              COUNT_glm_pval=COUNT_glm_pval[X],
                              COUNT_glm_lowerCI=COUNT_glm_lowerCI[X],
                              COUNT_glm_upperCI=COUNT_glm_upperCI[X],
			      NSEG_con_rate=NSEG_con_rate[X],
			      NSEG_cas_rate=NSEG_cas_rate[X],
                              NSEG_glm_OR=NSEG_glm_OR[X],
                              NSEG_glm_se=NSEG_glm_se[X],
                              NSEG_glm_tval=NSEG_glm_tval[X],
                              NSEG_glm_pval=NSEG_glm_pval[X],
                              NSEG_glm_lowerCI=NSEG_glm_lowerCI[X],
                              NSEG_glm_upperCI=NSEG_glm_upperCI[X],
                              NGENE_con_rate=NGENE_con_rate[X],
			      NGENE_cas_rate=NGENE_cas_rate[X],
                              NGENE_glm_OR=NGENE_glm_OR[X],
                              NGENE_glm_se=NGENE_glm_se[X],
                              NGENE_glm_tval=NGENE_glm_tval[X],
                              NGENE_glm_pval=NGENE_glm_pval[X],
                              NGENE_glm_lowerCI=NGENE_glm_lowerCI[X],
                              NGENE_glm_upperCI=NGENE_glm_upperCI[X],
			      KB_con_rate=KB_con_rate[X],
			      KB_cas_rate=KB_cas_rate[X],
                              KB_glm_OR=KB_glm_OR[X],
                              KB_glm_se=KB_glm_se[X],
                              KB_glm_tval=KB_glm_tval[X],
                              KB_glm_pval=KB_glm_pval[X],
                              KB_glm_lowerCI=KB_glm_lowerCI[X],
                              KB_glm_upperCI=KB_glm_upperCI[X],
			      KB_GENIC_con_rate=KB_GENIC_con_rate[X],
			      KB_GENIC_cas_rate=KB_GENIC_cas_rate[X],
                              KB_GENIC_glm_OR=KB_GENIC_glm_OR[X],
                              KB_GENIC_glm_se=KB_GENIC_glm_se[X],
                              KB_GENIC_glm_tval=KB_GENIC_glm_tval[X],
                              KB_GENIC_glm_pval=KB_GENIC_glm_pval[X],
                              KB_GENIC_glm_lowerCI=KB_GENIC_glm_lowerCI[X],
                              KB_GENIC_glm_upperCI=KB_GENIC_glm_upperCI[X],
			      KB_NONGENIC_con_rate=KB_NONGENIC_con_rate[X],
			      KB_NONGENIC_cas_rate=KB_NONGENIC_cas_rate[X],
                              KB_NONGENIC_glm_OR=KB_NONGENIC_glm_OR[X],
                              KB_NONGENIC_glm_se=KB_NONGENIC_glm_se[X],
                              KB_NONGENIC_glm_tval=KB_NONGENIC_glm_tval[X],
                              KB_NONGENIC_glm_pval=KB_NONGENIC_glm_pval[X],
                              KB_NONGENIC_glm_lowerCI=KB_NONGENIC_glm_lowerCI[X],
                              KB_NONGENIC_glm_upperCI=KB_NONGENIC_glm_upperCI[X],
			      NSEG_NONGENIC_con_rate=NSEG_NONGENIC_con_rate[X],
			      NSEG_NONGENIC_cas_rate=NSEG_NONGENIC_cas_rate[X],
                              NSEG_NONGENIC_glm_OR=NSEG_NONGENIC_glm_OR[X],
                              NSEG_NONGENIC_glm_se=NSEG_NONGENIC_glm_se[X],
                              NSEG_NONGENIC_glm_tval=NSEG_NONGENIC_glm_tval[X],
                              NSEG_NONGENIC_glm_pval=NSEG_NONGENIC_glm_pval[X],
                              NSEG_NONGENIC_glm_lowerCI=NSEG_NONGENIC_glm_lowerCI[X],
                              NSEG_NONGENIC_glm_upperCI=NSEG_NONGENIC_glm_upperCI[X],
			      NSEG_GENIC_con_rate=NSEG_GENIC_con_rate[X],
			      NSEG_GENIC_cas_rate=NSEG_GENIC_cas_rate[X],
                              NSEG_GENIC_glm_OR=NSEG_GENIC_glm_OR[X],
                              NSEG_GENIC_glm_se=NSEG_GENIC_glm_se[X],
                              NSEG_GENIC_glm_tval=NSEG_GENIC_glm_tval[X],
                              NSEG_GENIC_glm_pval=NSEG_GENIC_glm_pval[X],
                              NSEG_GENIC_glm_lowerCI=NSEG_GENIC_glm_lowerCI[X],
                              NSEG_GENIC_glm_upperCI=NSEG_GENIC_glm_upperCI[X])

## write to file
system('rm -r burden_loop')
}
}
}
}
}
 full_data <- do.call(rbind,tmp_data)
write.table(full_data,paste(sep='',wdir,'/',output,'.burden'),col=T,row=F,quo=F,sep='\t')
