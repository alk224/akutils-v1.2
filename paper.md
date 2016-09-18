---
title: 'akutils v1.2: Facilitating analyses of microbial communities through QIIME 1.9.1'
tags:
  - QIIME
  - microbial ecology
  - amplicon sequencing
authors:
 - name: Andrew Krohn
   orcid: 0000-0002-3957-2474
   affiliation: GitHub Inc.
date: 18 September 2016
bibliography: paper.bib
---

# Summary

akutils v1.2 is a collection of scripts meant to streamline analyses of community amplicon DNA sequencing data through QIIME 1.9.1 (Caporaso *et al.*, 2010). In addition, it adds functions for data pre-processing (primer and PhiX sequence removal from Illumina MiSeq data sets), database management (formatting a reference database to the sequenced region) and provides new functions for fastq/a file and OTU table manipulations (*e.g.*, fastq file concatenation, fastq/a length histograms, filtering fastq/a by length, filtering OTU tables by observation). It automates tasks commonly associated with data analysis through QIIME as long as certain conventions are met. The main functions are pick_otus (takes raw fastq data all the way to an OTU table), align_and_tree (alignment of representative sequences and phylogenetic tree construction), and core_diversity (production of graphs and statistical analyses). The core_diversity output provides access to all input files and transformed derivatives, a well-organized output including sequences extracted for each OTU, phylum-level phylogenetic tree representation via phyloseq (McMurdie & Homes, 2013), and analyses performed with rarefied data, or using the popular cumulative sum scaling (Paulson *et al.*, 2013) or DESeq2 (Love *et al.*, 2014) data normalizations. In addition to standard QIIME output, statistical tests of differential abundance are provided via indicator species analysis (Cáceres & Legendre, 2009) and analysis of composition of microbiomes (Mandal *et al.*, 2015).  

Complete documentation including a list of required dependencies, installation instructions and an installation tool for Ubuntu 14.04 LTS can be accessed from the repository homepage at http://alk224.github.io/akutils-v1.2/.

# References

