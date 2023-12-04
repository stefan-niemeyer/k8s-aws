#!/usr/bin/env bash

# Allow login w/ passwd
sed --in-place 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl reload sshd

# Install K3
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.25 INSTALL_K3S_EXEC="server --cluster-init --write-kubeconfig-mode=644" sh

# Install K9s
wget -q -O - https://github.com/derailed/k9s/releases/download/v0.28.2/k9s_Linux_amd64.tar.gz | tar xz -C /usr/local/bin k9s
chown root:root /usr/local/bin/k9s
