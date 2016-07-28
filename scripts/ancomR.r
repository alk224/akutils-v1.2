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
plot.un <- plot_ancom(ancom.out)
pdf(paste0(outdir, "ANCOM_", factor, "_uncorrected.pdf"))
plot.un

## Run ancom with FDR correction (relaxed)
ancom.out.fdr.2 <- ANCOM(real.data=otus,sig=0.05,multcorr=2)
detections.fdr.2 <- ancom.out.fdr.2$detected
write(detections.fdr.2, paste0(outdir, "ANCOM_detections_", factor, "_FDRrelaxed.txt"))
plot.fdr.2 <- plot_ancom(ancom.out.fdr.2)
pdf(paste0(outdir, "ANCOM_", factor, "_FDRrelaxed.pdf"))
plot.fdr.2

## Run ancom with FDR correction (strict)
ancom.out.fdr.1 <- ANCOM(real.data=otus,sig=0.05,multcorr=1)
detections.fdr.1 <- ancom.out.fdr.1$detected
write(detections.fdr.1, paste0(outdir, "ANCOM_detections_", factor, "_FDRstrict.txt"))
plot.fdr.1 <- plot_ancom(ancom.out.fdr.1)
pdf(paste0(outdir, "ANCOM_", factor, "_FDRstrict.pdf"))
plot.fdr.1

## Produce statistical summary
names0 <- colnames(otus)
counts0 <- ncol(otus)
counts1 <- counts0-1
Group <- names0[1:counts1]
WStat_NoCorrection <- ancom.out$W
WStat_Correction1 <- ancom.out.fdr.1$W
WStat_Correction2 <- ancom.out.fdr.2$W
Result <- cbind(Group,WStat_NoCorrection,WStat_Correction1,WStat_Correction2)
write.table(Result, paste0(outdir, "Statistical_summary.txt"), sep="\t", row.names=FALSE, quote=FALSE)

## End
q()

