TERRAFORM_CONFIG ?= config.tfvars

TERRAFORM_VERSION ?= 0.9.6
MATCHBOX_VERSION ?= v0.6.1
TECTONIC_VERSION ?= 1.7.1

RKT_DEB ?= rkt_$(RKT_VERSION)-1_amd64.deb
TECTONIC_TAR ?= tectonic-$(TECTONIC_VERSION)-tectonic.1.tar.gz

COREOS_CHANNEL ?= $(shell awk -F "=" '/^tectonic_cl_channel/ {gsub(/[ \t"]/, "", $$2); print $$2}' $(TERRAFORM_CONFIG))
COREOS_VERSION ?= $(shell awk -F "=" '/^tectonic_metal_cl_version/ {gsub(/[ \t"]/, "", $$2); print $$2}' $(TERRAFORM_CONFIG))

DOMAIN ?= dg.gg

tectonic/terraformrc.example: tectonic
tectonic/.terraformrc: tectonic/terraformrc.example
	sed "s|<PATH_TO_INSTALLER>|$(realpath $(dir $@)/tectonic-installer/linux/installer)|g" $< > $@

tectonic: deps/$(TECTONIC_TAR)
	mkdir -p $@
	ln -fs $(notdir $(TERRAFORM_CONFIG)) $@
	tar -xzvf $<

matchbox/server.key: deps/matchbox
	mkdir -p $(dir $@)
	cd $</scripts/tls && \
		SAN=DNS.1:matchbox.${DOMAIN} exec ./cert-gen
	mv $</scripts/tls/*.key $</scripts/tls/*.crt $(dir $@)

matchbox/coreos: matchbox/coreos/$(COREOS_VERSION)
matchbox/coreos/$(COREOS_VERSION): deps/matchbox
	$</scripts/get-coreos $(COREOS_CHANNEL) $(COREOS_VERSION) $$(dirname $(dir $@))

install: install-rkt
	apt-get update -y
	apt-get install --no-install-recommends -y git unzip qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients virtinst

clean:
	rm -rf deps matchbox tectonic
	
install-rkt: deps/$(RKT_DEB)
	dpkg -i $<
 
deps/$(RKT_DEB): deps
	curl -L -o $@ https://github.com/rkt/rkt/releases/download/v$(RKT_VERSION)/$(notdir $@)

deps/kubectl: deps
	curl -L -o $@ https://storage.googleapis.com/kubernetes-release/release/$(KUBECTL_VERSION)/bin/linux/amd64/kubectl
	chmod +x $@

deps/matchbox: deps
	git clone --branch $(MATCHBOX_VERSION) --depth 1 https://github.com/coreos/matchbox $@

deps/$(TECTONIC_TAR): deps
	curl -L -o $@ https://releases.tectonic.com/$(notdir $@)

deps:
	mkdir $@

.PHONY: install install-rkt clean
