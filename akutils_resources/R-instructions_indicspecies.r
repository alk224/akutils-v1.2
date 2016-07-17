
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

attach(map) ## so you can call your factor by name
f1 <- map[,Moisture] ## if factor is "Moisture"

## Indicator value analysis

indval = multipatt(biom, f1, control=how(nperm=999))
summary(indval)

## Assess coverage of indicator value analysis

coverage(biom, indval)

## Pearson's phi coefficient of association

phi = multipatt(biom, f1, func="r.g", control=how(nperm=999))
summary(phi)

## Assess coverage of phi

coverage(biom, phi)

## See the official indicspecies documentation and tutorial for more functionality:
## https://cran.r-project.org/web/packages/indicspecies/indicspecies.pdf
## https://cran.r-project.org/web/packages/indicspecies/vignettes/indicspeciesTutorial.pdf

