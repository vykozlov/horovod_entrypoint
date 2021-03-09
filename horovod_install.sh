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
# in case provided, install MPI library and Horovod framework
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
if [ $# -eq 0 ]; then 
# just print the help message
    shopt -s xpg_echo
    echo $USAGEMESSAGE
elif [ $1 == "-h" ] || [ $1 == "--help" ]; then 
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
else 
    # read options as parameters (1)
    cmd=${arr[0]} # command
    params=${arr[@]:1}
fi

# check if HOROVOD is set
# if so, also set OpenMPI to 4.1.0
if [ ${#HOROVOD} -gt 2 ]; then
   # check if OpenMPI is also set, if not => default version
   if [ ${#OpenMPI} -lt 2 ]; then
       OpenMPI=${OpenMPI_DEFAULT}
   fi
fi

if [ ${#OpenMPI} -gt 2 ]; then
    # deduce the main OpenMPI version
    OpenMPI_MainVer=$(echo ${OpenMPI} | cut -d\. -f1,2)
    mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget "https://www.open-mpi.org/software/ompi/v${OpenMPI_MainVer}/downloads/openmpi-${OpenMPI}.tar.gz" && \
    tar zxf openmpi-${OpenMPI}.tar.gz && \
    cd openmpi-${OpenMPI} && \
    ./configure --enable-orterun-prefix-by-default && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi    
fi

if [ ${#HOROVOD} -gt 2 ]; then
    if [ ${HOROVOD}=="latest" ]; then
        HOROVOD_PYPI="horovod"
    else
        HOROVOD_PYPI="horovod==${HOROVOD}"
    fi
    # Install Horovod, temporarily using CUDA stubs (Ubuntu path!)
    ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs && \
    HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_WITH_TENSORFLOW=1 pip3 install --no-cache-dir ${HOROVOD_PYPI} && \
    ldconfig
fi

# command to execute at the end
${cmd} ${params[@]}