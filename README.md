horovod_entrypoint
==================

## Description
wrapper to install horovod and OpenMPI in a docker container. Used as ENTRYPOINT in the Dockerfile.

If one of the following environment setting is provided:

*  OpenMPI=version (e.g. 4.0.0) : install OpenMPI of version 4.0.0

*  HOROVOD=version (e.g. 0.23.1 or "latest") : install horovod libraries


If `HOROVOD` env is provided but not `OpenMPI`, the default OpenMPI version (now: 4.1.0) is installed first.

Dockerfile.example : is an example of the Dockerfile using horovod_entrypoint.

## Docker usage example

   ```bash
   docker run -e OpenMPI=4.1.0 -e HOROVOD=latest repo/dockerimage:tag <user_program>
   ```

## Requirements:
* The script expects that cuda and python3 are available.

* cmake, git, wget, libnccl2, libnccl-dev are also required.

