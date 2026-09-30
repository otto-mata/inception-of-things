K3D_BIN_PATH = /usr/local/bin/k3d
ARGOCD_BIN_PATH = /usr/local/bin/argocd

up: $(K3D_BIN_PATH) $(ARGOCD_BIN_PATH)
	bash cluster-setup.sh

$(K3D_BIN_PATH):
	@test -f $@ || bash install-k3d-fedora.sh

$(ARGOCD_BIN_PATH):
	@test -f $@ || bash install-argocd.sh

down:
	k3d cluster destroy

.PHONY: up down
