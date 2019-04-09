#=============================================================================
#  HITwh Vegetable Group Docker Images Makefile Template
#
#  Code And Concept By HITwh Vegetable Group
#  https://github.com/hitwh-vegetable-group
#
#=============================================================================

REPO 				= hitwhvg
IMGNAME 			= secp_panel
TAG 				= dev

WINDOWS_USERNAME	= Drancick
WINDOWS_HOSTNAME	= 192.168.200.1
WINDOWS_ENV			= $(SECP_PANEL) # Need env patch first !

REMOTE_USERNAME		= root
REMOTE_HOSTNAME		= 192.168.200.132
REMOTE_ENV			= "/opt/secp/secp_panel"

# Build relative
.PHONY: status check reupload cache no-cache
status:
	docker ps -a
	docker images
check:
	cat ./Makefile
reupload:
	rm -rf ./* ./.dockerignore
	rz
cache:
	docker build -t $(REPO)/$(IMGNAME):$(TAG) .
no-cache:
	docker build -t $(REPO)/$(IMGNAME):$(TAG) --no-cache .

# Clean relative
.PHONY: clean hard-clean
.IGNORE: clean clean-containers
clean:
	docker rmi -f `docker images | grep none | awk '{print $3}'`
clean-containers:
	docker rm -f `docker ps -aq`
hard-clean: clean-containers clean

# Image relative
.PHONY: save load scp
save:
	docker save $(REPO)/$(IMGNAME):$(TAG) > $(REPO)-$(IMGNAME)-$(TAG).tar
load:
	docker load < $(REPO)-$(IMGNAME)-$(TAG).tar

# Test relative
.PHONY: test tclean
.IGNORE: tclean
tclean:
	docker rm -f $(IMGNAME)
test: tclean
	docker run -dit -p 80:80 --name=$(IMGNAME) $(REPO)/$(IMGNAME):$(TAG)
	docker exec -it $(IMGNAME) /bin/bash

# Remote to Windows
.PHONY: scp-windows
patch_env:
	bash env_windows.sh
scp-windows: patch_env
	scp ./$(REPO)-$(IMGNAME)-$(TAG).tar $(WINDOWS_USERNAME)@$(WINDOWS_HOSTNAME):$(WINDOWS_ENV)