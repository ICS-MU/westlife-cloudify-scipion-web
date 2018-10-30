# inputs/blueprint name parts
BASE_INPUTS=scipion-web-inputs
INPUTS=$(BASE_INPUTS).yaml
M4INPUTS=$(INPUTS).m4

BASE_BLUEPRINT=scipion-web-blueprint
BLUEPRINT=$(BASE_BLUEPRINT).yaml
M4BLUEPRINT=$(BLUEPRINT).m4

# blueprint/deployment names
CFY_BLUEPRINT=scipion-web
CFM_BLUEPRINT=scipion-web
CFM_DEPLOYMENT=scipion-web

RETRIES=50
VIRTUAL_ENV?=~/cfy
SCIPION_WEB?=https://github.com/ICS-MU/westlife-scipion-web
CFY_VERSION?=18.2.28
IS_CCZE:=$(shell ccze --version 2>/dev/null)

ifdef IS_CCZE
CCZE:=| ccze --mode ansi
endif

SHELL=/bin/bash -o pipefail

.PHONY: blueprints inputs validate test clean bootstrap bootstrap-cfy bootstrap-occi bootstrap-m4 cfy-local-profile cfm-plugins

# blueprints
blueprints: cfy-$(BLUEPRINT) cfm-$(BLUEPRINT)

cfy-$(BLUEPRINT): $(M4BLUEPRINT) cfy-$(INPUTS) bootstrap-m4
ifeq ($(PROVISIONER), )
	m4 $(M4BLUEPRINT) >".$@"
else
	m4 -D_PROVISIONER_=$(PROVISIONER) $(M4BLUEPRINT) >".$@"
endif
	mv ".$@" $@

cfm-$(BLUEPRINT): $(M4BLUEPRINT) cfy-$(INPUTS) bootstrap-m4
ifeq ($(PROVISIONER), )
	m4 -D_CFM_ $(M4BLUEPRINT) >".$@"
else
	m4 -D_CFM_ -D_PROVISIONER_=$(PROVISIONER) $(M4BLUEPRINT) >".$@"
endif
	mv ".$@" $@

# inputs
inputs: cfy-$(INPUTS) cfm-$(INPUTS)

cfy-$(INPUTS): $(M4INPUTS) resources/ssh_cfy/id_rsa bootstrap-m4
ifeq ($(PROVISIONER), )
	m4 $(M4INPUTS) >".$@"
else
	m4 -D_PROVISIONER_=$(PROVISIONER) $(M4INPUTS) >".$@"
endif
	mv ".$@" $@

cfm-$(INPUTS): $(M4INPUTS) resources/ssh_cfy/id_rsa bootstrap-m4
ifeq ($(PROVISIONER), )
	m4 -D_CFM_ -D_CFM_BLUEPRINT_=$(CFM_BLUEPRINT) $(M4INPUTS) >".$@"
else
	m4 -D_CFM_ -D_CFM_BLUEPRINT_=$(CFM_BLUEPRINT) -D_PROVISIONER_=$(PROVISIONER) $(M4INPUTS) >".$@"
endif
	mv ".$@" $@

validate: cfy-$(BLUEPRINT) cfm-$(BLUEPRINT)
	cfy blueprints validate cfy-$(BLUEPRINT)
	cfy blueprints validate cfm-$(BLUEPRINT)

test: validate inputs cfy-init clean

clean:
	-rm -rf cfy-$(INPUTS) .cfy-$(INPUTS) cfm-$(INPUTS) .cfm-$(INPUTS) cfy-$(BLUEPRINT) .cfy-$(BLUEPRINT) cfm-$(BLUEPRINT) .cfm-$(BLUEPRINT) cfm-$(BASE_BLUEPRINT).tar.bz2 resources/puppet.tar.gz resources/ssh_cfy/ local-storage/ resources/puppet/site/scipion_web/files/private/scipion_web.tar.gz

cfy-deploy: cfy-exec-install

cfy-undeploy: cfy-exec-uninstall

cfy-test: cfy-deploy cfy-undeploy

cfm-deploy: cfm-init cfm-exec-install

cfm-undeploy:
	-cfy executions start -d $(CFM_DEPLOYMENT) uninstall $(CCZE)
	-cfy deployments delete $(CFM_DEPLOYMENT) $(CCZE)
	-cfy deployments delete --force $(CFM_DEPLOYMENT) $(CCZE) #???
	cfy blueprints delete $(CFM_BLUEPRINT) $(CCZE)

cfm-test: cfm-deploy cfm-exec-uninstall cfm-clean


### Resources ####################################

resources/ssh_cfy/id_rsa:
	mkdir -p resources/ssh_cfy/
	ssh-keygen -N '' -f resources/ssh_cfy/id_rsa

resources/scipion_web:
	git clone $(SCIPION_WEB) $@

resources/puppet/site/scipion_web/files/private/scipion_web.tar.gz: resources/scipion_web
	mkdir -p resources/puppet/site/scipion_web/files/private/
	GZIP='-9' tar -czvf $@ -C $? .

resources/puppet.tar.gz: resources/puppet/site/scipion_web/files/private/scipion_web.tar.gz
	GZIP='-9' tar -czvf $@ -C resources/puppet/ .


### Standalone deployment ########################

cfy-local-profile:
	@cfy init -r

cfy-init: cfy-local-profile cfy-$(BLUEPRINT) cfy-$(INPUTS) resources/puppet.tar.gz
	cfy init --install-plugins -i cfy-$(INPUTS) cfy-$(BLUEPRINT) $(CCZE)

# execute deployment
cfy-exec-install: cfy-local-profile cfy-$(BLUEPRINT) cfy-$(INPUTS) resources/puppet.tar.gz
	cfy install -b $(CFY_BLUEPRINT) -i cfy-$(INPUTS) cfy-$(BLUEPRINT) --task-retries $(RETRIES) --install-plugins $(CCZE)

cfy-exec-uninstall: cfy-local-profile
	cfy uninstall -b $(CFY_BLUEPRINT) --task-retries $(RETRIES) $(CCZE)

cfy-outputs: cfy-local-profile
	cfy deployments outputs -b $(CFY_BLUEPRINT)


### Cloudify Manager managed deployment ##########

cfm-plugins:
	cfy plugin list 2>/dev/null | grep -Fq 'plugin:cloudify-fabric-plugin?version=1.5.1.1&' || \
		cfy plugin upload -y https://github.com/ICS-MU/westlife-cloudify-fabric-plugin/releases/download/1.5.1.1/plugin.yaml \
			https://github.com/ICS-MU/westlife-cloudify-fabric-plugin/releases/download/1.5.1.1/cloudify_fabric_plugin-1.5.1.1-py27-none-linux_x86_64-centos-Core.wgn
	cfy plugin list 2>/dev/null | grep -Fq 'plugin:cloudify-occi-plugin?version=0.0.15&' || \
		cfy plugin upload -y https://github.com/ICS-MU/westlife-cloudify-occi-plugin/releases/download/0.0.15/plugin.yaml \
			https://github.com/ICS-MU/westlife-cloudify-occi-plugin/releases/download/0.0.15/cloudify_occi_plugin-0.0.15-py27-none-linux_x86_64-centos-Core.wgn
	cfy plugin list 2>/dev/null | grep -Fq 'plugin:cloudify-host-pool-plugin?version=1.5&' || \
		cfy plugin upload -y https://github.com/cloudify-cosmo/cloudify-host-pool-plugin/releases/download/1.5/plugin.yaml \
			https://github.com/cloudify-cosmo/cloudify-host-pool-plugin/releases/download/1.5/cloudify_host_pool_plugin-1.5-py27-none-linux_x86_64-centos-Core.wgn

cfm-$(BASE_BLUEPRINT).tar.bz2: cfm-$(BLUEPRINT) cfm-$(INPUTS) scripts/ types/ resources/puppet.tar.gz
	BZIP2='-9' tar --transform 's,^,blueprint/,' -cjvf $@ $^

cfm-init: cfm-$(BASE_BLUEPRINT).tar.bz2 cfm-plugins
	cfy blueprints upload -b $(CFM_BLUEPRINT) -n cfm-$(BLUEPRINT) $< $(CCZE)
	cfy deployments create -b $(CFM_BLUEPRINT) -i cfm-$(INPUTS) $(CFM_DEPLOYMENT) $(CCZE)

cfm-exec-%:
	cfy executions start -d $(CFM_DEPLOYMENT) $* $(CCZE)
	sleep 10

cfm-scale-out:
	cfy executions start -d $(CFM_DEPLOYMENT) scale -p 'scalable_entity_name=workerNodes' -p 'delta=+1' $(CCZE)

cfm-scale-out-hostpool:
	cfy executions start -d $(CFM_DEPLOYMENT) scale -p 'scalable_entity_name=workerNodesHostPool' -p 'delta=+1' $(CCZE)

cfm-scale-in:
	cfy executions start -d $(CFM_DEPLOYMENT) scale -p 'scalable_entity_name=workerNodes' -p 'delta=-1' $(CCZE)

cfm-scale-in-hostpool:
	cfy executions start -d $(CFM_DEPLOYMENT) scale -p 'scalable_entity_name=workerNodesHostPool' -p 'delta=-1' $(CCZE)

cfm-outputs:
	cfy deployments outputs $(CFM_DEPLOYMENT)


### Bootstrap ####################################

bootstrap: bootstrap-cfy bootstrap-occi bootstrap-m4

bootstrap-m4:
	which m4 >/dev/null 2>&1 || \
		sudo yum install -y m4 || \
		sudo apt-get install -y m4

bootstrap-cfy:
	which virtualenv pip >/dev/null 2>&1 || \
		sudo yum install -y python-virtualenv python-pip || \
		sudo apt-get install -y python-virtualenv python-pip
	wget -O get-cloudify.py 'http://repository.cloudifysource.org/org/cloudify3/get-cloudify.py'
ifeq ($(CFY_VERSION), )
	python get-cloudify.py -e $(VIRTUAL_ENV) --upgrade
else
	python get-cloudify.py -e $(VIRTUAL_ENV) --upgrade --version $(CFY_VERSION)
endif
	unlink get-cloudify.py

bootstrap-occi:
	which occi >/dev/null 2>&1 || \
		sudo yum install -y ruby-devel openssl-devel gcc gcc-c++ ruby rubygems || \
		sudo apt-get install -y ruby rubygems ruby-dev
	which occi >/dev/null 2>&1 || \
		gem install occi-cli
