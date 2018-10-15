#!/usr/bin/env Rscript
#
#  phyloseq_ordination_p1.r - generate p1 ordination graphic through phyloseq
#
#  Version 1.0.0 (December 24, 2015)
#
#  Copyright (c) 2014-- Lela Andrews
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

## Ordinate command
MD.ord <- ordinate(MD1, "NMDS", "bray")

## Make taxa-only ordination (NMDS)
p1 = plot_ordination(MD1, MD.ord, type = "taxa", color = "Class", title = "Taxonomic ordination (NMDS)")
## Output pdf graphic
pdf(paste0(factor, "_taxa-only_NMDS.pdf"))
plot(p1)
dev.off()

