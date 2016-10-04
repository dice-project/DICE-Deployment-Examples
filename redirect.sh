#!/bin/bash

DEFAULT_BRANCH=tb-wip
BASE="http://dice-project.github.io/DICE-Deployment-Cloudify"
NEEDLE="$BASE/spec/([^/]+)/.*\\.yaml"
REPLACEMENT="$BASE/spec/\\1/__BRANCH__/plugin.yaml"

function usage ()
{
  cat <<EOF
USAGE:

 $0 BLUEPRINT [BRANCH | TAG]

This script can be used to update blueprint's import location, which can be
quite usefull when developing new functionality or creating releases.

If no branch or tag is specified, default branch 'tb-wip' is used.

If special name 'all' is used in place of BLUEPRINT, all blueprints will be
updated.


EXAMPLES:

  $0 blueprint.yaml 0.4.3  # Redirect blueprint.yaml to tag 0.4.3
  $0 blueprint.yaml        # Redirect blueprint.yaml to branch tb-wip
  $0 all            1.0.0  # Redirect all blueprints to tag 1.0.0

EOF
}

function main ()
{
  local branch=$DEFAULT_BRANCH blueprints f replacement

  [[ $# -lt 1 ]] && usage && exit 0

  [[ $# -gt 1 ]] && branch="$2"
  replacement=${REPLACEMENT/__BRANCH__/$branch}

  if [[ "$1" == "all" ]]
  then
    blueprints=$(git ls-files '*/*.yaml')
  else
    blueprints=$1
  fi

  for f in $blueprints
  do
    sed -i -re "s,$NEEDLE,$replacement," $f
  done
}

main "$@"
