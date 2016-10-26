#!/bin/bash

for i in $(seq $1)
do
  echo "[$i] $2 to stdout" >&1
  echo "[$i] $3 to stderr" >&2
  sleep 1
done
