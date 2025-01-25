<p align="center">
  <img src="https://github.com/user-attachments/assets/c54f466b-104e-4fda-9c29-b0de0b7805fc" width="144px" height="144px"/>
</p>

# K8s Cluster charts

This repository contains the configuration and deployment scripts for a K3s cluster.

## Prerequisites

- [Helm](https://helm.sh/)
- [Doppler](https://www.doppler.com/)
- [Docker](https://www.docker.com/) (optional, for local development)

First of all, you need to [authenticate the doppler CLI](https://docs.doppler.com/docs/cli#authentication) with
your account:

```sh
doppler login
````

Next, you may use all the available commands in the `Makefile` to deploy the cluster. For the first deployment, you
need to use the `make install`, any future deployment can be done with `make upgrade-system` or `make upgrade-apps`.
