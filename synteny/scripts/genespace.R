#!/usr/bin/env Rscript
library(GENESPACE)
###############################################
# -- change paths to those valid on your system
wd <- "/bigdata/stajichlab/shared/projects/Afumigatus_RefStrains/synteny"
path2mcscanx <- "/opt/linux/rocky/8.x/x86_64/pkgs/MCScanX/r51_g97e74f4"
###############################################

	gpar <- init_genespace(
		genomeIDs = c("Af293", "A1163",
		"47_10", "47_4", "ATCC_13073","ATCC_42202","ATCC_46645", "B5233","CEA10", "D141","H237","S02_30", "TP9","W72310"),
		outgroup = NULL,
		ploidy = rep(1,1,1,1,1,1,1,1,1,1,1),
		diamondUltraSens = TRUE,
		wd = wd,
		orthofinderInBlk = FALSE,
		nCores = 48,
		path2orthofinder = "orthofinder",
		path2diamond = "diamond",
		path2mcscanx = path2mcscanx,
	)

# -- accomplish the run
out <- run_genespace(gpar,overwrite = T)
