#=============================================================================
#  HITwh Vegetable Group Docker Images Makefile Template
#
#  Code And Concept By HITwh Vegetable Group
#  https://github.com/hitwh-vegetable-group
#
#=============================================================================

REPO 				= hitwhvg
IMGNAME 			= lnmp
TAG 				= dev

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
.PHONY: save load

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
