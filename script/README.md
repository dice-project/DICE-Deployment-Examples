# Monitoring of user installed software

DICE TOSCA library allows us to setup DMon monitoring for custom nodes.
Monitoring is composed of two parts: registering node role with DMon and
setting up actual data transmission.

Registering with DMon is done by DICE TOSCA library and all we need to do is
list node roles in `roles` field in monitoring property. WARNING: MAKE SURE
ROLE USED IS SUPPORTED BY DMON!!!!

Data acquisition is done by collectd and logstash forwarder. DICE TOSCA
library configures collectd automatically when we enable monitoring on the
script node, so we only need to configure logstash forwarder.

To send logs to DMon, DICE TOSCA library sets up logstash forwarder service
that is partially configured and disabled by default. In order to finalize
configuraton, we must inform it about locations of our logs. This is done by
placing part of logstash forwarder configuration into
`/etc/logstash-forwarder.conf.d` folder. After configuration is in place, we
can start the logstash forwarder system service.

Examples of monitored nodes can be found in `script-PLATFORM-monitored.yaml`
blueprints. Sample logstash forwarder configuration can be found in
[lsf.conf](resources/lsf.conf) file and sample node setup script in
[setup-lsf.sh](rersources/setup-lsf.sh).
