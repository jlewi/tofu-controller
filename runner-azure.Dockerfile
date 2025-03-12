ARG BASE_IMAGE

FROM $BASE_IMAGE

ARG TARGETARCH
ARG TF_VERSION=1.3.9

# Set environment variables for version and architecture
ARG KUBELOGIN_VERSION=0.1.9

# Switch to root to have permissions for operations
USER root

#******************************************************
# Install the AZ cli
# This is needed to apply Azure resources

# Install Python 3 and Pip
RUN apk add --no-cache python3 py3-pip

# Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev \
    cargo \
    make

# Create and activate a virtual environment
# We need to use a virtual environment because we can't modify the system python
RUN python3 -m venv /opt/azcli \
    && . /opt/azcli/bin/activate

# Upgrade Pip and install Azure CLI within the virtual environment
RUN /opt/azcli/bin/pip install --upgrade pip \
    && /opt/azcli/bin/pip install azure-cli

# Add Azure CLI to PATH
ENV PATH="/opt/azcli/bin:$PATH"

ADD https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${TARGETARCH}.zip /terraform_${TF_VERSION}_linux_${TARGETARCH}.zip
RUN unzip -q /terraform_${TF_VERSION}_linux_${TARGETARCH}.zip -d /usr/local/bin/ && \
    rm /terraform_${TF_VERSION}_linux_${TARGETARCH}.zip && \
    chmod +x /usr/local/bin/terraform

# Download and install kubelogin
ADD https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-${TARGETARCH}.zip /tmp/kubelogin-linux-${TARGETARCH}.zip
RUN unzip -q /tmp/kubelogin-linux-${TARGETARCH}.zip -d /tmp/ && \
    mv /tmp/bin/linux_${TARGETARCH}/kubelogin /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubelogin && \
    rm -rf /tmp/kubelogin-linux-${TARGETARCH}.zip /tmp/bin


# Install curl
RUN apk update && apk add --no-cache curl

# Download kubectl
RUN curl -LO https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl

# Make kubectl executable and move it to a directory in PATH
RUN chmod +x kubectl && mv kubectl /usr/local/bin/kubectl

# Switch back to the non-root user after operations
USER 65532:65532

ENV GNUPGHOME=/tmp