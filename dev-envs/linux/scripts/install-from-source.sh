#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

# Set default values
ALGORITHM="sha256"
CONFIGURE_SCRIPT="./configure"
INSTALL_SCRIPT="make -j \"$(nproc)\" && make install"

while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift
            shift
            ;;
        --url)
            URL="$2"
            shift
            shift
            ;;
        --relative-path)
            RELATIVE_PATH="$2"
            shift
            shift
            ;;
        --digest)
            DIGEST="$2"
            shift
            shift
            ;;
        --algorithm)
            ALGORITHM="$2"
            shift
            shift
            ;;
        --configure-script)
            CONFIGURE_SCRIPT="$2"
            shift
            shift
            ;;
        --install-script)
            INSTALL_SCRIPT="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

URL="${URL//'{{version}}'/${VERSION}}"
RELATIVE_PATH="${RELATIVE_PATH//'{{version}}'/${VERSION}}"

archive_name=$(basename "${URL}")
work_dir="/tmp/$(openssl rand -base64 16)"
archive_path="${work_dir}/${archive_name}"
mkdir -p "${work_dir}"
curl "${URL}" -Lo "${archive_path}"

digest=$(openssl dgst -"${ALGORITHM}" "${archive_path}" | cut -d' ' -f2)
if [[ "${digest}" != "${DIGEST}" ]]; then
    echo "Digest mismatch"
    echo "Expected: ${DIGEST}"
    echo "Got: ${digest}"
    exit 1
fi

tar -xf "${archive_path}" -C "${work_dir}"
ls "${work_dir}"

pushd "${work_dir}/${RELATIVE_PATH}"
eval "${CONFIGURE_SCRIPT}"
eval "${INSTALL_SCRIPT}"
popd
rm -rf "${work_dir}"
