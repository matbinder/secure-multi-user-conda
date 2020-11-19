# For testing only
Test this environment on: [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jan-janssen/secure-multi-user-conda/master)

The focus of this setup is to demonstrate how to configure a conda environment for high performance computing on a multi-user system. This means we install one conda environment which is used from multiple users and which is updated regularly. 

## Fix conda-forge as default 
To prevent conda from switching from anaconda to conda-forge, add the following line in `.condarc`. 
```
channel_priority: strict
channels:
  - conda-forge
  - defaults
ssl_verify: true
```
Rather than having a `~/.condarc` in the users home directory it is recommended to place it in the root of the conda environment `${CONDA_PREFIX}/.condarc`

## Fix MKL 
To prevent conda from switching from MKL to openblas, add the following line in `${CONDA_PREFIX}/conda-meta/pinned`: 
```
libblas[build=*mkl]
```

## Compile all python modules
As the conda directory is set to read and execute only, all python files are compiled using:
```
find ${CONDA_DIR} -name "*.py" ! -path "${CONDA_DIR}pkgs/*" -exec ${CONDA_DIR}bin/python -m py_compile {} +
```
Or alternatively with `${CONDA_PREFIX}` rather than `${CONDA_DIR}`: 
```
find ${CONDA_PREFIX} -name "*.py" ! -path "${CONDA_PREFIX}pkgs/*" -exec ${CONDA_PREFIX}bin/python -m py_compile {} +
```

## Jupyterlab 
Some packages like `nglview` are distributed as two parts a conda package and a jupyterlab extension. It is therefore important to keep both versions synchronized. To check the status of the jupyter lab plugins use: 
```
jupyter labextension list 
```
When a jupyterlab extension was updated then it might be necessary to rebuild jupyterlab. You should see a corresponding warning message when you call the command above. To rebuild jupyterlab use: 
```
jupyter lab build
```

## Clean up 
When regularly updating the environment it makes sense to clean up afterwards. Conda offers a built-in clean up utility: 
```
conda clean --all
```
In addition jupyterlab requires a clean up to remove the intermediate parts of the build process: 
```
npm cache clean --force
jlpm cache clean
jupyter lab clean
```
