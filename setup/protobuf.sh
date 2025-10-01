#!/usr/bin/env bash
set -euxo pipefail

mkdir /tmp/protobuf
cd /tmp/protobuf

curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME}
echo "${PROTOBUF_SHA256}  ${PROTOBUF_FILENAME}" | sha256sum --check
unzip -o ${PROTOBUF_FILENAME} -d protoc3
mv protoc3/bin/* /usr/bin/
mv protoc3/include/* /usr/include/
rm -rf protoc3
rm ${PROTOBUF_FILENAME}

rm -rf /tmp/protobuf
