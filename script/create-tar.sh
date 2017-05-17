#!/bin/bash

function main ()
{
  local tmp_folder=$(mktemp -d)

  # Next line is very important, works around a particularly annoying behavior
  # of Cloudify Manager that is quite painful to debug.
  chmod 755 $tmp_folder

  cp script.yaml $tmp_folder/blueprint.yaml
  cp -r resources $tmp_folder
  tar -cvzf blueprint.tar.gz -C $(dirname $tmp_folder) $(basename $tmp_folder)

  rm -rf $tmp_folder
}

main $1

exit 0
