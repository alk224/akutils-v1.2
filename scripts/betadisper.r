#!/usr/bin/env Rscript
#
#  two-way_permanova.r - R slave for two-way permanova analysis with R package vegan
#
#  Version 1.0.0 (July, 15, 2016)
#
#  Copyright (c) 2016 Andrew Krohn
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
map=(args[1])
dmfile=(args[2])
factor1=(args[3])
factor2=(args[4])
dmname=(args[5])
f2temp=(args[6])
outdir=(args[7])

## Load libraries
library(vegan)

## Read in data
mapfile <- read.csv(map, sep="\t", header=TRUE)
dm0 <- read.csv(dmfile, sep="\t", header=TRUE)
dm <- as.dist(dm0)
f1 <- mapfile[,factor1]
f2 <- mapfile[,factor2]
f3 <- paste(f1, f2)

## Run betadisper and print to screen
pd <- betadisper(dm, f3)
pd

## Permutation test of dispersions, printing to screen
permutest(pd, permutations = 999)

## Tukey HSD test and print to screen
writeLines("********************************\nTukey's HSD test of dispersions across groups\n")
pd.HSD <- TukeyHSD(pd)
pd.HSD

## PCoA plots and boxplots of multivariate dispersions, write to pdf file
Permdisp <- pd
pdf(paste0(outdir, "/Permdisp_plots.pdf"), width=12, height=12)
par(mfrow=c(2,2))
plot(Permdisp, label.cex=0.5, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, sub=dmname, main="PCoA axes 1 vs 2", cex.main=1.5, cex.sub=1.25, cex.lab=1.1, axes=c(1,2))
plot(Permdisp, label.cex=0.5, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, sub=dmname, main="PCoA axes 1 vs 3", cex.main=1.5, cex.sub=1.25, cex.lab=1.1, axes=c(1,3))
plot(Permdisp, label.cex=0.5, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, sub=dmname, main="PCoA axes 2 vs 3", cex.main=1.5, cex.sub=1.25, cex.lab=1.1, axes=c(2,3))
boxplot(pd, main="Boxplots of multivariate dispersions", sub="Categories", cex.axis=0.75, cex.main=1.5, cex.sub=1.25, cex.lab=1.25)

## End
q()
