# docker-dd-agent-build-rpm-x64

This repo contains the Dockerfile used to build the Datadog Agent (https://github.com/DataDog/dd-agent).

The Datadog Agent is built using a Chef omnibus project (https://github.com/DataDog/dd-agent-omnibus) on CircleCi.


## IMPORTANT NOTE:
Because CentOS 5 has been EOL'd for a while now, any changes to the dockerfile need to use a former valid image for the bootstrapping. Meaning the `FROM` image in subsequent images will be `DataDog/docker-dd-agent-build-rpm-x64:sometag` or your build will fail; building the Dockerfile from `centos:5` will no longer work.

To keep a sane papertrail tag your new images with `YYYYMMDD` when you push to dockerhub. *_NEVER_* push with the `latest` tag unless you are absolutely sure your `YYYYMMDD` works, and the previous latest has a valid "backup" tag.

Finally, please push the changes to the dockerfile made to a `build/YYYYMMDD` branch so we can keep track of what's actually been done to the incremental image builds. 

Example Dockerfile:
```
FROM datadog/docker-dd-agent-build-rpm-x64:20180107
MAINTAINER Remi Hakim @remh

ADD new_entrypoiny.sh /

VOLUME ["/dd-agent-omnibus/pkg"]

ENTRYPOINT /bin/bash -l /new_entrypoiny.sh
```

Build with `docker build . -t DataDog/docker-dd-agent-build-rpm-x64:20180108` and push `docker push DataDog/docker-dd-agent-build-rpm-x64:20180108`.

Only once you're absolutely positive that works can you update the `latest` tag, after identifying a valid backup tag for the image exists.

You may naturally use dockerhub builds if you're more comfortable with that by using your `build/YYYYMMDD` tag. 
