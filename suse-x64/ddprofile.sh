# This is our local profile for suse, adding RVM and Conda to the image's path

if [ -r /etc/profile.d/rvm.sh ] ; then
  . /etc/profile.d/rvm.sh
fi

if [ -r /etc/profile.d/conda.sh ] ; then
  . /etc/profile.d/conda.sh
fi

export PATH="/opt/datadog/bin:$PATH"
