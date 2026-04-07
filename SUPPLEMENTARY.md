# Yeast protein-protein interactions
## Methods
### Sampling random pools for all-vs-all screening
We aim to sample proteins into pools such that
(1) every interaction is included in at least one pool;
(2) the total number of pools is minimised;
(3) pool sizes are close to the AlphaFold3 recommended input limit of 5,120 tokens.
We achieve this with "locally greedy sampling" as in ([Todor et al, 2026](https://doi.org/10.1038/s44320-026-00189-7))
except that the interactions are weighted by the product of the length of the interacting proteins.
For *Mgen*, this reduces the number of pools needed to cover every interaction [from 2,027 to 1,866](https://github.com/jurgjn/pooled-ppi/blob/main/examples-colab/sample-pools-mgen/sample-pools-mgen-colab.ipynb).

We use
[AFDB v4](https://ftp.ebi.ac.uk/pub/databases/alphafold/v4/UP000002311_559292_YEAST_v4.tar)/[UniProt 2021_04](https://alphafold.ebi.ac.uk/faq)
protein sequences.
We first sampled all-vs-all pools from the entire proteome (n=6,039).
After initial profiling, we focused on an all-vs-all subset of proteins expressed under standard conditions (n=4,270).

### Running AlphaFold3 on large inputs at scale
We ran the AlphaFold3 ([Abramson et al, 2024](https://doi.org/10.1038/s41586-024-07487-w)) data pipeline (MSA and template search) for every monomer sequence using the latest release (v3.0.1). One sequence (Q3E7A6) failed with v3.0.1, and was successfully re-run with b78e215. For inference on pooled input, we "fill in" the data pipeline strings [using custom scripts](https://github.com/jurgjn/af3io).

We are running AlphaFold3 inference on heterogeneous hardware with A100, GH200, RTX4090, and RTX PRO 6000 GPUs.
We use containers of the current release (v3.0.1) except where the [latest/modified code is needed to accommodate newer hardware](https://hub.docker.com/r/jurgjn/alphafold3). We found that reducing the number of recycles from ten (default) to three reduces the runtime by half without a significant effect on re-capitulating STRING interactions.

We minimise storage and network traffic by compressing data pipeline output (gzip), and inference output (zip).

### Web app for exploratory data analysis
We use foldcomp ([Kim et al, 2023](https://doi.org/10.1093/bioinformatics/btad153)) to store predicted structures locally in the container.
The web app is written in streamlit, structures are visualised with stmol ([Nápoles-Duarte et al, 2022](https://doi.org/10.3389/fmolb.2022.990846))
which uses 3Dmol.js ([Rego et al, 2014](https://doi.org/10.1093/bioinformatics/btu829)) as the underlying rendering engine.

## Supplementary Tables
| GPU model         | RAM  | Runtime <br>10 recycles | Runtime<br>3 recycles | Container | Comments |
|-------------------|------|------------|-----------|--------------|----------|
| RTX PRO 6000 96GB | 16GB |     | 20m | b78e215 |          |
| A100 80GB         | 16GB |  1h | 30m | v3.0.1  |          |
| A100 40GB         | 84GB |     |  4h | v3.0.1  | Unif. mem & adjust shard spec |
| RTX 4090 24GB     | 84GB | 24h | 12h | v3.0.1  | Unif. mem & adjust shard spec |

*Supplementary Table. Resources used to run inference for a single pool. For lower-end GPUs, we enabled unified memory & adjusted shard spec [as specified in the AlphaFold3 documentation](https://github.com/google-deepmind/alphafold3/blob/main/docs/performance.md#nvidia-a100-40-gb). All containers are [available on Docker Hub](https://hub.docker.com/r/jurgjn/alphafold3).*

## Supplementary Data
| Name                 | URL / Container file |
|----------------------|----------------------|
| Data pipeline        | https://doi.org/10.5281/zenodo.18925033
| Proteins             | `proteins.parquet`
| Pools                | `pools.parquet`
| Confidence metrics   | `summary_confidences.parquet`
| Interactions         | `summary_pairs.parquet`
| Predicted structures | `predictions-db/`

### Proteins
- `uniprot_id`, `seq`, `seq_len` uniprot identifier, sequence and length from the [yeast v4 proteome](https://ftp.ebi.ac.uk/pub/databases/alphafold/v4/UP000002311_559292_YEAST_v4.tar) of the AlphaFold Protein Structure Database
- `af3_id` contains [AlphaFold3-sanitised uniprot identifiers](https://github.com/google-deepmind/alphafold3/issues/480) to track proteins, e.g. Q3E7A6 becomes q3e7a6
- `is_expressed` whether the protein is considered as expressed under standard conditions for pool sampling
- `uniprot_genes`, `uniprot_locus`, `uniprot_entry` additional protein/gene identifiers from UniProt 2021_04

### Pools
- `pool_id` proteins in the pool (from `af3_id`), sorted and separated by underscores
- `pool_size` total number of residues in the pool
- `source` indicates whether pool was sampled from all yeast v4 proteome sequences (`all`) or from the subset expressed under standard conditions (`std`)
- `pool_hash` is a hash of `pool_id` (with `hashlib.sha1`), used as a unique identifer to track pools as `pool_id` can exceed file name length limits

### Predicted structures
Foldcomp database with the top predicted structures. Foldcomp [does not support multimers](https://github.com/steineggerlab/foldcomp/issues/50); we circumvent this by storing every pool/chain combination separately with `{pool_hash}_{af3_id}` as the primary key/identifier.