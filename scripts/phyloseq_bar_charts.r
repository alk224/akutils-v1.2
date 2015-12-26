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

## Make a tree
treeout <- plot_tree(mergedata, color = factor, label.tips = "Species", plot.margin = 0.5, ladderize = "left", nodelabf = nodeplotboot(), size = "abundance", base.spacing = 0.03, shape = "Class")

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

