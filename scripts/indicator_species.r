#!/usr/bin/env Rscript
#
#  indicator_species.r - R slave for indicator species analysis with R package indicspecies
#
#  Version 1.0.0 (July, 16, 2016)
#
#  Copyright (c) 2016-- Lela Andrews
#
#  This software is provided 'as-is', without any express or implied
#  warranty. In no event will the authors be held liable for any damages
#  arising from the use of this software.
#
#  Permission is granted to anyone to use this software for any purpose,
#  including commercial applications, and to alter it and redistribute it
#  freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software
#     in a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#  3. This notice may not be removed or altered from any source distribution.
#

## Recieve input files from bash
args <- commandArgs(TRUE)
mapfile=(args[1])
biomfile=(args[2])
factor=(args[3])
outdir=(args[4])
perms0=(args[5])
perms <- as.integer(perms0)

## Load libraries
library(indicspecies)
options(width=300)

## Read in data
map <- read.csv(mapfile, sep="\t", header=TRUE)
biom <- read.csv(biomfile, sep="\t", header=TRUE)
f1 <- map[,factor]

## Run indval and print to screen
invalperms <- paste("\n********************************\nIndicator value analysis summary\n(", perms, " permutations, uncorrected for multiple testing):", sep="")
writeLines(invalperms)
indval = multipatt(biom, f1, control=how(nperm=perms))
summary(indval)

## Run coverage and print to screen
writeLines("\n********************************\nCoverage (IndVal):")
coverage(biom, indval)

## Run phi and print to screen
phiperms <- paste("\n********************************\nPearson's phi coefficient of association summary\n(", perms, " permutations, uncorrected for multiple testing):", sep="")
writeLines(phiperms)
phi = multipatt(biom, f1, func="r.g", control=how(nperm=perms))
summary(phi)

## Run coverage and print to screen
writeLines("\n********************************\nCoverage (Phi):")
coverage(biom, phi)

## Read all indval results to variable
indval.all <- indval$sign

## Extract p-values to separate vector
indval.all.pvals <- indval.all[,"p.value"]

## Correct p-values (FDR) and bind the result to original output
fdr.p.value <- p.adjust(indval.all.pvals, method="fdr")
indval.all.fdr <- cbind(indval.all, fdr.p.value)

## Omit NA values and print only those with p <= 0.05
attach(indval.all.fdr)
indval.all.fdr.nona.sort <- indval.all.fdr[order(fdr.p.value, p.value, na.last=NA),]
indvalfdrperms <- paste("\n********************************\nIndVal results with FDR corrections\n(only valid p-values shown, ", perms, " permutations):\n", sep="")
writeLines(indvalfdrperms)
indval.all.fdr.nona.sort
detach(indval.all.fdr)

## Repeat FDR correction and NA omission for Phi output
phi.all <- phi$sign
phi.all.pvals <- phi.all[,"p.value"]
fdr.p.value <- p.adjust(phi.all.pvals, method="fdr")
phi.all.fdr <- cbind(phi.all, fdr.p.value)
attach(phi.all.fdr)
phi.all.fdr.nona.sort <- phi.all.fdr[order(fdr.p.value, p.value, na.last=NA),]
phivalfdrperms <- paste("\n********************************\nPhi results with FDR corrections\n(only valid p-values shown, ", perms, " permutations):\n", sep="")
writeLines(phivalfdrperms)
phi.all.fdr.nona.sort

## Blank line at end of file
writeLines("")
## End
q()
