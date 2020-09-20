# For testing only
Test this environment on: [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jan-janssen/secure-multi-user-conda/master)

# Fix conda-forge as default 
To prevent conda from switching from anaconda to conda-forge, add the following line in `.condarc`:
```
channel_priority: strict
channels:
  - conda-forge
  - defaults
ssl_verify: true
```

# Fix MKL 
To prevent conda from switching from MKL to openblas, add the following line in `conda-meta/pinned`: 
```
libblas[build=*mkl]
```