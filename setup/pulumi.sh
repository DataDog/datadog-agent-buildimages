#!/usr/bin/env bash


curl --retry 10 -fsSL https://get.pulumi.com/ | bash -s -- --version $PULUMI_VERSION && \
    mv ~/.pulumi/bin/* /usr/local/bin
