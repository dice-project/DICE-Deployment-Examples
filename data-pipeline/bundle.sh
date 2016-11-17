#!/bin/bash

for PLATFORM in openstack fco
do
	T=$(mktemp -d)
	chmod 755 $T
	cp blueprint-$PLATFORM.yaml $T/blueprint.yaml
	cp -r resources scripts $T
	tar -cvzf data-pipeline-$PLATFORM.tar.gz -C $(dirname $T) $(basename $T)
	rm -rf $T
	unset T
done
