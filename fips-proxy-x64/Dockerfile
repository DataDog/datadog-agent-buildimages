FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:v2718644-9ce6565-18.09.6-py3

COPY ./requirements.txt .

RUN apt-get install jq bash

RUN python3 -m pip install -r requirements.txt
