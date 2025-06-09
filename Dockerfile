FROM --platform=linux/amd64 ubuntu:latest

LABEL description="Docker image for Terraform on AMD64 architecture."

RUN apt-get update -qy && apt-get upgrade -qy && apt-get install -qy curl unzip gnupg python3 python3-pip pipx

# SOPS
RUN SOPS_VERSION=3.10.2
RUN curl -LO https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64
RUN mv sops-v${SOPS_VERSION}.linux.amd64 /usr/local/bin/sops
RUN chmod +x /usr/local/bin/sops

# OpenTofu
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
RUN chmod +x install-opentofu.sh
RUN ./install-opentofu.sh --install-method standalone
RUN rm -f install-opentofu.sh
RUN cp /usr/local/bin/tofu /usr/local/bin/terraform

# OpenShift CLI
RUN curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz | tar xzvf -
RUN mv oc /usr/local/bin/oc

# pre-commit
RUN export PIPX_HOME=/opt/pipx
RUN export PIPX_BIN_DIR=/usr/local/bin
RUN pipx install --global pre-commit
RUN curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.20.0/terraform-docs-v0.20.0-$(uname)-amd64.tar.gz
RUN tar -xzf terraform-docs.tar.gz -C /usr/local/bin
RUN chmod +x /usr/local/bin/terraform-docs
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install --global checkov
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

CMD ["/bin/bash"]