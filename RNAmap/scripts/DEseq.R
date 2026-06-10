#!/usr/bin/env Rscript
# DESeq2 analysis of Afumigatus pangenome RNASeq data
# Reads: HetSet_SOG_metadata.tsv + count matrix (SOG_ID x sample)
# Outputs: VST-normalized data, non-length-corrected TPM (CPM), PCA/PCoA/NMDS plots, DE results

suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(ggrepel)
  library(vegan)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(tibble)
  library(RColorBrewer)
})

# ── Paths ─────────────────────────────────────────────────────────────────────
COUNTS_FILE   <- file.path("Afumigatus_Pangenome_Final_A1163_Anchored.with_core_accessory.count_matrix.tsv.gz")
METADATA_FILE <- file.path("HetSet_SOG_metadata.tsv")
OUTDIR        <- file.path("results", "DEseq2")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

# ── Load data ─────────────────────────────────────────────────────────────────
message("Loading metadata...")
meta <- read_tsv(METADATA_FILE, col_types = cols(.default = "c")) %>%
  filter(qc == "PASS") %>%
  mutate(
    condition = factor(condition, levels = c("normoxia", "hypoxia")),
    clade     = factor(clade),
    strainName = factor(strainName)
  ) %>%
  column_to_rownames("cSample_names")

message("Loading count matrix...")
counts_raw <- read_tsv(COUNTS_FILE, col_types = cols(.default = "d", SOG_ID = "c"))
counts_mat  <- counts_raw %>%
  column_to_rownames("SOG_ID") %>%
  as.matrix()

# Keep only PASS samples that are present in the count matrix
keep_samples <- intersect(rownames(meta), colnames(counts_mat))
message(sprintf("Samples after QC filter: %d", length(keep_samples)))

counts_mat <- counts_mat[, keep_samples]
meta       <- meta[keep_samples, ]

# Remove genes with zero counts across all kept samples
counts_mat <- counts_mat[rowSums(counts_mat) > 0, ]
message(sprintf("Genes with at least one count: %d", nrow(counts_mat)))

# ── Non-length-corrected TPM (CPM) ───────────────────────────────────────────
message("Computing CPM (non-length-corrected TPM)...")
lib_sizes <- colSums(counts_mat)
cpm_mat   <- sweep(counts_mat, 2, lib_sizes / 1e6, FUN = "/")

# Average CPM per strain x condition
cpm_df <- as.data.frame(cpm_mat) %>%
  tibble::rownames_to_column("SOG_ID")

cpm_long <- cpm_df %>%
  pivot_longer(-SOG_ID, names_to = "cSample_names", values_to = "CPM") %>%
  left_join(
    meta %>% tibble::rownames_to_column("cSample_names") %>%
      select(cSample_names, strainName, condition),
    by = "cSample_names"
  )

cpm_avg <- cpm_long %>%
  group_by(SOG_ID, strainName, condition) %>%
  summarise(mean_CPM = mean(CPM), .groups = "drop") %>%
  unite("sample_condition", strainName, condition, sep = "_") %>%
  pivot_wider(names_from = sample_condition, values_from = mean_CPM)

write_csv(cpm_avg, file.path(OUTDIR, "CPM_replicate_averaged.csv"))
write_csv(
  as.data.frame(cpm_mat) %>% tibble::rownames_to_column("SOG_ID"),
  file.path(OUTDIR, "CPM_per_sample.csv")
)
message("CPM tables written.")

# ── DESeq2 object ─────────────────────────────────────────────────────────────
message("Building DESeq2 object...")
dds <- DESeqDataSetFromMatrix(
  countData = counts_mat,
  colData   = meta,
  design    = ~ clade + condition
)

# Pre-filter: keep genes with >= 10 counts in at least 3 samples
keep <- rowSums(counts(dds) >= 10) >= 3
dds  <- dds[keep, ]
message(sprintf("Genes after low-count filter: %d", sum(keep)))

# ── VST ───────────────────────────────────────────────────────────────────────
message("Running VST...")
vst_obj  <- vst(dds, blind = TRUE)
vst_mat  <- assay(vst_obj)

write_csv(
  as.data.frame(vst_mat) %>% tibble::rownames_to_column("SOG_ID"),
  file.path(OUTDIR, "VST_normalized.csv")
)

# ── Colour palette helpers ────────────────────────────────────────────────────
condition_colors <- c(normoxia = "#4393C3", hypoxia = "#D6604D")
clade_shapes     <- c(C1 = 16, C2 = 17, C3 = 15)

# ── PCA ───────────────────────────────────────────────────────────────────────
message("Plotting PCA...")
pca_data <- plotPCA(vst_obj, intgroup = c("condition", "clade", "strainName"),
                    returnData = TRUE)
pct_var  <- round(100 * attr(pca_data, "percentVar"), 1)

p_pca <- ggplot(pca_data, aes(PC1, PC2,
                               colour = condition,
                               shape  = clade,
                               label  = strainName)) +
  geom_point(size = 3, alpha = 0.85) +
  geom_text_repel(size = 2.5, max.overlaps = 20, show.legend = FALSE) +
  scale_colour_manual(values = condition_colors) +
  scale_shape_manual(values = clade_shapes) +
  labs(x = paste0("PC1: ", pct_var[1], "% variance"),
       y = paste0("PC2: ", pct_var[2], "% variance"),
       title = "PCA — VST-normalized counts",
       colour = "Condition", shape = "Clade") +
  theme_bw(base_size = 12)

ggsave(file.path(OUTDIR, "PCA_VST.pdf"), p_pca, width = 8, height = 6)
ggsave(file.path(OUTDIR, "PCA_VST.png"), p_pca, width = 8, height = 6, dpi = 150)

# ── PCoA (Euclidean on VST = equivalent to PCA, Bray-Curtis on counts) ────────
message("Plotting PCoA (Bray-Curtis)...")
# Use Bray-Curtis on count-per-million for ecological distance
bc_dist <- vegdist(t(cpm_mat[rownames(vst_mat), ]), method = "bray")
pcoa    <- cmdscale(bc_dist, k = 2, eig = TRUE)

pcoa_df <- data.frame(
  Axis1 = pcoa$points[, 1],
  Axis2 = pcoa$points[, 2],
  cSample_names = rownames(pcoa$points)
) %>%
  left_join(meta %>% tibble::rownames_to_column("cSample_names"), by = "cSample_names")

eig_pct <- round(100 * pcoa$eig[1:2] / sum(pcoa$eig[pcoa$eig > 0]), 1)

p_pcoa <- ggplot(pcoa_df, aes(Axis1, Axis2,
                               colour = condition,
                               shape  = clade,
                               label  = strainName)) +
  geom_point(size = 3, alpha = 0.85) +
  geom_text_repel(size = 2.5, max.overlaps = 20, show.legend = FALSE) +
  scale_colour_manual(values = condition_colors) +
  scale_shape_manual(values = clade_shapes) +
  labs(x = paste0("PCoA1: ", eig_pct[1], "%"),
       y = paste0("PCoA2: ", eig_pct[2], "%"),
       title = "PCoA — Bray-Curtis (CPM)",
       colour = "Condition", shape = "Clade") +
  theme_bw(base_size = 12)

ggsave(file.path(OUTDIR, "PCoA_BrayCurtis.pdf"), p_pcoa, width = 8, height = 6)
ggsave(file.path(OUTDIR, "PCoA_BrayCurtis.png"), p_pcoa, width = 8, height = 6, dpi = 150)

# ── NMDS ──────────────────────────────────────────────────────────────────────
message("Running NMDS (Bray-Curtis)...")
set.seed(42)
nmds <- metaMDS(t(cpm_mat[rownames(vst_mat), ]), distance = "bray",
                k = 2, trymax = 100, trace = FALSE)
message(sprintf("NMDS stress: %.4f", nmds$stress))

nmds_df <- data.frame(
  NMDS1 = nmds$points[, 1],
  NMDS2 = nmds$points[, 2],
  cSample_names = rownames(nmds$points)
) %>%
  left_join(meta %>% tibble::rownames_to_column("cSample_names"), by = "cSample_names")

p_nmds <- ggplot(nmds_df, aes(NMDS1, NMDS2,
                               colour = condition,
                               shape  = clade,
                               label  = strainName)) +
  geom_point(size = 3, alpha = 0.85) +
  geom_text_repel(size = 2.5, max.overlaps = 20, show.legend = FALSE) +
  scale_colour_manual(values = condition_colors) +
  scale_shape_manual(values = clade_shapes) +
  annotate("text", x = Inf, y = -Inf, hjust = 1.1, vjust = -0.5,
           label = sprintf("Stress = %.3f", nmds$stress), size = 3.5) +
  labs(title = "NMDS — Bray-Curtis (CPM)",
       colour = "Condition", shape = "Clade") +
  theme_bw(base_size = 12)

ggsave(file.path(OUTDIR, "NMDS_BrayCurtis.pdf"), p_nmds, width = 8, height = 6)
ggsave(file.path(OUTDIR, "NMDS_BrayCurtis.png"), p_nmds, width = 8, height = 6, dpi = 150)

# ── DESeq2 DE analysis ────────────────────────────────────────────────────────
message("Running DESeq2...")
dds <- DESeq(dds)

# Overall hypoxia vs normoxia (across all strains/clades)
res_hyp_vs_norm <- results(dds,
                            contrast  = c("condition", "hypoxia", "normoxia"),
                            alpha     = 0.05)
res_df <- as.data.frame(res_hyp_vs_norm) %>%
  tibble::rownames_to_column("SOG_ID") %>%
  arrange(padj)

write_csv(res_df, file.path(OUTDIR, "DE_hypoxia_vs_normoxia.csv"))

sig_up   <- sum(res_df$padj < 0.05 & res_df$log2FoldChange > 1,  na.rm = TRUE)
sig_down <- sum(res_df$padj < 0.05 & res_df$log2FoldChange < -1, na.rm = TRUE)
message(sprintf("DE genes (padj<0.05, |LFC|>1): %d up, %d down in hypoxia", sig_up, sig_down))

# Volcano plot
p_volc <- res_df %>%
  mutate(
    sig = case_when(
      padj < 0.05 & log2FoldChange >  1 ~ "Up in hypoxia",
      padj < 0.05 & log2FoldChange < -1 ~ "Down in hypoxia",
      TRUE ~ "NS"
    )
  ) %>%
  ggplot(aes(log2FoldChange, -log10(pvalue), colour = sig)) +
  geom_point(alpha = 0.4, size = 0.8) +
  scale_colour_manual(values = c(
    "Up in hypoxia"   = "#D6604D",
    "Down in hypoxia" = "#4393C3",
    "NS"              = "grey60"
  )) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", colour = "grey30") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", colour = "grey30") +
  labs(title = "Hypoxia vs Normoxia",
       x = "log2 Fold Change", y = "-log10(p-value)",
       colour = NULL) +
  theme_bw(base_size = 12)

ggsave(file.path(OUTDIR, "Volcano_hypoxia_vs_normoxia.pdf"), p_volc, width = 7, height = 5)
ggsave(file.path(OUTDIR, "Volcano_hypoxia_vs_normoxia.png"), p_volc, width = 7, height = 5, dpi = 150)

message("Done. Results written to: ", OUTDIR)
