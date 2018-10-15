#!/usr/bin/env python
## This file comes from Jennifer Fourquier's excellent ghost-tree project
## Some modifications by Lela Andrews to fit within akutils framework
##
## Ghost-tree is provided under BSD license
##
## Copyright (c) 2015--, ghost-tree development team.
## All rights reserved.
##
"""
This file can be downloaded and used to create a .txt file containing only
the accession numbers from the ghost-tree.nwk that you plan to use for your
analyses.
You must have skbio installed. http://scikit-bio.org/
You will then use "ghost_tree_tips.txt" output file containing the accession
numbers to filter your .biom table so that it contains only the OTUs that
are in the ghost-tree.nwk that you are using.
http://qiime.org/scripts/filter_otus_from_otu_table.html
Use the required arguments and the following two optional arguments:
-e, --otu_ids_to_exclude_fp
(provide the text file containing OTU ids to exclude)
--negate_ids_to_exclude
(this will keep OTUs in otu_ids_to_exclude_fp, rather than discard them)
"""

## Import modules
import os
from skbio import TreeNode

## Read in variables from bash and set tips file name
intree = os.getenv("tree")
randcode = os.getenv("randcode")
tempdir = os.getenv("tempdir")
tipsfile = os.path.join(tempdir + "/" + randcode + "_ghost_tree_tips.txt")

## Filter OTU table against supplied tree
ghosttree = TreeNode.read(intree)
output = open(tipsfile, "w")

for node in ghosttree.tips():
    output.write(str(node.name)+"\n")

output.close()

