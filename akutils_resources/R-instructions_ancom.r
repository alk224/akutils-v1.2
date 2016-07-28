
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
plot <- plot_ancom(ancom.out)

## List detected OTUs/taxa
detections

## Generate plots of any detections
plot(plot)

## Run ancom with FDR correction -- note that multcorr=2 is less stringent than multcorr=1
## Significance level is set at 0.05
ancom.out.fdr <- ANCOM(real.data=otus,sig=0.05,multcorr=2) 
detections.fdr <- ancom.out.fdr$detected
plot.fdr <- plot_ancom(ancom.out.fdr)

## List detected OTUs/taxa
detections.fdr

## Generate plots of any detections
plot(plot.fdr)

## See the ancom.R documentation for more functionality:
## http://www.niehs.nih.gov/research/resources/software/biostatistics/ancom/index.cfm

