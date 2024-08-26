#!/bin/bash -l

# This script checks all the amd64.deb packages in the working directory against the ones
# in the remote staging apt pool (apt.datad0g.com).
# If the package is already present in the pool (same name and version), replace the local one with the remote one.
# If the caller is releasing the deb packages, this makes the caller re-release the packages in
# the pool instead of releasing the local package.
# See https://github.com/DataDog/devops/wiki/Datadog-Agent-Release-Overview#apt-repository for why we do this.

set -e

for FILE in *amd64.deb; do
  # if no file matches the glob, we enter the loop once with FILE set to the raw glob. Handle this case.
  [ -e "${FILE}" ] || { echo "No file matching ${FILE} found, skipping apt pool check"; continue; }
  if curl --output /dev/null --silent --head --fail "https://s3.amazonaws.com/apt.datad0g.com/pool/d/da/${FILE}"; then
    echo "${FILE} already exists in the APT pool, replacing the local artifact with the remote one."
    rm -f "${FILE}"
    curl --silent -o "${FILE}" "https://s3.amazonaws.com/apt.datad0g.com/pool/d/da/${FILE}"
  else
    echo "The local artifact ${FILE} will be added to the APT pool."
  fi
done
