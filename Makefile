#--------------------------------------------------------------
# image and container name
#--------------------------------------------------------------
APP_IMAGE=app
APP_CONT=app
TAG=latest

#--------------------------------------------------------------
# arguments
#--------------------------------------------------------------
# container from port
FROM_PORT?=8080
# container to port
TO_PORT?=8080
# git clone branch
GIT_BRANCH?=master
# ssh private key path
SSH_KEY_PATH?=$(HOME)/.ssh/id_rsa
# ssh private key
SSH_KEY?="$$(cat $(SSH_KEY_PATH))"
# git domain for private repository
GIT_DOMAIN?=github.com
# from mount
FROM_MOUNT?=$(shell echo $(PWD))
# to mount
TO_MOUNT=
# git clone url
GIT_CLONE_URL=
# google service account key file path
GOOGLE_SERVICE_ACCOUNT_KEY_FILE=
# for docker run env_file
ENV_FILE=
#--------------------------------------------------------------
# make commands
#--------------------------------------------------------------
build:
	export DOCKER_BUILDKIT=1; docker build --secret id=ssh,src=$(SSH_KEY_PATH) --rm -f docker/build/golang/Dockerfile --build-arg WORKDIR=$(WORKDIR) --build-arg GIT_CLONE_URL=$(GIT_CLONE_URL) --build-arg GIT_DOMAIN=$(GIT_DOMAIN) --build-arg GIT_BRANCH=$(GIT_BRANCH) -t $(APP_IMAGE) .

build-app-engine:
	export DOCKER_BUILDKIT=1; docker build --secret id=ssh,src=$(SSH_KEY_PATH) --rm -f docker/build/cloud/gcp/app_engine/Dockerfile --build-arg WORKDIR=$(WORKDIR) --build-arg GIT_CLONE_URL=$(GIT_CLONE_URL) --build-arg GIT_DOMAIN=$(GIT_DOMAIN) --build-arg GIT_BRANCH=$(GIT_BRANCH) --build-arg GOOGLE_SERVICE_ACCOUNT_KEY_FILE=$(GOOGLE_SERVICE_ACCOUNT_KEY_FILE) -t $(APP_IMAGE)-app-engine .

build-test:
	export DOCKER_BUILDKIT=1; docker build --secret id=ssh,src=$(SSH_KEY_PATH) --rm -f docker/test/Dockerfile --build-arg WORKDIR=$(WORKDIR) --build-arg GIT_CLONE_URL=$(GIT_CLONE_URL) --build-arg GIT_DOMAIN=$(GIT_DOMAIN) --build-arg GIT_BRANCH=$(GIT_BRANCH) -t $(APP_IMAGE)-test .

build-local:
	docker build --rm -f docker/local/Dockerfile --build-arg WORKDIR=$(WORKDIR) --build-arg GIT_DOMAIN=$(GIT_DOMAIN) --build-arg SSH_KEY=$(SSH_KEY) -t $(APP_IMAGE)-local .

run:
	-docker stop $(APP_CONT)
	docker run --rm -d -p $(FROM_PORT):$(TO_PORT) --name $(APP_CONT) $(APP_IMAGE):$(TAG)

run-app-engine:
	docker run --rm -d --env-file=$(ENV_FILE) $(APP_IMAGE)-app-engine:$(TAG)

run-test:
	-docker stop $(APP_CONT)-test
	docker run --rm -d --name $(APP_CONT)-test $(APP_IMAGE)-test:$(TAG)

run-local:
	-docker stop $(APP_CONT)-local
	docker run --rm -d -p $(FROM_PORT):$(TO_PORT) -v $(FROM_MOUNT):$(TO_MOUNT) --name $(APP_CONT)-local $(APP_IMAGE)-local:$(TAG)

check-aws:
	PROFILE=--profile $(PROFILE)
	AWS_ID=$$( \
			aws sts get-caller-identity \
			--query 'Account' \
			--output text \
			$(PROFILE))
	REGION=$$(aws configure get region $(PROFILE))

upload-aws: check-aws
	@$$(aws ecr get-login --no-include-email --region $(REGION) $(PROFILE))
	@docker tag $(APP_IMAGE):$(TAG) $(AWS_ID).dkr.ecr.$(REGION).amazonaws.com/$(APP_IMAGE):$(TAG)
	@docker push $(AWS_ID).dkr.ecr.$(REGION).amazonaws.com/$(APP_IMAGE):$(TAG)

upload-gcp:
# see https://cloud.google.com/container-registry/docs/pushing-and-pulling
	@gcloud auth configure-docker --quiet
	@docker tag $(APP_IMAGE) gcr.io/$(PROJECT_ID)/$(APP_IMAGE)
	@docker push gcr.io/$(PROJECT_ID)/$(APP_IMAGE):$(TAG)

upload-azure:
# see https://docs.microsoft.com/ja-jp/azure/container-registry/container-registry-get-started-docker-cli
	@az acr login --name $(REGISTORY)
	@docker tag $(APP_IMAGE) $(REGISTORY).azurecr.io/$(APP_IMAGE)
	@docker push $(REGISTORY).azurecr.io/$(APP_IMAGE):$(TAG)
