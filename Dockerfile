# Start with BioSim base image.
ARG BASE_IMAGE=latest
FROM ghcr.io/jimboid/biosim-jupyterhub-base:$BASE_IMAGE

LABEL maintainer="James Gebbie-Rayet <james.gebbie@stfc.ac.uk>"
LABEL org.opencontainers.image.source=https://github.com/jimboid/biosim-nemd-workshop
LABEL org.opencontainers.image.description="A container environment for the ccpbiosim workshop on non-equilibrium MD."
LABEL org.opencontainers.image.licenses=MIT

ARG GMX_VERSION=2025.0
ARG TARGETPLATFORM

# Root to install "rooty" things.
USER root

WORKDIR /tmp
# Grab a specified version of gromacs
RUN wget ftp://ftp.gromacs.org/gromacs/gromacs-$GMX_VERSION.tar.gz && \
    tar xvf gromacs-$GMX_VERSION.tar.gz && \
    rm gromacs-$GMX_VERSION.tar.gz

# make a build dir
RUN mkdir /tmp/gromacs-$GMX_VERSION/build
WORKDIR /tmp/gromacs-$GMX_VERSION/build

# build gromacs
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gromacs-$GMX_VERSION -DGMX_BUILD_OWN_FFTW=ON -DGMX_OPENMP=ON -DGMXAPI=OFF -DCMAKE_BUILD_TYPE=Release; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gromacs-$GMX_VERSION -GMX_SIMD=ARM_SVE -DGMX_SIMD_ARM_SVE_LENGTH=128 -DGMX_BUILD_OWN_FFTW=ON -DGMX_OPENMP=OFF -DGMXAPI=OFF -DCMAKE_BUILD_TYPE=Release; \
    fi

RUN make -j8
RUN make install
RUN rm -r /tmp/gromacs-$GMX_VERSION && \
    chown -R 1000:100 /opt/gromacs-$GMX_VERSION

ENV PATH=/opt/gromacs-$GMX_VERSION/bin:$PATH

# Switch to jovyan user.
USER $NB_USER
WORKDIR $HOME

RUN conda install ipywidgets nglview -y
RUN pip install mdtraj

# Copy lab workspace
COPY --chown=1000:100 default-37a8.jupyterlab-workspace /home/jovyan/.jupyter/lab/workspaces/default-37a8.jupyterlab-workspace

RUN wget https://www.hecbiosim.ac.uk/workshop_files/D-NEMD_tutorial.tar.xz
RUN tar xvf D-NEMD_tutorial.tar.xz && \
    rm D-NEMD_tutorial.tar.xz

# UNCOMMENT THIS LINE FOR REMOTE DEPLOYMENT
COPY jupyter_notebook_config.py /etc/jupyter/

# Always finish with non-root user as a precaution.
USER $NB_USER
