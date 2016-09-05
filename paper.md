### akutils v1.2: Facilitating analyses of microbial communities through QIIME 1.9.1  

### Summary  
akutils v1.2 is a collection of scripts meant to streamline analyses of community amplicon DNA sequencing data through QIIME 1.9.1 (Caporaso *et al.*, 2010). In addition, it adds functions for data pre-processing (primer and PhiX sequence removal from Illumina MiSeq data sets), database management (formatting a reference database to the sequenced region) and provides new functions for fastq/a file and OTU table manipulations (*e.g.*, fastq file concatenation, fastq/a length histograms, filtering fastq/a by length, filtering OTU tables by observation). It automates tasks commonly associated with data analysis through QIIME as long as certain conventions are met. The main functions are pick_otus (takes raw fastq data all the way to an OTU table), align_and_tree (alignment of representative sequences and phylogenetic tree construction), and core_diversity (production of graphs and statistical analyses). The core_diversity output provides access to all input files and transformed derivatives, a well-organized output including sequences extracted for each OTU, phylum-level phylogenetic tree representation via phyloseq (McMurdie & Homes, 2013), and analyses performed with rarefied data, or using the popular cumulative sum scaling (Paulson *et al.*, 2013) or DESeq2 (Love *et al.*, 2014) data normalizations. In addition to standard QIIME output, statistical tests of differential abundance are provided via indicator species analysis (Cáceres & Legendre, 2009) and analysis of composition of microbiomes (Mandal *et al.*, 2015).  

Complete documentation including a list of required dependencies, installation instructions and an installation tool for Ubuntu 14.04 LTS can be accessed from the repository homepage at http://alk224.github.io/akutils-v1.2/.  

### References  

Caporaso, J. G., Kuczynski, J., Stombaugh, J., Bittinger, K., Bushman, F. D., Costello, E. K., … Knight, R. (2010). QIIME allows analysis of high-throughput community sequencing data. Nature Methods, 7(5), 335–6. http://doi.org/10.1038/nmeth.f.303  

Cáceres, M. De, & Legendre, P. (2009). Associations between species and groups of sites: indices and statistical inference. Ecology, 90(12), 3566–3574. http://doi.org/10.1890/08-1823.1  

Love, M. I., Huber, W., & Anders, S. (2014). Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. Genome Biology, 15(12), 550. http://doi.org/10.1186/s13059-014-0550-8  

Mandal, S., Van Treuren, W., White, R. A., Eggesbø, M., Knight, R., & Peddada, S. D. (2015). Analysis of composition of microbiomes: a novel method for studying microbial composition. Microbial Ecology in Health and Disease, 26, 27663. http://doi.org/10.3402/mehd.v26.27663  

McMurdie, P. J., & Holmes, S. (2013). phyloseq: an R package for reproducible interactive analysis and graphics of microbiome census data. PloS One, 8(4), e61217. http://doi.org/10.1371/journal.pone.0061217  

Paulson, J. N., Stine, O. C., Bravo, H. C., & Pop, M. (2013). Differential abundance analysis for microbial marker-gene surveys. Nature Methods, 10(12), 1200–2. http://doi.org/10.1038/nmeth.2658  




