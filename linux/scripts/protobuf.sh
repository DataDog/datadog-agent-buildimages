#!/usr/bin/env bash
set -euxo pipefail

unzip -o ${PROTOBUF_FILENAME} -d protoc3
mv protoc3/bin/* /usr/bin/
mv protoc3/include/* /usr/include/
