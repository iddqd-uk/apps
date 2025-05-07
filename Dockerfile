# syntax=docker/dockerfile:1

#################################################################################################################
## This Dockerfile contains all the necessary tools to work with the project's Kubernetes cluster locally. By  ##
## using it, you don't need to install anything on your host system, as everything is already included in this ##
## Docker image.                                                                                               ##
#################################################################################################################

FROM docker.io/library/alpine:3.21

# install kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
RUN set -x \
    # renovate: source=github-releases name=kubernetes/kubernetes
    && KUBECTL_VERSION="1.33.0" \
    && APK_ARCH="$(apk --print-arch)" \
    && case "${APK_ARCH}" in \
        x86_64) KUBECTL_ARCH="amd64" ;; \
        aarch64) KUBECTL_ARCH="arm64" ;; \
        *) echo >&2 "error: unsupported architecture: ${APK_ARCH}"; exit 1 ;; \
    esac \
    && BASE_URL="https://dl.k8s.io/release" \
    && wget -q \
      -O /usr/local/bin/kubectl \
      "${BASE_URL}/v${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client

# install helm (https://github.com/helm/helm)
RUN set -x \
    # renovate: source=github-releases name=helm/helm
    && HELM_VERSION="3.17.2" \
    && APK_ARCH="$(apk --print-arch)" \
    && case "${APK_ARCH}" in \
        x86_64) HELM_ARCH="amd64" ;; \
        aarch64) HELM_ARCH="arm64" ;; \
        *) echo >&2 "error: unsupported architecture: ${APK_ARCH}"; exit 1 ;; \
    esac \
    && BASE_URL="https://get.helm.sh" \
    && wget -q "${BASE_URL}/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz" -O - | \
      tar -xzO "linux-${HELM_ARCH}/helm" > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && helm version

# install doppler (https://github.com/DopplerHQ/cli)
RUN set -x \
    # renovate: source=github-releases name=DopplerHQ/cli
    && DOPPLER_VERSION="3.73.0" \
    && APK_ARCH="$(apk --print-arch)" \
    && case "${APK_ARCH}" in \
        x86_64) DOPPLER_ARCH="amd64" ;; \
        aarch64) DOPPLER_ARCH="arm64" ;; \
        *) echo >&2 "error: unsupported architecture: ${APK_ARCH}"; exit 1 ;; \
    esac \
    && BASE_URL="https://github.com/DopplerHQ/cli/releases/download" \
    && wget -q "${BASE_URL}/${DOPPLER_VERSION}/doppler_${DOPPLER_VERSION}_linux_${DOPPLER_ARCH}.tar.gz" -O - | \
      tar -xzO "doppler" > /usr/local/bin/doppler \
    && chmod +x /usr/local/bin/doppler \
    && doppler --version

# install kube-linter (https://github.com/stackrox/kube-linter)
RUN set -x \
    # renovate: source=github-releases name=stackrox/kube-linter
    && KUBE_LINTER_VERSION="0.7.2" \
    && APK_ARCH="$(apk --print-arch)" \
    && case "${APK_ARCH}" in \
        x86_64) KUBE_LINTER_ARCH="" ;; \
        aarch64) KUBE_LINTER_ARCH="_arm64" ;; \
        *) echo >&2 "error: unsupported architecture: ${APK_ARCH}"; exit 1 ;; \
    esac \
    && BASE_URL="https://github.com/stackrox/kube-linter/releases/download" \
    && wget -q "${BASE_URL}/v${KUBE_LINTER_VERSION}/kube-linter-linux${KUBE_LINTER_ARCH}.tar.gz" -O - | \
      tar -xzO "kube-linter" > /usr/local/bin/kube-linter \
    && chmod +x /usr/local/bin/kube-linter \
    && kube-linter version
