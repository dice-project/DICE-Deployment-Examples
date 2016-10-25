#!/bin/bash

# Next two lines are needed because virtualenv does not support nesting and
# we would like to break free if we are running inside one right now
unset VIRTUALENV
export PATH=/usr/bin:$PATH

INSTALL_DIR=$HOME/data-parser

echo "Installing mock DATA parser dependencies ..."
sudo apt-get update -y
sudo apt-get install python-virtualenv -y

mkdir $INSTALL_DIR
virtualenv $INSTALL_DIR/venv
. $INSTALL_DIR/venv/bin/activate
pip install pika

echo "Installing mock data parser ..."
cp emitter.py $INSTALL_DIR

echo "Starting mock data parser ..."
nohup python $INSTALL_DIR/emitter.py $1 \
  < /dev/null                           \
  >> $INSTALL_DIR/emitter.out           \
  2>> $INSTALL_DIR/emitter.err          &

echo "All done"
