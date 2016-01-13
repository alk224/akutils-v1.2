#!/usr/bin/env Rscript
#
# make_ggplot_taxa_plots.r - Make QIIME-like taxa plots but with ggplot2
#
#  phyloseq_network.r - R slave to generate network graph through phyloseq
#
#  Version 0.0.1 (January 11, 2016)
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

## Should add .sh script to manipulate input data for this script, then call this
## script, and silence annoying R outputs.

## Load libraries
library(ggplot2)
library(reshape2)
library(plyr)
library(dplyr)
#library(lazyeval)

## Recieve input files from bash
args <- commandArgs(TRUE)
otufile=(args[1])
xfactor=(args[2])
Width=(args[3])
Palette=(args[4])

## Fix variable name for useful parsing
#interp(xfactor, xfactor = as.name(xfactor))
#interp(xfactor)

################################
## Set colorblind color palettes
## 7-color palette from Wong, B. (2011) Nature Methods 8:441
WongPalette <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

## 8-color palette from ggplot tutorial (Wong plus black)
WongPalette1 <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

## 8-color palette from ggplot tutorial (Wong plus grey)
WongPalette2 <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

## Read in data, transform and apply labels
dat <- read.csv(otufile)
dat.m <- melt(dat)
dat.OTU <- rename(dat.m,Drought=variable,Abundance=value)
#colnames(dat.OTU)[colnames(dat.OTU)=="value"] <- "Abundance"
#colnames(dat.OTU)[colnames(dat.OTU)=="variable"] <- xfactor

## Summarize by taxonomic levels
dat.Kingdom <- ddply(dat.OTU,.(Kingdom,Drought),summarize,Kingdom_Abundance=sum(Abundance))
dat.Phylum <- ddply(dat.OTU,.(Phylum,Drought),summarize,Phylum_Abundance=sum(Abundance))
#dat.Class <- ddply(dat.OTU,.(Class,xfactor),summarize,Class_Abundance=sum(Abundance))
#dat.Order <- ddply(dat.OTU,.(Order,xfactor),summarize,Order_Abundance=sum(Abundance))
#dat.Family <- ddply(dat.OTU,.(Family,xfactor),summarize,Family_Abundance=sum(Abundance))
#dat.Genus <- ddply(dat.OTU,.(Genus,xfactor),summarize,Genus_Abundance=sum(Abundance))
#dat.Species <- ddply(dat.OTU,.(Species,xfactor),summarize,Species_Abundance=sum(Abundance))

################
## Produce plots
	# Kingdom plot
p.Kingdom <- ggplot(dat.Kingdom,aes_string(x=(xfactor),y="Kingdom_Abundance",fill="Kingdom"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette2),10000), drop=FALSE)
	# Write to output
pdf(paste0("Kingdom_", xfactor, "_taxa_plot.pdf"))
plot(p.Kingdom)

	# Phylum plot
p.Phylum <- ggplot(dat.Phylum,aes_string(x=(xfactor),y="Phylum_Abundance",fill="Phylum"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette2),10000), drop=FALSE)
	# Write to output
pdf(paste0("Phylum_", xfactor, "_taxa_plot.pdf"))
plot(p.Phylum)
q()
	# Class plot
p.Class <- ggplot(dat.Class,aes_string(x=(xfactor),y="Class_Abundance",fill="Class"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette),10000), drop=FALSE)
	# Write to output
pdf(paste0("Class_", xfactor, "_taxa_plot.pdf"))
plot(p.Class)

	# Order plot
p.Order <- ggplot(dat.Order,aes_string(x=(xfactor),y="Order_Abundance",fill="Order"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette),10000), drop=FALSE)
	# Write to output
pdf(paste0("Order_", xfactor, "_taxa_plot.pdf"))
plot(p.Order)

	# Family plot
p.Family <- ggplot(dat.Family,aes_string(x=(xfactor),y="Family_Abundance",fill="Family"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette),10000), drop=FALSE)
	# Write to output
pdf(paste0("Family_", xfactor, "_taxa_plot.pdf"))
plot(p.Family)

	# Genus plot
p.Genus <- ggplot(dat.Genus,aes_string(x=(xfactor),y="Genus_Abundance",fill="Genus"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette),10000), drop=FALSE)
	# Write to output
pdf(paste0("Genus_", xfactor, "_taxa_plot.pdf"))
plot(p.Genus)

	# Species plot
p.Species <- ggplot(dat.Species,aes_string(x=(xfactor),y="Species_Abundance",fill="Species"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette),10000), drop=FALSE)
	# Write to output
pdf(paste0("Species_", xfactor, "_taxa_plot.pdf"))
plot(p.Species)

	# OTU plot
p.OTU <- ggplot(dat.OTU,aes_string(x=(xfactor),y="Abundance",fill="OTU"))+
  theme_minimal()+
  geom_bar(stat="identity",color="Black",width=0.3)+
  ylab("Relative abundance")+
  scale_y_continuous(labels=scales::percent)+
  scale_fill_manual(values=rep(c(WongPalette),10000), drop=FALSE)
	# Write to output
pdf(paste0("OTU_", xfactor, "_taxa_plot.pdf"))
plot(p.OTU)

