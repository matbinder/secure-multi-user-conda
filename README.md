# For testing only
Test this environment on: [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jan-janssen/secure-multi-user-conda/master)

The focus of this setup is to demonstrate how to configure a conda environment for high performance computing on a multi-user system. This means one conda environment is installed which is used from multiple users and can be updated regularly by the administrative user. The challange in this approach is that we do not want to allow non-administrative users to modify the environment and at the same time as python is a just-in-time compiled language users typically need write access to execute python code. Therefore the official anaconda documentation recommends to give all users in the same group read, write and execute access: 
https://docs.anaconda.com/anaconda/install/multi-user/#multi-user-anaconda-installation-on-linux
But in this case users might be able to install new packages via pip or directly via conda or modify the python code of existing packages. Both is not recommended for a high performance computing environment which is focused on stability. Instead this tutorial proposes to provide the users with only read and execute access and only the administrative user with write access. 

# Installation 
Just follow the single user setup and install conda in an directory which is accessible for all users, as explained in: 
https://docs.anaconda.com/anaconda/install/multi-user/#multi-user-anaconda-installation-on-linux

In the example above conda is installed to:
```
/opt/anaconda3
```

After the successful setup copy the conda activate commands to each users shell profile. For an installation in `/opt/anaconda3` the activate commands might look like this: 
```
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
```
After the initialization of the user account (logout and login again) each user should be able to access the conda environment. To confirm this check the location of the following executables: 
```
which conda
which python
```
Both should point to the newly installed conda environment. In addition the environment variable `${CONDA_PREFIX}` should be set for all users. 

# Configuration
Restrict the permissions of users in the group to read and execute access while limiting the write access to the atministrative account who is executing these commands:
```
chmod -R 750 ${CONDA_PREFIX}
```

## Fix conda-forge as default 
Before modifying the environment it is recommended to add the conda-forge community channel and update all packages: 
```
conda config --add channels conda-forge 
conda update --all
```
To prevent conda from switching from anaconda to conda-forge, add the following line in `.condarc`. 
```
channel_priority: strict
channels:
  - conda-forge
  - defaults
ssl_verify: true
```
Rather than having a `~/.condarc` in the users home directory it is recommended to place it in the root of the conda environment `${CONDA_PREFIX}/.condarc`. If conda already created a `~/.condarc` in the users home directory, this should be removed to confirm that only the configuration in the root of the conda envrionment `${CONDA_PREFIX}/.condarc` is used. After this step it is important to update conda again to superseed packages from the default conda channel with the ones from the conda-forge community channel, in case they were not updated previously:
```
conda update --all
```
You can confirm that the majority of the packages are now installed from conda-forge using: 
```
conda list
```

## Fix MKL 
To prevent conda from switching from MKL to openblas, add the following line in `${CONDA_PREFIX}/conda-meta/pinned`: 
```
libblas[build=*mkl]
```
Again after this step it is recommended to update the environment: 
```
conda update --all
```
In case you prefer openblas you can fix openblas the same way. As a general rule of thumb mkl typically provides better performance for Linux systems running on intel hardware. 

## Compile all python modules
As the conda directory is set to read and execute only, all python files are compiled using:
```
find ${CONDA_PREFIX} -name "*.py" ! -path "${CONDA_PREFIX}pkgs/*" -exec ${CONDA_PREFIX}bin/python -m py_compile {} +
```
This step is essential for the non-administrative users to have access to the conda environment and it has to be executed after every update. 

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
