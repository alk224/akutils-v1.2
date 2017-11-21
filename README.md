###akutils-v1.2 README  


This is a collection of scripts I wrote to make myself more productive while doing microbial ecology work with QIIME. I was having difficulty knowing that I was making the best decisions in my analyses, so I started writing this as an exercise in getting to know better the QIIME commands that I was using. I can now use it to run many OTU picking workflows in a row and it generates the plots and stats that I like to have access to right away. This avoids the tedium of entering many commands and helps to keep me organized. I do everything on a Linux system (Ubuntu 14.04). I have also tested most things on CentOS 6.6 (monsoon cluster at Northern Arizona University). You should be comfortable installing packages and such that may be required. For more information on the functionality of akutils, [check out the wiki pages.](https://github.com/alk224/akutils-v1.2/wiki)  

[Also see the home page for short install instructions.](http://alk224.github.io/akutils-v1.2/)  

If you like akutils, please Star this repository (Star button at top of page)

**Getting akutils on your local system (workstation or VirtualBox):**

**1)** Set up your system appropriately. I have done this on a large workstation as well as within a VirtualBox on my netbook. Install Ubuntu 14.04LTS. I have had trouble with 14.04.3 base installs so prefer 14.04.1 install ([download .iso here](http://old-releases.ubuntu.com/releases/14.04.2/ubuntu-14.04.1-desktop-amd64.iso)) and then update.

**2)** Get all programs and dependencies installed. The easiest way is with [my installer script.](https://github.com/alk224/akutils_ubuntu_installer) Instructions are there to fix the screen size in a Virtualbox guest as well as to update and run all installation. This part takes a long time and requires a decent internet connection.

**3)** Clone the akutils-v1.2 repository:

     git clone https://github.com/alk224/akutils-v1.2.git

**4)** Run install script to add akutils to PATH and enable command autocompletion.

     cd akutils-v1.2  
     bash install  

**Getting akutils on your compute cluster:**  

**1)** No guarantees! This works on Ubuntu 14.04 and Centos 6.6. Maybe other systems too.  

**2)** Have your sysadmin install the necessary packages:  

 -- QIIME 1.9.1 (https://qiime.org)  
 -- ea-utils (https://code.google.com/p/ea-utils/)  
 -- Fastx toolkit (http://hannonlab.cshl.edu/fastx_toolkit/)  
 -- vsearch (https://github.com/torognes/vsearch)  
 -- ITSx (http://microbiology.se/software/itsx/)  
 -- Smalt (https://www.sanger.ac.uk/resources/software/smalt/)  
 -- HMMer v3+ (http://hmmer.janelia.org/)  
 -- Mafft (http://mafft.cbrc.jp/alignment/software/)  
 -- Phyloseq (http://joey711.github.io/phyloseq/)  
 -- Ancom (https://www.niehs.nih.gov/research/resources/software/biostatistics/ancom/index.cfm)  
 -- datamash (https://www.gnu.org/software/datamash/)  
 -- fasta-splitter.pl (http://kirill-kryukov.com/study/tools/fasta-splitter/)  
 -- cutadapt (http://cutadapt.readthedocs.io/en/stable/index.html)  

**3)** Clone the repository and run the install script (steps 3-4 above).  

If you find any problems or have ideas for useful functionality, you can [submit an issue via github.](https://github.com/alk224/akutils-v1.2/issues)  

**Updating:**  

If (when) I make useful changes, I will push them to the repo. To benefit from these changes, execute:  

     akutils update

After this, check your configuration:  

     akutils print_config  

If new configurable options are available, you will be instructed to run the config utility and choose "rebuild" to make a fresh global config file which will contain the new options. Older config files may not function correctly after an update. This can cause some scripts to miss a variable import without a config file to match the version of that script.  

**Citing akutils:**  

Lela Andrews. (2016). akutils-v1.2: Facilitating analyses of microbial communities through QIIME. Zenodo. 10.5281/zenodo.61581

[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.61581.svg)](http://dx.doi.org/10.5281/zenodo.61581)
