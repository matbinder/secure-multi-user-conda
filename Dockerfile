FROM alpine:3.8
MAINTAINER Jan Janssen <janssen@mpie.de>

# Inspired by :
# * https://github.com/jupyter/docker-stacks
# * https://github.com/CognitiveScale/alpine-miniconda
# * https://github.com/show0k/alpine-jupyter-docker
# * https://github.com/datarevenue-berlin/alpine-miniconda

# Install glibc and useful packages
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk --update add \
    bash \
    curl \
    ca-certificates \
    libstdc++ \
    glib \
    git \
    tini@testing \
    && curl "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" -o glibc.apk \
    && apk add glibc.apk \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-bin-2.23-r3.apk" -o glibc-bin.apk \
    && apk add glibc-bin.apk \
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk" -o glibc-i18n.apk \
    && apk add --allow-untrusted glibc-i18n.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc/usr/lib \
    && rm -rf glibc*apk /var/cache/apk/*

# Configure environment
ENV CONDA_DIR=/srv/conda/envs/notebook/\
    PATH=/srv/conda/envs/notebook/bin:${PATH}\
    SHELL=/bin/bash\
    PYIRON_USER=pyiron\
    PYIRON_UID=1000\
    LC_ALL=en_US.UTF-8\
    LANG=en_US.UTF-8\
    LANGUAGE=en_US.UTF-8\
    HOME=/home/pyiron\
    OMPI_MCA_plm=isolated\
    OMPI_MCA_rmaps_base_oversubscribe=yes\
    OMPI_MCA_btl_vader_single_copy_mechanism=none\
    MINICONDA_VER=4.8.3\
    MINICONDA_MD5_SUM=d63adf39f2c220950a063e0529d4ff74\
    MINICONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-py38_4.8.3-Linux-x86_64.sh

COPY . ${HOME}

# Install 
RUN cd /tmp \
    && mkdir -p ${CONDA_DIR} \
    && curl -L ${MINICONDA_URL}  -o miniconda.sh \
    && echo "${MINICONDA_MD5_SUM}  miniconda.sh" | md5sum -c - \
    && ${SHELL} miniconda.sh -f -b -p ${CONDA_DIR} \
    && chmod -R 755 ${CONDA_DIR} \
    && rm miniconda.sh \
    && ${CONDA_DIR}/bin/conda install --yes conda==${MINICONDA_VER} \
    && source ${CONDA_DIR}/bin/activate \
    && conda install -y -c conda-forge libblas=*=*mkl \
    && printf "channel_priority: strict\nchannels:\n  - conda-forge\n  - defaults\nssl_verify: true" > ${CONDA_DIR}.condarc \
    && printf "libblas[build=*mkl]" > ${CONDA_DIR}conda-meta/pinned \
    && conda update --all -y \
    && conda env update -n root -f "${HOME}/environment.yml" \
    && find ${CONDA_DIR} -name "*.py" ! -path "${CONDA_DIR}pkgs/*" -exec ${CONDA_DIR}bin/python -m py_compile {} +; exit 0 \
    && conda clean --all -y \
    && printf "__conda_setup=\"\$(\"${CONDA_DIR}bin/conda\" \"shell.bash\" \"hook\" 2> /dev/null)\"\nif [ $? -eq 0 ]; then\n    eval \"\$__conda_setup\"\nelse\n    if [ -f \"${CONDA_DIR}etc/profile.d/conda.sh\" ]; then\n        . \"${CONDA_DIR}etc/profile.d/conda.sh\"\n    else\n         export PATH=\"${CONDA_DIR}bin:\$PATH\"\n    fi\nfi\nunset __conda_setup\n" > ${HOME}/.profile

# Create user with UID=1000 and in the 'users' group
RUN adduser -s ${SHELL} --disabled-password --gecos "Default user" -u ${PYIRON_UID} -D ${PYIRON_USER} \
    && chown -R ${PYIRON_USER} ${HOME}

# Configure container startup as root
WORKDIR ${HOME}/
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]

# Switch back to pyiron to avoid accidental container runs as root
USER ${PYIRON_USER}
