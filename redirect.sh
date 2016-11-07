#!/bin/bash

DEFAULT_BRANCH=tb-wip
BASE="http://dice-project.github.io/DICE-Deployment-Cloudify"
NEEDLE="$BASE/spec/([^/]+)/__SRC__/plugin\\.yaml"
REPLACEMENT="$BASE/spec/\\1/__BRANCH__/plugin.yaml"

function usage ()
{
  cat <<EOF
USAGE:

 $0 BLUEPRINT [BRANCH | TAG] [BRANCH | TAG]

This script can be used to update blueprint's import location, which can be
quite usefull when developing new functionality or creating releases.

If no branch or tag is specified, default branch '$DEFAULT_BRANCH' is used.

If special name 'all' is used in place of BLUEPRINT, all blueprints will be
updated.

If second branch or tag is specified, only blueprints that use second branch
will be redirected to new branch.


EXAMPLES:

  $0 blueprint.yaml 0.4.3  # Redirect blueprint.yaml to tag 0.4.3
  $0 blueprint.yaml        # Redirect blueprint.yaml to branch $DEFAULT_BRANCH
  $0 all 1.0.0             # Redirect all blueprints to tag 1.0.0
  $0 all 1.0.0 develop     # Redirect blueprints that use develop to 1.0.0

EOF
}

function main ()
{
  local branch=$DEFAULT_BRANCH src='[^/]+' blueprints f replacement

  [[ $# -lt 1 ]] && usage && exit 0

  [[ $# -gt 1 ]] && branch="$2"
  [[ $# -gt 2 ]] && src="$3"
  replacement=${REPLACEMENT/__BRANCH__/$branch}
  needle=${NEEDLE/__SRC__/$src}

  if [[ "$1" == "all" ]]
  then
    blueprints=$(git ls-files '*/*.yaml')
  else
    blueprints=$1
  fi

  for f in $blueprints
  do
    sed -i -re "s,$needle,$replacement," $f
  done
}

main "$@"
