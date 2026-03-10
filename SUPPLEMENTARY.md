# Yeast protein-protein interactions
## Supplementary Tables
| GPU model         | RAM  | Runtime <br>10 recycles | Runtime<br>3 recycles | Container | Comments |
|-------------------|------|------------|-----------|--------------|----------|
| RTX PRO 6000 96GB | 16GB |     | 20m | b78e215 |          |
| A100 80GB         | 16GB |  1h | 30m | v3.0.1  |          |
| A100 40GB         | 84GB |     |  4h | v3.0.1  | Unif. mem & adjust shard spec |
| RTX 4090 24GB     | 84GB | 24h | 12h | v3.0.1  | Unif. mem & adjust shard spec |

*Supplementary Table. Resources used to run inference for a single pool. For lower-end GPUs, we enabled unified memory & adjusted shard spec [as specified in the AlphaFold3 documentation](https://github.com/google-deepmind/alphafold3/blob/main/docs/performance.md#nvidia-a100-40-gb). All containers are [available on Docker Hub](https://hub.docker.com/r/jurgjn/alphafold3).*
