# PARAMETER (with default values)

# Directory which cointains the Makefile
SPHINX_EXEC_DIR			?= .

# Directory from which the sources will be read
SPHINX_SOURCE_DIR  		?= ./source

# Directory which contains the builded files
SPHINX_OUTPUT_DIR   	?= ./output

# Args parsed to the sphinx-build command
SPHINXOPTS         		?= -c $(SPHINX_EXEC_DIR)

# Directory which contains the auto generated files
SPHINX_GENERATED_DIR 	= $(SPHINX_OUTPUT_DIR)/../generated

# Directory which contains the extracted requirement files
SPHINX_REQUIREMENTS_DIR = $(SPHINX_EXEC_DIR)/requirements

ASSETS_IMG=	$(SPHINX_SOURCE_DIR)/assets/img/

.PHONY: help install copy-images apidoc clean html generate Makefile up

# Copy images before running any Sphinx command (except for help)
copy-images:
	@echo "Copying images from $(ASSETS_IMG) to ./assets/img/..."
	cp -vr $(ASSETS_IMG)* ./assets/img/

# Installation routines for package manager
# This command shouldn't run inside the container
install: clean
	cp -vr --no-dereference $(shell pkgmgr path cymais)/* ./source/

# Generate reStructuredText files from Python modules using sphinx-apidoc
generate-apidoc:
	@echo "Running sphinx-apidoc..."
	sphinx-apidoc -f -o $(SPHINX_GENERATED_DIR)/modules $(SPHINX_SOURCE_DIR)

generate-yaml-index:
	@echo "Generating YAML index..."
	python generators/yaml_index.py --source-dir $(SPHINX_SOURCE_DIR) --output-file $(SPHINX_GENERATED_DIR)/yaml_index.rst

generate-ansible-roles:
	@echo "Generating Ansible roles documentation..."
	python generators/ansible_roles.py --roles-dir $(SPHINX_SOURCE_DIR)/roles --output-dir $(SPHINX_GENERATED_DIR)/roles
	@echo "Generating Ansible roles index..."
	python generators/index.py --roles-dir generated/roles --output-file $(SPHINX_SOURCE_DIR)/roles/ansible_role_glosar.rst --caption "Ansible Role Glosar"
	
generate-readmes:	
	@echo "Create required README.md's for index..."
	python generators/readmes.py --generated-dir ./$(SPHINX_GENERATED_DIR)

generate: generate-apidoc generate-yaml-index generate-ansible-roles generate-readmes

#extract-requirements:
#    @echo "Creating requirement files"
#    - python ./scripts/extract-requirements.py "$(SPHINX_EXEC_DIR)/requirements.yml" "$(SPHINX_REQUIREMENTS_DIR)"

clean:
	@echo "Removing generated files..."
	- git clean -fdX

help:
	- sphinx-build -M help "$(SPHINX_SOURCE_DIR)" "$(SPHINX_OUTPUT_DIR)" $(SPHINXOPTS) $(O)

html: copy-images generate
	@echo "Building Sphinx documentation..."
	- sphinx-build -M html "$(SPHINX_SOURCE_DIR)" "$(SPHINX_OUTPUT_DIR)" $(SPHINXOPTS)

just-html:
	- sphinx-build -M html "$(SPHINX_SOURCE_DIR)" "$(SPHINX_OUTPUT_DIR)" $(SPHINXOPTS)

up: install	
	- docker compose up -d --force-recreate --build

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option. $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	- sphinx-build -M $@ "$(SPHINX_SOURCE_DIR)" "$(SPHINX_OUTPUT_DIR)" $(SPHINXOPTS) $(O)
