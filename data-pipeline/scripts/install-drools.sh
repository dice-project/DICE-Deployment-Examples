#!/bin/bash

INSTALL_DIR=$HOME/drools

echo "Installing mock drools dependencies ..."
sudo apt-get update -y
sudo apt-get install python-virtualenv -y

# Next two lines are needed because virtualenv does not support nesting and
# we would like to break free if we are running inside one right now
unset VIRTUALENV
export PATH=/usr/bin:$PATH

mkdir $INSTALL_DIR
virtualenv $INSTALL_DIR/venv
. $INSTALL_DIR/venv/bin/activate
pip install pika cassandra-driver

echo "Installing mock drools ..."
cp transmitter.py $INSTALL_DIR

echo "Starting mock drools ..."
nohup python $INSTALL_DIR/transmitter.py $1 $2 \
  < /dev/null                                  \
  >> $INSTALL_DIR/transmitter.out              \
  2>> $INSTALL_DIR/transmitter.err             &

echo "All done"
