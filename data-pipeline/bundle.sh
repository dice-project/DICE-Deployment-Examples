#!/bin/bash

T=$(mktemp -d)
chmod 755 $T
cp blueprint.yaml $T/blueprint.yaml
cp -r resources scripts $T
tar -cvzf data-pipeline.tar.gz -C $(dirname $T) $(basename $T)
rm -rf $T
unset T
