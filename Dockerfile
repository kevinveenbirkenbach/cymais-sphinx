ARG DOCKER_PYTHON_VERSION
FROM python:3.9-slim

# The following is necessary because make can not copy files outside their directory
ARG SPHINX_HOST_SOURCE_DIR_RELATIVE=./source/
ARG SPHINX_HOST_EXEC_DIR_RELATIVE=./

# Defaults
ARG SPHINX_SOURCE_DIR=/source/
ARG SPHINX_OUTPUT_DIR=/output/
ARG SPHINX_EXEC_DIR=/sphinx/

# Set the environment variables so they are available during build for Makefile
ENV SPHINX_SOURCE_DIR=${SPHINX_SOURCE_DIR}
ENV SPHINX_OUTPUT_DIR=${SPHINX_OUTPUT_DIR}
ENV SPHINX_REQUIREMENTS_DIR=${SPHINX_EXEC_DIR}/requirements

# Set the working directory
WORKDIR ${SPHINX_EXEC_DIR}

# Update and install make
RUN apt-get update && apt install -y make

# Copy the project files into the container
COPY ${SPHINX_HOST_EXEC_DIR_RELATIVE} ${SPHINX_EXEC_DIR}

# Copy the source files into the container
COPY ${SPHINX_HOST_SOURCE_DIR_RELATIVE} ${SPHINX_SOURCE_DIR}

# Install required packages
RUN xargs -a ${SPHINX_REQUIREMENTS_DIR}/apt.txt apt install -y

# Install Python packages via requirements.txt
RUN pip install --upgrade pip && pip install -r ${SPHINX_REQUIREMENTS_DIR}/pip.txt

# Build the HTML documentation using Sphinx with the defined directories
RUN cd ${SPHINX_EXEC_DIR} && make html

# Expose port 8000 where the HTTP server will run
EXPOSE 8000

# Start a simple HTTP server to serve the built documentation
CMD python -m http.server 8000 --directory "${SPHINX_OUTPUT_DIR}html/"
