#!/bin/bash

# Inform DMon master about the type of this node. How this should be done is
# something that DMon maintainers will instruct you about.
# TODO: Node registration

# Configure and restart logstash forwarder
sudo cp lsf.json /etc/logstash-forwarder.conf.d
sudo service lsf restart

# Create some data for logstash forwarder to digest (this is where you install
# and configure your node).
for i in {1..100}
do
  echo "LSF should report this line $i"
done > /tmp/dummy.log
