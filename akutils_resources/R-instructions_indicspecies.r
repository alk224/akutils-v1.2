
## Instructions to run your output files in R manually (with indicspecies package)

## You will need the following files (output from indicator_species.sh):
##	1) map.indicspecies.txt (metadata file)
##	2) otutable.indicspecies.txt (OTU table file)

## Open R
R

## Load indicspecies
library(indicspecies)

## Read in your files
map <- read.csv("map.indicspecies.txt", sep="\t", header=TRUE)
biom <- read.csv("otutable.indicspecies.txt", sep="\t", header=TRUE)

## List available factors from your metadata
colnames(map)

## Read in your factor
f1 <- map[,"Moisture"] ## if factor is "Moisture"

## Indicator value analysis
indval = multipatt(biom, f1, control=how(nperm=9999)) ## If you wish to do 9999 permutations
summary(indval)

## Assess coverage of indicator value analysis
coverage(biom, indval)

## Pearson's phi coefficient of association
phi = multipatt(biom, f1, func="r.g", control=how(nperm=9999)) ## If you wish to do 9999 permutations
summary(phi)

## Assess coverage of phi
coverage(biom, phi)

##FDR corrections (IndVal)
## Read all indval results to variable
indval.all <- indval$sign

## Extract p-values to separate vectors for fdr correction
indval.all.pvals <- indval.all[,"p.value"]

## Correct p-values (FDR) and bind the results to original output
fdr.p.value <- p.adjust(indval.all.pvals, method="fdr")
indval.all.fdr <- cbind(indval.all, fdr.p.value)

## Omit NA values and print only those with p <= 0.05
attach(indval.all.fdr) ## allows sorting by header
indval.all.fdr.nona.sort <- indval.all.fdr[order(fdr.p.value, p.value, na.last=NA),] ## sort output by fdr, then p-value, omit "NA"
indval.all.fdr.nona.sort
detach(indval.all.fdr)

##FDR corrections (Phi)
## Read all phi results to variable
phi.all <- phi$sign
phi.all.pvals <- phi.all[,"p.value"]

## Correct p-values (FDR) and bind the results to original output
fdr.p.value <- p.adjust(phi.all.pvals, method="fdr")
phi.all.fdr <- cbind(phi.all, fdr.p.value)

## Omit NA values and print only those with p <= 0.05
attach(phi.all.fdr)
phi.all.fdr.nona.sort <- phi.all.fdr[order(fdr.p.value, p.value, na.last=NA),]
phi.all.fdr.nona.sort
detach(phi.all.fdr)

## See the official indicspecies documentation and tutorial for more functionality:
## https://cran.r-project.org/web/packages/indicspecies/indicspecies.pdf
## https://cran.r-project.org/web/packages/indicspecies/vignettes/indicspeciesTutorial.pdf

