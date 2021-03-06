#!/usr/bin/env Rscript
#
#  phyloseq_network.r - R slave to generate network graph through phyloseq
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

## Recieve input files from bash
args <- commandArgs(TRUE)

otufile=(args[1])
mapfile=(args[2])
factor=(args[3])
outdir=(args[4])

## Load data into phyloseq
map=import_qiime_sample_data(mapfile)
otus=import_biom(otufile,parseFunction=parse_taxonomy_greengenes)
mergedata=merge_phyloseq(otus,map)

## Make older network (plot_network command)
ig <- make_network(mergedata, type="samples", distance="bray", max.dist="0.9")
networkout <- plot_network(ig, mergedata, color=factor, label=NULL)

## Make newer network (plot_net command)
netout <- plot_net(mergedata, maxdist = "0.9", color=factor, distance="bray")

## Write to output
pdf(paste0(outdir, factor, "_network.pdf"))
plot(networkout)
dev.off()

## Change pdf resolution like this (doesnt change text size):
#pdf("network.pdf", height = 12, width = 12)

## .png output instead
#png('network.png', height="12")
#plot(networkout)
#dev.off()

## plot_net function.  Odd-looking plots.
#pdf('net.pdf')
#plot(netout)
#dev.off

## End
q()
