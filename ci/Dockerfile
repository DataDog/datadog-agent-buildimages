# syntax=docker/dockerfile:1

FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/images/docker:24.0.4-gbi-focal

COPY .awsconfig /root/.aws/config
COPY ci/install_awscli.sh /tmp/install_awscli.sh

RUN ./tmp/install_awscli.sh