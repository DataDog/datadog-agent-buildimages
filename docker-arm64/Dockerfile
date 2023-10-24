FROM 486234852809.dkr.ecr.us-east-1.amazonaws.com/docker:20.10-py3

COPY requirements.txt /
COPY requirements /requirements

RUN python3 -m pip install -r requirements.txt

# External calls configuration
COPY .awsconfig $HOME/.aws/config
COPY .curlrc .wgetrc $HOME/