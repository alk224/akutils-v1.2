
## Instructions to run your output files in R manually (with ancom package)

## You will need the following files (output from ancomR.sh):
##	1) otufile_for_ancom.txt (OTU table formatted for ancom)

## Open R
R

## Load ancom
library(ancom.R)

## Read in your file
otufile="otufile_for_ancom.txt"
otus <- read.table(otufile, sep="\t", header=TRUE)

## Run ancom without multiple corrections
## Significance level is set at 0.05
ancom.out <- ANCOM(real.data=otus,sig=0.05,multcorr=3)
detections <- ancom.out$detected
plot.un <- plot_ancom(ancom.out)

## List detected OTUs/taxa and generate plots
detections
plot.un

## Run ancom with relaxed FDR correction -- note that multcorr=2 is less stringent than multcorr=1
## Significance level is set at 0.05
ancom.out.fdr.2 <- ANCOM(real.data=otus,sig=0.05,multcorr=2) 
detections.fdr.2 <- ancom.out.fdr.2$detected
plot.fdr.2 <- plot_ancom(ancom.out.fdr.2)

## List detected OTUs/taxa and generate plots
detections.fdr.2
plot.fdr.2

## Run ancom with strict FDR correction
## Significance level is set at 0.05
ancom.out.fdr.1 <- ANCOM(real.data=otus,sig=0.05,multcorr=1) 
detections.fdr.1 <- ancom.out.fdr.1$detected
plot.fdr.1 <- plot_ancom(ancom.out.fdr.1)

## List detected OTUs/taxa and generate plots
detections.fdr.1
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

## View Statistics
Result

## See the ancom.R documentation for more functionality:
## http://www.niehs.nih.gov/research/resources/software/biostatistics/ancom/index.cfm

