
## CrocoLake-Julia

CrocoLake-Julia is a collection of Jupyter notebooks that shows how to interface with [CrocoLake](https://crocolakedocs.readthedocs.io/en/latest/) and Argo's parquet databases with Ju;oa.

### Table of Contents
1. [Usage](#usage)
1. [Examples](#examples)
1. [Databases](#databases)
1. [Pre-Requisites](#pre-requisites)
1. [Contact](#contact)

### Usage

To install the necessary packages, run these commands:

``` sh
git clone https://github.com/boom-lab/crocolake-julia
cd crocolake-julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

- You can then launch the notebook via `jupyter notebook example.ipynb` (or via `jupyter lab`). 
- Click on ⏩ to run all cells at once. The notebook will download small sample datasets to run the examples.

### Examples

1. [Example 1](example.ipynb) shows how to read, subset, and visaulize data from the Parquet folder.

### Databases

The following databases are currently available:

* CrocoLake: contains the best available data from Argo, GLODAP, and Spray Gliders. [More details here](https://crocolakedocs.readthedocs.io/en/latest/crocolake.html). [This example uses CrocoLake](notebooks/Example_2_CrocoLakePHY_Map_Temperature.ipynb).
* Argo 'QC': contains the best available data, that is real time values are reported only when delayed values are not available. This version is the same used in CrocoLake, and [here](https://crocolakedocs.readthedocs.io/en/latest/available_datasets.html#argo) you can find more details on how it is generated. [This example uses Argo 'QC'](notebooks/Example_3_ArgoPHY_QC_Temperature-Salinity_Profiles.ipynb).
* Argo 'ALL': contains all real time and adjusted variables as reported in the core ('<PLATFORM_NUMBER>_prof.nc') and synthetic ('<PLATFORM_NUMBER>_Sprof.nc') profile files, for the physical and biogeochemical versions respectively. [Both this](notebooks/Example_1_ArgoBGC_Map_Oxygen.ipynb) and [this examples](notebooks/Example_4_Animation_Oxygen.ipynb) use Argo 'ALL'.

Each database comes in 'PHY' and 'BGC' versions.

### Pre-Requisites

- install Julia
- install Jupyter
- Install Jupyter kernel for Julia

### Contact

For any questions, bugs, missing information, etc, open an issue or [get in touch](enrico.milanese@whoi.edu)!

