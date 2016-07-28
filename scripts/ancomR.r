#!/usr/bin/env Rscript
#
#  ancomR.r - R slave for analysis in the R package ANCOM
#
#  Version 1.0.0 (February, 17, 2016)
#
#  Copyright (c) 2015 Andrew Krohn
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
otufile=(args[1])
factor=(args[2])
outdir=(args[3])

## Load libraries
library(ancom.R)

## Read in data
otus <- read.table(otufile, sep="\t", header=TRUE)

## Run ancom without multiple corrections
ancom.out <- ANCOM(real.data=otus,sig=0.05,multcorr=3)
detections <- ancom.out$detected
write(detections, paste0(outdir, "ANCOM_detections_", factor, "_uncorrected.txt"))
plot <- plot_ancom(ancom.out)
pdf(paste0(outdir, "ANCOM_", factor, "_uncorrected.pdf"))
plot(plot)

## Run ancom with FDR correction
ancom.out.fdr <- ANCOM(real.data=otus,sig=0.05,multcorr=2)
detections.fdr <- ancom.out.fdr$detected
write(detections.fdr, paste0(outdir, "ANCOM_detections_", factor, "_FDRcorrected.txt"))
plot.fdr <- plot_ancom(ancom.out.fdr)
pdf(paste0(outdir, "ANCOM_", factor, "_FDRcorrected.pdf"))
plot(plot.fdr)

## End
q()

