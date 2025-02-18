# README

## Overview
This script is a Bash automation workflow for processing and analyzing biological datasets using various computational tools, including Python and R. In particular, this workflow focuses on using different biological networks, processing them through embedding, and using this information to prioritize causal genes related to a given disease.

## Prerequisites
Ensure the following dependencies are installed before running the script:

- Bash shell (Linux/macOS)
- Python (by deafaul, initialized via `init_python`)
- R (by default, initialized via `init_R`)
- AutoFlow
- Required scripts and daemons located in `~soft_bio_267/` as default. You can use them cloning the repository of [biosys scripts](https://github.com/seoanezonjic/sys_bio_lab_scripts.git) and adjusting de path from daemon.sh, named as `sys_bio_lab_scripts_path`.

## Usage
Run daemon.sh with the desired execution mode:

```sh
./daemon.sh <exec_mode> [additional_options]
```

### Execution Modes
- `download_layers`: Downloads the necessary dataset layers.
- `download_translators`: Fetches and processes translator tables.
- `process_download`: Processes downloaded datasets.
- `dversion <version>`: Selects the data version to use.
- `whitelist`: Filters genes based on a whitelist.
- `process_control`: Prepares control datasets.
- `get_control <benchmark>`: Retrieves control genes for benchmarking (`zampieri` or `menche`).
- `kernels`: Computes similarity kernels.
- `plot_sims`: Generates similarity plots.
- `ranking <benchmark>`: Computes non-integrated rankings.
- `integrate`: Integrates kernels or embeddings.
- `integrated_ranking <benchmark>`: Computes rankings from integrated kernels or embeddings.
- `report <save_option>`: Generates HTML reports. It is worth to mention that, in order to respect author order, menche banchmark is named as buphamalai benchmark in the resulting reports.
- `check <folder>`: Checks AutoFlow execution logs.
- `recover <folder>`: Recovers execution logs.

## Outputs
The script generates several output folders:
- `output_folder/similarity_kernels/` - Stores computed similarity kernels.
- `output_folder/rankings/` - Contains computed rankings.
- `output_folder/integrations/` - Stores kernel integrations.
- `output_folder/integrated_rankings/` - Contains integrated rankings.
- `report_folder/` - Stores generated reports.

## Example
```sh
./daemon.sh kernels
./daemon.sh ranking menche
./daemon.sh report save
```

## Notes
- The script makes use of `AutoFlow` for various processing steps.
- Data sources include STRING, OMIM, DepMap, and other biological databases.
- Ensure network connectivity when downloading data.

## License
This script is intended for research and educational purposes.

