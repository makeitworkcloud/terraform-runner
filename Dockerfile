FROM --platform=linux/amd64 ubuntu:latest

LABEL description="Ubuntu-based image for OpenTofu/Terraform on AMD64 architecture."

RUN apt-get update -qy && apt-get upgrade -qy && apt-get install -qy curl unzip gnupg python3 python3-pip pipx git jq yq lsb-release

# SOPS
RUN curl -LO https://github.com/getsops/sops/releases/download/v3.10.2/sops-v3.10.2.linux.amd64
RUN mv sops-v3.10.2.linux.amd64 /usr/local/bin/sops
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
RUN chmod +x /usr/local/bin/oc

# Kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
RUN mv kustomize /usr/local/bin/kustomize
RUN chmod +x /usr/local/bin/kustomize

# pre-commit & dependencies
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install pre-commit
RUN curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.20.0/terraform-docs-v0.20.0-$(uname)-amd64.tar.gz
RUN tar -xzf terraform-docs.tar.gz -C /usr/local/bin
RUN curl -sSLo ./tfupdate.tar.gz https://github.com/minamijoyo/tfupdate/releases/download/v0.9.1/tfupdate_0.9.1_linux_amd64.tar.gz
RUN tar -xzf tfupdate.tar.gz -C /usr/local/bin
RUN curl -sSLo ./hcledit.tar.gz https://github.com/minamijoyo/hcledit/releases/download/v0.2.17/hcledit_0.2.17_darwin_amd64.tar.gz
RUN tar -xzf hcledit.tar.gz -C /usr/local/bin
RUN chmod +x /usr/local/bin/terraform-docs
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install checkov
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
RUN curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Arguments for the terraformer user
ARG USERNAME=terraformer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the terraformer user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

# Setup pre-commit hooks
WORKDIR $HOME
RUN git init pre-commit-init
ADD pre-commit-config.yaml pre-commit-init/.pre-commit-config.yaml
WORKDIR ${HOME}/pre-commit-init
RUN pre-commit install-hooks
WORKDIR $HOME

CMD ["/bin/bash"]
