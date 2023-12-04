#!/usr/bin/env bash

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage $(basename $0) user passwd"
  exit 1
fi

set -e     # exit script if a command fails

LAB_USER=$1
LAB_PASSWD="$2"

# Create user
useradd --create-home --shell /bin/bash "${LAB_USER}"
echo "${LAB_USER}:${LAB_PASSWD}" | chpasswd

# Copy K3s access file
mkdir -p "/home/${LAB_USER}/.kube"
cp /etc/rancher/k3s/k3s.yaml "/home/${LAB_USER}/.kube/config"
chown -R "${LAB_USER}:${LAB_USER}" "/home/${LAB_USER}/.kube"

# Config .profile
echo 'export KUBECONFIG=$HOME/.kube/config' >> "/home/${LAB_USER}/.profile"
echo 'export EXTERNAL_DNS=$(hostname).laserschwert.io' >> "/home/${LAB_USER}/.profile"
echo 'alias k=kubectl' >> "/home/${LAB_USER}/.profile"
echo "alias ktools='kubectl run tools --rm -it --image wbitt/network-multitool -- /bin/bash'" >> "/home/${LAB_USER}/.profile"
