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
fastq=(args[1])
outfile=(args[2])

## Load libraries
library(seqTools)
options(width=300)

## Read in data
fq <- fastqq(fastq)

## Write to output
pdf(outfile, width=11, height=8.5)
plot.new()
text(0.5,0.8,paste0("FASTQ SUMMARY:     ",fastq))
text(0.5,0.8,paste0("FASTQ SUMMARY:     ",fastq))
text(0.5,0.8,paste0("FASTQ SUMMARY:     ",fastq))
text(0.453,0.75,paste0("Read count:     ", fq@nReads))
text(0.499,0.7,paste0("Max Sequence Length:     ", fq@seqLen[2]))
text(0.498,0.65,paste0("Min Sequence Length:","     ", fq@seqLen[1]))
text(0.453,0.6,paste0("Read count:     ", fq@nReads))
text(0.5,0.55,paste0("Ambiguous (N) base calls:     ", fq@nN))
text(0.5,0.4,paste0("fastq_data.sh -- https://github.com/alk224/akutils-v1.2"))
plotMergedPhredQuant(fq)
title("Q-score distribution",plotPhredDist(fq))
plotNucFreq(fq,1)
plotGCcontent(fq)
plotKmerCount(fq,mxey=10)
dev.off()

## End
q()

