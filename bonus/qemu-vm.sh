#!/usr/bin/env bash
set -eo pipefail

BASE_IMAGE_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/44/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2"
BASE_IMAGE_FILE=`basename ${BASE_IMAGE_URL}`
VM_NAME="qemu-fedora-cloud"
DISK="${VM_NAME}.qcow2"

create() {
  if [ ! -f "$BASE_IMAGE_FILE" ]
  then
      curl -sfLO "$BASE_IMAGE_URL"
  fi
  qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE_FILE" "$DISK"
  python cloud-init/cloud-init-gen.py --no-iso
}

install() {
  virt-install \
    --connect qemu:///system \
    --name "$VM_NAME" \
    --memory 8192 \
    --vcpus 8 \
    --disk path="$DISK",format=qcow2 \
    --import \
    --os-variant fedora-unknown \
    --network network=default \
    --graphics none \
    --console pty,target_type=serial \
    --cloud-init user-data="cloud-init/user-data.yaml",meta-data="cloud-init/meta-data.yaml" \
    --noautoconsole
}

is_vm_running() {
  virsh --connect qemu:///system list --name | grep "$VM_NAME"
}

remove() {
  while is_vm_running
  do
    virsh --connect qemu:///system shutdown "$VM_NAME"
    sleep 2
  done
  virsh --connect qemu:///system undefine --domain "$VM_NAME" --remove-all-storage
}

case "$1" in
  "create")
    create
    ;;
  "install")
    install
    ;;
  "remove")
    remove
    ;;
  *)
    printf 'Usage: %s <create | install | remove>\n' "$0"
    ;;
esac
