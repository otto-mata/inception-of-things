#!/usr/bin/env bash
set -eu

test `id -u` -eq 0 || (printf "Must be root to run install script\n" && exit 1)

if ! command -v k3d
then
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
	printf "k3d installed\n"
	if ! systemctl is-active podman.socket
	then
		printf "podman.socket isn't active, setting it up\n"
		systemctl enable --now podman.socket
		mkdir -pv /etc/containers/containers.conf.d
		set -x
		echo 'service_timeout=0' > /etc/containers/containers.conf.d/timeout.conf
		set +x
		ln -sv /run/podman/podman.sock /var/run/docker.sock

		# Podman's Docker compat layer may try to fetch logs using journald
		# 
		# Related: https://github.com/Glyndor/podup/pull/1872
		# > The Podman 5 VM already moved container logs to k8s-file
		# > because Fedora 44's journald binding cannot open its library
		# > (every logs request came back 500 unable to open a handle
		# > to the library). The events backend reads the same journal
		# > through the same binding and was left on journald.
		# 
		# We explicitely tell Podman to use k8s-file for logs
		printf '[containers]\nlog_driver = "k8s-file"' >> /etc/containers/containers.conf
	fi
else
	printf "k3d already installed\n"
fi

if ! command -v kubectl
then
	temp_dir=`mktemp -d`
	curl -sfL "https://dl.k8s.io/release/v1.37.1/bin/linux/amd64/kubectl" \
		-o "$temp_dir/kubectl"
	curl -sfL "https://dl.k8s.io/release/v1.37.1/bin/linux/amd64/kubectl.sha256" \
		-o "$temp_dir/kubectl.sha256"
	printf " kubectl" >> "$temp_dir/kubectl.sha256"
	pushd "$temp_dir"
		sha256sum --check kubectl.sha256
		install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
	popd
	rm -rf "$temp_dir"
	printf "kubectl installed\n"
else
	printf "kubectl already installed\n"
fi
