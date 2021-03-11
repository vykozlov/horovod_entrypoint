#!/usr/bin/env bash
#
# -*- coding: utf-8 -*-
#
# Copyright (c) 2018 - 2020 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# @author: vykozlov
#

###  INFO  ###
# Script to check MPI and HOROVOD environment settings and
# if provided, install MPI and Horovod libraries
#
# It is required that:
# cmake
# git
# wget
# libnccl2 and libnccl-dev
# are installed.
# cuda, python3, pip3 are supposed to be installed as well.
###

##### USAGEMESSAGE #####
USAGEMESSAGE="Usage: $0 <options>\n
where <options> are:\n
 \t --help, -h    \t help message (this message) \n
 \t <any command> \t any command to execute at the end of the script \n
The script checks for the following environment settings:\n
 \t OpenMPI=version (e.g. 4.0.1)\n
 \t HOROVOD=version (e.g. 0.21.3 or latest)\n
If set, the script attempts to install corresponding libraries.\n
Once installed, runs <any command>"

# default OpenMPI version, if only HOROVOD requested
OpenMPI_DEFAULT=4.1.0

##### PARSE SCRIPT FLAGS #####
arr=("$@")
if [[ $# -eq 0 ]]; then 
# just print the help message
    shopt -s xpg_echo
    echo $USAGEMESSAGE
elif [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then 
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
else 
    # read options as parameters (1)
    params="$*"
fi

# Store path from where the script called
# This script's full path
# https://unix.stackexchange.com/questions/17499/get-path-of-current-script-when-executed-through-a-symlink/17500
SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"

# check if HOROVOD is set
# if so, also set OpenMPI to 4.1.0
if [ ${#HOROVOD} -gt 2 ]; then
   # check if OpenMPI is also set, if not => default version
   if [ ${#OpenMPI} -lt 2 ]; then
       OpenMPI=${OpenMPI_DEFAULT}
   fi
fi

if [ ${#OpenMPI} -gt 2 ]; then
    # check if OpenMPI is already installed
    OpenMPI_Install=true
    if command mpirun --version 2>/dev/null; then
        OpenMPI_InstalledVer=$(mpirun --version | head -1 | cut -d' ' -f4)
        # check that requested and installed versions match
        # if so, no action to install again.
        if [ ${OpenMPI}=="${OpenMPI_InstalledVer}" ]; then
            OpenMPI_Install=false
        fi
    fi
    # install OpenMPI, if not installed or versions do not match
    if $OpenMPI_Install; then
        # deduce the main OpenMPI version
        OpenMPI_MainVer=$(echo ${OpenMPI} | cut -d\. -f1,2)
        mkdir /tmp/openmpi && cd /tmp/openmpi && \
        wget "https://www.open-mpi.org/software/ompi/v${OpenMPI_MainVer}/downloads/openmpi-${OpenMPI}.tar.gz"
        tar zxf openmpi-${OpenMPI}.tar.gz
        cd openmpi-${OpenMPI}
        ./configure --enable-orterun-prefix-by-default
        [[ $? -eq 0 ]] && make -j $(nproc) all
        [[ $? -eq 0 ]] && make install
        [[ $? -eq 0 ]] && ldconfig
        [[ $? -eq 0 ]] && rm -rf /tmp/openmpi

        if [ $? -eq 0 ]; then
            echo "[DEBUG] Finish OpenMPI installation"
        else
            echo "[ERROR] Something went wrong. Please, check error messages above."
        fi
    fi
fi

# go back to the script folder
cd ${SCRIPT_PATH}

# install HOROVOD if asked for
if [ ${#HOROVOD} -gt 2 ]; then
    if [ ${HOROVOD}=="latest" ]; then
        HOROVOD_PYPI="horovod"
    else
        HOROVOD_PYPI="horovod==${HOROVOD}"
    fi
    # Install Horovod, temporarily using CUDA stubs (Ubuntu path!)
    # pip3 also checks, if horovod is already installed
    ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs && \
    HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_WITH_TENSORFLOW=1 \
    python3 -m pip install --no-cache-dir ${HOROVOD_PYPI} && \
    ldconfig
fi

# go back to the script folder
cd ${SCRIPT_PATH}

# command to execute at the end
if [ $? -eq 0 ]; then
/bin/bash<<EOF
${params}
EOF
else
    echo "[ERROR] Something went wrong. Please, check error messages above."
fi

# might be better to:
#if [[ $# -eq 0 ]]; then
#  exec "/bin/bash"
#else
#  exec "$@"
#fi

