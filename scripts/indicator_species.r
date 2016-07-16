#!/usr/bin/env Rscript
#
#  indicator_species.r - R slave for indicator species analysis with R package indicspecies
#
#  Version 1.0.0 (July, 16, 2016)
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
mapfile=(args[1])
biomfile=(args[2])
factor=(args[3])
outdir=(args[4])

## Load libraries
library(indicspecies)

## Read in data
map <- read.csv(mapfile, sep="\t", header=TRUE)
biom <- read.csv(biomfile, sep="\t", header=TRUE)
f1 <- map[,factor]

## Run indval and print to screen
writeLines("\n********************************\nIndicator value analysis:")
indval = multipatt(biom, f1, control=how(nperm=999))
summary(indval)

## Run coverage and print to screen
writeLines("\n********************************\nCoverage (IndVal):")
coverage(biom, indval)

## Run phi and print to screen
writeLines("\n********************************\nPearson's phi coefficient of association:")
phi = multipatt(biom, f1, func="r.g", control=how(nperm=999))
summary(phi)

## Run coverage and print to screen
writeLines("\n********************************\nCoverage (Phi):")
coverage(biom, phi)

writeLines("")
## End
q()
