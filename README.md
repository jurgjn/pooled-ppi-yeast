# Yeast protein-protein interactions
*We recently used pooled co-folding to map protein-protein interactions in Mgen, a small bacterium ([Todor et al, 2026](https://doi.org/10.1038/s44320-026-00189-7)).
Here we present a work-in-progress scaleup of pooled co-folding in yeast. 
We discuss technical optimisations to run pooled co-folding at scale,
and an initial comparison to experimental evidence.
Our work-in-progress predictions are publicly available.*

## Results
### Pooled co-folding recapitulates known interactions
<p align="center">
<img src="figures/recap_by_string_score.svg" />
</p>

To ask whether we are recapitulating known interactors, we compared the subset of finished predictions (81,912 from 283,146 pools) to evidence of physical interaction from STRING. We binned the STRING physical interaction score to create groups of physical interactors with increasing levels of confidence. We then tested the ability of our pooled AlphaFold3 predictions to differentiate between interactions assigned to a STRING confidence bin, and interactions without any evidence in STRING.

Size-corrected AlphaFold3 confidence scores are better at re-capitulating higher-confidence STRING interactions (Figure). The AUC ranges from 0.6 for the lowest-confidence to 0.84 for the highest-confidence bins.

### A resource of predicted protein-protein interactions in yeast
To browse finished predictions, we created a self-contained web app available from [Docker Hub](https://hub.docker.com/r/jurgjn/pooled-ppi-yeast):
```
docker run -p 8501:8501 jurgjn/pooled-ppi-yeast
```
The web app works offline, and contains top-scoring predicted structures for approximately four million heterodimers,
a quarter of all possible pairwise protein-protein interactions in yeast.

**These predicted AlphaFold3 models of protein complexes are shared as a community resource to accelerate structural biology research.
We encourage the use of this data for targeted studies, provided appropriate credit is given.
We kindly ask that researchers refrain from publishing proteome-wide or large-scale data mining studies until our formal publication is released.
However, we welcome inquiries regarding collaborative efforts and are open to joint analysis projects that leverage this resource for broader biological insights.**

**All structures generated with AlphaFold3, subject to [Output Terms of Use](OUTPUT_TERMS_OF_USE.md).**

## Methods
### Sampling random pools for all-vs-all screening
We aim to sample proteins into pools such that
(1) every interaction is included in at least one pool;
(2) the total number of pools is minimised;
(3) pool sizes are close to the AlphaFold3 recommended input limit of 5,120 tokens.
We achieve this with "locally greedy sampling" as in ([Todor et al, 2026](https://doi.org/10.1038/s44320-026-00189-7))
except that the interactions are weighted by the product of the length of the interacting proteins.
For *Mgen*, this reduces the number of pools needed to cover every interaction [from 2,027 to 1,866](https://github.com/jurgjn/pooled-ppi/blob/main/examples/sample-pools-mgen/sample-pools-mgen-colab.ipynb).

### Running AlphaFold3 on large inputs at scale
We are running AlphaFold3 ([Abramson et al, 2024](https://doi.org/10.1038/s41586-024-07487-w)) on heterogeneous hardware with A100, GH200, RTX4090, and RTX PRO 6000 GPUs.
We use containers of the current release (v3.0.1) except where the [latest/modified code is needed to accommodate newer hardware](https://hub.docker.com/r/jurgjn/alphafold3).

We run the AlphaFold3 data pipeline (MSA and template searches) once for every monomer sequence.
For inference on pooled input, we "fill in" the data pipeline strings [using custom scripts](https://github.com/jurgjn/af3io).
We minimise storage and network traffic by compressing data pipeline output (gzip), and inference output (zip).

We found that reducing the number of recycles from ten (default) to three reduces the runtime by half without a significant effect on re-capitulating STRING interactions.

### Web app for exploratory data analysis
We use foldcomp ([Kim et al, 2023](https://doi.org/10.1093/bioinformatics/btad153)) to store predicted structures locally in the container.
The web app is written in streamlit, structures are visualised with stmol ([Nápoles-Duarte et al, 2022](https://doi.org/10.3389/fmolb.2022.990846))
which uses 3Dmol.js ([Rego et al, 2014](https://doi.org/10.1093/bioinformatics/btu829)) as the underlying rendering engine.
