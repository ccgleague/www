SHELL := $(shell which bash) # Use bash instead of bin/sh as shell
SYS_PYTHON := $(shell which python3 || echo ".python_is_missing")
VENV = .venv
PYTHON := $(VENV)/bin/python3
PIP := $(VENV)/bin/pip3
PROJECT_NAME=$(shell basename $(PWD))
DEPS := $(VENV)/.deps
AWSCLI := $(VENV)/bin/aws
BUCKET := www.chicagochicagogolfleague.com
REGION := us-east-1
BUCKET_INFO := .bucket_info
WEBSITE_INFO := .website_info
BUCKET_CONF := conf/s3api.create-bucket.json
WEBSITE_CONF := conf/s3api.put-bucket-website.json
LIVERELOAD_HOST := localhost
export AWS_CONFIG_FILE=$(PWD)/.aws/credentials
export AWS_SHARED_CREDENTIALS_FILE=$(PWD)/.aws/credentials

.SILENT:

help:
	grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(AWS_SHARED_CREDENTIALS_FILE):
	$(info "Enter the credentials for the 'website' user in the website CCGL AWS account)
	$(VENV)/bin/aws configure

$(SYS_PYTHON):
	$(error "You need Python 3. I can't find it on the PATH.")

$(VENV): $(SYS_PYTHON)
	$(SYS_PYTHON) -m venv $(VENV)

$(DEPS): requirements.txt | $(VENV)
	$(PIP) install setuptools --upgrade pip
	$(PIP) install -r requirements.txt
	cp requirements.txt $(DEPS)

$(BUCKET_INFO): | $(BUCKET_CONF)
	$(AWSCLI) s3api create-bucket \
		--region $(REGION) \
		--bucket $(BUCKET) \
		--cli-input-json file://$(BUCKET_CONF) \
		> $(BUCKET_INFO)

$(WEBSITE_INFO): | $(WEBSITE_CONF) $(BUCKET_INFO)
	$(AWSCLI) s3api put-bucket-website \
		--region $(REGION) \
		--bucket $(BUCKET) \
		--cli-input-json file://$(WEBSITE_CONF) \
		> $(WEBSITE_INFO)

.PHONY: deploy server bucket solve clean

clean: ## Remove pycache files
	find . -name __pycache__ | grep -v .venv | xargs rm -rf
	rm -rf $(VENV)

solve: deps.txt clean $(VENV) ## Re-solve locked project dependencies from deps.txt
	$(PIP) install setuptools --upgrade pip==19.3.1
	$(PIP) install -r deps.txt
	$(PIP) freeze > requirements.txt
	cp requirements.txt $(DEPS)

deploy: $(DEPS) $(AWS_SHARED_CREDENTIALS_FILE) ## Deploy webapp to S3 bucket
	$(AWSCLI) s3 sync public/ s3://$(BUCKET) --acl public-read

bucket: $(AWS_SHARED_CREDENTIALS_FILE) | $(WEBSITE_INFO) ## Create a new S3 bucket using the configuration in conf/*
	echo Website URL: http://$(BUCKET).s3-website-$(REGION).amazonaws.com

server: $(DEPS) ## Run a development web server with livereload on port 35729
	echo "Open http://localhost:35729 in your web browser"
	$(VENV)/bin/livereload --host $(LIVERELOAD_HOST) public
