#!/usr/bin/env Rscript
#
#  phyloseq_tree.r - generate tree graphic through phyloseq
#
#  Version 1.0.0 (December 24, 2015)
#
#  Copyright (c) 2014-2015 Andrew Krohn
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

## Load libraries
library(phyloseq)
library(ggplot2)
library(scales)
library(grid)
library(plyr)
theme_set(theme_bw())

## Recieve input files from bash
args <- commandArgs(TRUE)

otufile=(args[1])
mapfile=(args[2])
treefile=(args[3])
factor=(args[4])

## Load data into phyloseq
map=import_qiime_sample_data(mapfile)
tree=read_tree(treefile)
otus=import_biom(otufile,parseFunction=parse_taxonomy_greengenes)
mergedata=merge_phyloseq(otus,tree,map)
MD=mergedata

## Filter taxa not present at least 5 times in at least 10% of samples
md0 = genefilter_sample(MD, filterfun_sample(function(x) x > 5), A = 0.1 * nsamples(MD))
MD1=prune_taxa(md0, MD)

## Make taxa-only ordination (NMDS)
MD.ord <- ordinate(MD1, "NMDS", "bray")
p1 = plot_ordination(MD1, MD.ord, type = "taxa", color = "Class", title = "Taxonomic ordination (NMDS)")
## Output pdf graphic
pdf(paste0(factor, "_taxa-only_NMDS.pdf"))
plot(p1)
dev.off()

## Make faceted version of taxa-only ordination
#p1 + facet_wrap(~Class, 2)
## Output pdf graphic
pdf(paste0(factor, "_taxa-only-faceted_NMDS.pdf"))
plot(p1 + facet_wrap(~Class, 2))
dev.off()

## Make samples-only ordination (NMDS)
p2 = plot_ordination(MD1, MD.ord, type = "samples", color = factor, title = "Samples ordination (NMDS)")
## Output pdf graphic
pdf(paste0(factor, "_samples-only_NMDS.pdf"))
plot(p2)
dev.off()

## Samples-only ordination with polygon fill
#p2 + geom_polygon(aes(fill = factor)) + geom_point(size = 5) + ggtitle("Samples ordination with fill (NMDS)")
## Output pdf graphic
pdf(paste0(factor, "_samples-only-polygon_NMDS.pdf"))
plot(p2 + geom_polygon(aes(fill = factor)) + geom_point(size = 5) + ggtitle("Samples ordination with fill (NMDS)"))
dev.off()

## Make biplot
p3 = plot_ordination(MD1, MD.ord, type = "biplot", color = factor, shape = "Class", title = "Biplot")
#MD1.shape.names = get_taxa_unique(MD1, "Class")
#MD1.shape <- 15:(15 + length(MD1.shape.names) - 1)
#names(MD1.shape) <- MD1.shape.names
#MD1.shape["samples"] <- 16
#p3 + scale_shape_manual(values = MD1.shape)
## Output pdf graphic
pdf(paste0(factor, "_biplot_NMDS.pdf"))
plot(p3)
dev.off()

## Make splitplot
p4 = plot_ordination(MD1, MD.ord, type = "split", color = "Class", shape = factor, title = "split") + geom_point(size = 5)






## Output pdf graphic
pdf(paste0(factor, "_tree.pdf"))
plot(treeout)
dev.off()

## Change pdf resolution like this (doesnt change text size):
#pdf("network.pdf", height = 12, width = 12)

## .png output instead
#png('network.png', height="12")
#plot(networkout)
#dev.off()

