#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

BINARIES=()
DIGESTS=()

# Set default values
ALGORITHM="sha256"
TOP_LEVEL="0"
UNPACK_COMMAND=""

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
        --digest)
            DIGESTS+=("$2")
            shift
            shift
            ;;
        --name)
            BINARIES+=("$2")
            shift
            shift
            ;;
        --algorithm)
            ALGORITHM="$2"
            shift
            shift
            ;;
        --unpack-command)
            UNPACK_COMMAND="$2"
            shift
            shift
            ;;
        --top-level)
            TOP_LEVEL="1"
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

URL="${URL//'{{version}}'/${VERSION}}"

file_name=$(basename "${URL}")
file_path="/tmp/${file_name}"

curl "${URL}" -Lo "${file_path}"

digest=$(openssl dgst -"${ALGORITHM}" "${file_path}" | cut -d' ' -f2)
match="0"
for d in "${DIGESTS[@]}"; do
    if [[ "${d}" == "${digest}" ]]; then
        match="1"
        break
    fi
done
if [[ "${match}" == "0" ]]; then
    echo "Digest mismatch"
    echo "Expected:"
    for d in "${DIGESTS[@]}"; do
        echo "    ${d}"
    done
    echo "Got: ${digest}"
    exit 1
fi

if [[ "${file_name}" =~ \.tar\.gz$ ]]; then
    for binary in "${BINARIES[@]}"; do
        if [[ "${TOP_LEVEL}" == "1" ]]; then
            tar -xf "${file_path}" -C /usr/local/bin "${binary}"
        else
            tar -xf "${file_path}" -C /usr/local/bin --strip-components=1 --wildcards "*/${binary}"
        fi
        chmod +x "/usr/local/bin/${binary}"
    done
elif [[ "${file_name}" =~ \.zip$ ]]; then
    if [[ -n "${UNPACK_COMMAND}" ]]; then
        unpack_command="${UNPACK_COMMAND//'{{file_path}}'/${file_path}}"
        eval "${unpack_command}"
        for binary in "${BINARIES[@]}"; do
            chmod +x "/usr/local/bin/${binary}"
        done
    else
        for binary in "${BINARIES[@]}"; do
            unzip -j "${file_path}" "${binary}" -d /usr/local/bin
            chmod +x "/usr/local/bin/${binary}"
        done
    fi
else
    target_path="/usr/local/bin/${BINARIES[0]}"
    mv "${file_path}" "${target_path}"
    chmod +x "${target_path}"
fi

# Remove any downloaded archive
if [[ -f "${file_path}" ]]; then
    rm "${file_path}"
fi
