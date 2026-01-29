ARG INFINITO_IMAGE_REPO=ghcr.io/kevinveenbirkenbach/infinito-arch
ARG INFINITO_IMAGE_TAG=latest

FROM ${INFINITO_IMAGE_REPO}:${INFINITO_IMAGE_TAG} AS full

# Hadolint-like: ensure non-interactive package installs
SHELL ["/bin/bash", "-o", "pipefail", "-lc"]

# Defaults for docs build
ARG SPHINX_OUTPUT_DIR=/output/
ARG SPHINX_EXEC_DIR=/sphinx/

# The infinito repo path used by your ecosystem
ARG INFINITO_SRC_DIR=/opt/src/infinito

ENV SPHINX_OUTPUT_DIR=${SPHINX_OUTPUT_DIR}
ENV SPHINX_EXEC_DIR=${SPHINX_EXEC_DIR}
ENV INFINITO_SRC_DIR=${INFINITO_SRC_DIR}

WORKDIR ${SPHINX_EXEC_DIR}

# Install pandoc (required by infinito_docs.generators.ansible_roles)
RUN pacman -Sy --noconfirm --needed pandoc \
 && pacman -Scc --noconfirm

# Copy the infinito-sphinx (docs tooling) repo into /sphinx
COPY . ${SPHINX_EXEC_DIR}

# Install this repo as a Python package to provide infinito-docs-* CLIs
RUN python -m pip install --no-cache-dir .

# Explicit: run infinito setup first, then build HTML
RUN make setup && make html

EXPOSE 8000

CMD python -m http.server 8000 --directory "${SPHINX_OUTPUT_DIR}html/"
