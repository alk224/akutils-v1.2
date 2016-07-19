
## Instructions to run your output files in R manually (with vegan package)

## You will need the following files (output from two-way_permanova.sh):
##	1) map.vegan.txt (metadata file)
##	2) dm.vegan.txt (distance matrix file)

## Open R
R

## Load vegan
library(vegan)

## Read in your files
map <- read.csv("map.vegan.txt", sep="\t", header=TRUE)
dm0 <- read.csv("dm.vegan.txt", sep="\t", header=TRUE)
dm <- as.dist(dm0)
dmname="dm.vegan.txt"

## List available factors from your metadata
colnames(map)

## Read in your factors
f1 <- map[,"Moisture"] ## if first factor is Moisture
f2 <- map[,"Drought"] ## if second factor is Drought

## Run adonis (permanova) and print to screen
pm <- adonis(formula = dm ~ f1 * f2, permutations = 99)
pm

## Combine your factors for betadisper
f3 <- paste(f1, f2)

## Run betadisper and print to screen
pd <- betadisper(dm, f3)
pd

## Run permutation test of dispersions and print to screen
permutest(pd, permutations = 99)

## Run Tukey HSD test on dispersions and print to screen
pd.HSD <- TukeyHSD(pd)
pd.HSD

## Make PCoA and boxplots
plot(pd, label.cex=0.5, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, sub=dmname, main="PCoA axes 1 vs 2", cex.main=1.5, cex.sub=1.25, cex.lab=1.1, axes=c(1,2))
plot(pd, label.cex=0.5, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, sub=dmname, main="PCoA axes 1 vs 3", cex.main=1.5, cex.sub=1.25, cex.lab=1.1, axes=c(1,3))
plot(pd, label.cex=0.5, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, sub=dmname, main="PCoA axes 2 vs 3", cex.main=1.5, cex.sub=1.25, cex.lab=1.1, axes=c(2,3))
boxplot(pd, main="Boxplots of multivariate dispersions", sub="Categories", cex.axis=0.75, cex.main=1.5, cex.sub=1.25, cex.lab=1.25)

## See the official vegan documentation and tutorials for more functionality:
## https://cran.r-project.org/web/packages/vegan/vegan.pdf
## https://cran.r-project.org/web/packages/vegan/vignettes/intro-vegan.pdf
## http://cc.oulu.fi/~jarioksa/opetus/metodi/vegantutor.pdf

