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
alpha=(args[4])
akutilsres=(args[5])
ncores=(args[6])

## Load libraries
library(ancom.R)

## Replace functions for parallel processing
akutils_ANCOM <- paste0(akutilsres, "ANCOM.akutils.r")
akutils_ancom.detect <- paste0(akutilsres, "ancom.detect.akutils.r")
source(akutils_ANCOM)
source(akutils_ancom.detect)

## Read in data
otus <- read.table(otufile, sep="\t", header=TRUE)

## Run ancom without multiple corrections
ancom.out <- ANCOM(real.data=otus,sig=alpha,multcorr=3)
detections <- ancom.out$detected
plot.un <- plot_ancom(ancom.out)
write(detections, paste0(outdir, "ANCOM_detections_", factor, "_uncorrected.txt"))

## Run ancom with FDR correction (relaxed)
ancom.out.fdr.2 <- ANCOM(real.data=otus,sig=alpha,multcorr=2)
detections.fdr.2 <- ancom.out.fdr.2$detected
plot.fdr.2 <- plot_ancom(ancom.out.fdr.2)
write(detections.fdr.2, paste0(outdir, "ANCOM_detections_", factor, "_FDRrelaxed.txt"))

## Run ancom with FDR correction (strict)
ancom.out.fdr.1 <- ANCOM(real.data=otus,sig=alpha,multcorr=1)
detections.fdr.1 <- ancom.out.fdr.1$detected
plot.fdr.1 <- plot_ancom(ancom.out.fdr.1)
write(detections.fdr.1, paste0(outdir, "ANCOM_detections_", factor, "_FDRstrict.txt"))

## Write pdf output
pdf(paste0(outdir, "Detection_plots.pdf"),width=12,height=12)
plot.new()
mtext(text="Uncorrected detections plots",cex=3)
plot.un
plot.new()
mtext(text="Relaxed FDR corrected detections plots",cex=3)
plot.fdr.2
plot.new()
mtext(text="Strict FDR corrected detections plots",cex=3)
plot.fdr.1
dev.off()

## Produce statistical summary
names0 <- colnames(otus)
counts0 <- ncol(otus)
counts1 <- counts0-1
Group <- names0[1:counts1]
ancom.W <- ancom.out$W
ancom.W.FDRstrict <- ancom.out.fdr.1$W
ancom.W.FDR <- ancom.out.fdr.2$W
Result <- cbind(Group,ancom.W,ancom.W.FDR,ancom.W.FDRstrict)
Result.sort <- Result[order(-ancom.W.FDRstrict, -ancom.W.FDR, -ancom.W, na.last=NA),]
write.table(Result.sort, paste0(outdir, "Rstats.txt"), sep="\t", row.names=FALSE, quote=FALSE)

## End
q()

