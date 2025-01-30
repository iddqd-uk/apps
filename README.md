<p align="center">
  <img src="https://github.com/user-attachments/assets/c54f466b-104e-4fda-9c29-b0de0b7805fc" width="144px" height="144px"/>
</p>

# K8s Cluster charts

This repository contains the configuration and deployment scripts for a K3s cluster.

## Managing the Cluster

To manage the cluster, ensure that `make` and `docker` are installed on your machine. The required tools for
deployment are listed in the [Dockerfile](Dockerfile), but since everything is containerized, there is no need
to install them locally.

Before you begin, obtain a new token (or reuse an existing one) from the [Doppler](https://www.doppler.com/)
dashboard associated with this project. Add the token to the `.env` file (you can refer to the `.env.example`
file for guidance), and you will be ready to go.

You can use all available commands in the `Makefile` to manage the cluster. For the initial deployment,
use `make install(-*)`, and for subsequent deployments, use `make upgrade(-*)`.

> [!NOTE]
> The installation order is important:
>
> 1. `system` (contains essential configurations and CRDs)
> 2. `monitoring` (manages monitoring and logging)
> 3. `apps` (includes all applications running on the cluster)
