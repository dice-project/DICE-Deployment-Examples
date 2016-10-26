#!/bin/bash

PLATFORMS="fco openstack"

function list_platforms ()
{
  echo $(ls script-*.yaml | sed -r -e 's/script-(.+).yaml/\1/')
}

function usage ()
{
  cat <<EOF
Usage:

  $0 PLATFORM

  This will create blueprint.tar.gz archive that contains all required
  components for deploying script example.

Available platforms:
  $(list_platforms)
EOF

  exit 1
}


function main ()
{
  local tmp_folder=$(mktemp -d)

  # Next line is very important, works around a particularly annoying behavior
  # of Cloudify Manager that is quite painful to debug.
  chmod 755 $tmp_folder

  cp script-$1.yaml $tmp_folder/blueprint.yaml
  cp -r resources $tmp_folder
  tar -cvzf blueprint.tar.gz -C $(dirname $tmp_folder) $(basename $tmp_folder)

  rm -rf $tmp_folder
}

# Parameter check
[[ $# -ne 1 ]] && usage
[[ -f "script-$1.yaml" ]] || usage

main $1

exit 0
