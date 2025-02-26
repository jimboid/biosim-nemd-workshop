# Start with BioSim base image.
ARG BASE_IMAGE=latest
FROM ghcr.io/jimboid/biosim-jupyterhub-base:$BASE_IMAGE

LABEL maintainer="James Gebbie-Rayet <james.gebbie@stfc.ac.uk>"
LABEL org.opencontainers.image.source=https://github.com/jimboid/biosim-nemd-workshop
LABEL org.opencontainers.image.description="A container environment for the ccpbiosim workshop on non-equilibrium MD."
LABEL org.opencontainers.image.licenses=MIT

ARG TARGETPLATFORM

# Switch to jovyan user.
USER $NB_USER
WORKDIR $HOME

# Dependencies for the workshop
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      conda install conda-forge/linux-64::gromacs=2024.5=nompi_h5f56185_100 -y; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      conda install conda-forge/osx-arm64::gromacs=2024.5=nompi_he3c68ee_100 -y; \
    fi
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
