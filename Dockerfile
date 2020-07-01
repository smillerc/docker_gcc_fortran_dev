FROM fedora:31

RUN dnf install -y \
      make kernel-devel kernel-headers valgrind gdb \
      libtool file gfortran g++ gcc m4 \
      openmpi-devel openmpi cmake wget curl git \
      hdf5-devel zlib vim ack tmux tar libtsan libasan patch

RUN dnf install -y python\
      python3-numpy python3-matplotlib python3-h5py python3-pip python3-scipy

RUN pip install pint xarray fortran-language-server

ENV PATH="/usr/lib64/openmpi/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/lib64:/usr/lib64/openmpi/lib:${LD_LIBRARY_PATH}"

RUN rm -rf /tmp/* && cd /tmp && git clone https://github.com/Goddard-Fortran-Ecosystem/pFUnit.git && \
      cd pFUnit && \
      git checkout tags/v4.1.7 -b latest && \
      mkdir build && cd build && \
      FC=mpif90 CC=gcc cmake .. \
      -DSKIP_FHAMCREST=YES \
      -DSKIP_ROBUST=YES \
      -DCMAKE_INSTALL_PREFIX=/software/ && \
      make -j && make install ; exit 0 && rm -rf /tmp/*

ENV PFUNIT_DIR /software/PFUNIT-4.1
ENV FARGPARSE_DIR /software/FARGPARSE-0.9
ENV GFTL_DIR /software/GFTL-1.2
ENV GFTL_SHARED_DIR /software/GFTL_SHARED-1.0

# Add a default non-root user to run mpi jobs
ARG USER=user
ENV USER ${USER}
RUN adduser ${USER} \
      && echo "${USER}   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV USER_HOME /home/${USER}
RUN chown -R ${USER}:${USER} ${USER_HOME}
RUN chown -R ${USER}:${USER} /software

# Create working directory
ARG WORKDIR=/workspace
ENV WORKDIR ${WORKDIR}
RUN mkdir ${WORKDIR}
RUN chown -R ${USER}:${USER} ${WORKDIR}

WORKDIR ${WORKDIR}
USER ${USER}

# install spack
ENV SPACK_ROOT=/software/spack
RUN mkdir $SPACK_ROOT && curl -s -L https://api.github.com/repos/llnl/spack/tarball \
      | tar xzC $SPACK_ROOT --strip 1
RUN echo ". $SPACK_ROOT/share/spack/setup-env.sh" \
      >> ${USER_HOME}/.bashrc

ENV PATH="$SPACK_ROOT/bin:${PATH}"
RUN mkdir -p ${USER_HOME}/.spack
COPY packages.yaml ${USER_HOME}/.spack/packages.yaml

# CGNS
RUN spack spec cgns@3.4.0~mpi+fortran^hdf5+hl+fortran~mpi
RUN spack install cgns@3.4.0~mpi+fortran^hdf5+hl+fortran~mpi

# NetCDF Fortran
RUN spack spec netcdf-fortran~mpi^hdf5+hl+fortran~mpi
RUN spack install netcdf-fortran~mpi^hdf5+hl+fortran~mpi

# Set the prompt look
RUN echo "parse_git_branch() {" >> ${USER_HOME}/.bashrc
RUN echo "  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'" >> ${USER_HOME}/.bashrc
RUN echo "}" >> ${USER_HOME}/.bashrc
RUN echo 'export PS1="\n\[$(tput sgr0)\]\[\033[38;5;75m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\]: [\w] \$(parse_git_branch) \n\[$(tput sgr0)\]\[\033[38;5;10m\]\\$>\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"' >> ${USER_HOME}/.bashrc

CMD ["/bin/bash"]