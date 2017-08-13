RKT_VERSION ?= 1.28.1
KUBECTL_VERSION ?= v1.7.1
TERRAFORM_VERSION ?= 0.9.6
MATCHBOX_VERSION ?= v0.6.1

RKT_DEB ?= rkt_$(RKT_VERSION)-1_amd64.deb

install: install-rkt
	apt-get update -y
	apt-get install --no-install-recommends -y git unzip qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients virtinst

clean: deps
	rm -rf $?
	
install-rkt: deps/$(RKT_DEB)
	dpkg -i $<
 
deps/$(RKT_DEB): deps
	curl -L -o $@ https://github.com/rkt/rkt/releases/download/v$(RKT_VERSION)/$(notdir $@)

deps/kubectl: deps
	curl -L -o $@ https://storage.googleapis.com/kubernetes-release/release/$(KUBECTL_VERSION)/bin/linux/amd64/kubectl
	chmod +x $@

deps/terraform: deps
	curl -L https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_linux_amd64.zip | funzip > $@
	chmod +x $@

deps/matchbox: deps
	git clone --branch $(MATCHBOX_VERSION) --depth 1 https://github.com/coreos/matchbox $@

deps:
	mkdir $@

.PHONY: install install-rkt clean
