# Start with BioSim base image.
ARG BASE_IMAGE=latest
FROM harbor.stfc.ac.uk/biosimulation-cloud/biosim-jupyter-base:$BASE_IMAGE

LABEL maintainer="James Gebbie-Rayet <james.gebbie@stfc.ac.uk>"

# Root to install "rooty" things.
USER root

WORKDIR /opt
RUN wget ftp://ftp.gromacs.org/gromacs/gromacs-2022.4.tar.gz
RUN tar xvf gromacs-2022.4.tar.gz && \
    rm gromacs-2022.4.tar.gz
WORKDIR /opt/gromacs-2022.4
RUN mkdir build
WORKDIR /opt/gromacs-2022.4/build
RUN cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gromacs-2022.4 -DGMX_BUILD_OWN_FFTW=ON -DGMX_OPENMP=ON -DGMXAPI=OFF -DCMAKE_BUILD_TYPE=Release
RUN make -j8
RUN make install

# Switch to jovyan user.
USER $NB_USER
WORKDIR $HOME

RUN conda install ipywidgets nglview mdtraj -y

ENV PATH=/opt/gromacs-2022.4/bin:$PATH

# Copy lab workspace
COPY --chown=1000:100 default-37a8.jupyterlab-workspace /home/jovyan/.jupyter/lab/workspaces/default-37a8.jupyterlab-workspace

COPY --chown=1000:100 D-NEMD_tutorial.tar.xz /home/jovyan/
RUN tar xvf D-NEMD_tutorial.tar.xz
RUN rm D-NEMD_tutorial.tar.xz

# UNCOMMENT THIS LINE FOR REMOTE DEPLOYMENT
COPY jupyter_notebook_config.py /etc/jupyter/

# Always finish with non-root user as a precaution.
USER $NB_USER
