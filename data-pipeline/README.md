# Posidonia use case

With the help of this use case we will demonstrate how to write a blueprint
that uses custom nodes with manually installed and configured software.


## General information

For this demonstration, we will model the following pipeline:

    .-------------.     .----------.     .--------.     .-----------.
    | data_parser +---->| rabbitmq +---->| drools +---->| cassandra |
    '-------------'     '----------'     '--------'     '-----------'

First three nodes will be installed by means of user supplied scripts and
the last node (Apache Cassandra) will be installed from the library that
DICE provides.

Since getting real components up and running is out of the scope for this demo,
we wrote our own mock `data_parser` and `drools` components. `data_parser` simply
sends `Hello` to RabbitMQ every ten seconds. `drools` waits for messages and
store them into Cassandra. Implementation of both mocks is really simple and
is available in `resources` subfolder.

We will assume that properly configured DICE Deployment Service is available
to us and will not bother ourselves with details of how this happened to be.
If you need help with this, consult [DICE Deployment Service] documentation.

[DICE Deployment Service]: https://github.com/dice-project/DICE-Deployment-Service

## Writing blueprint

In this document, we will use top-down approach and start building blueprint
first. This will allow us to focus on general layout that will serve as a
guide for when we start bothering ourselves with details.

So, first thing we need to do is setup `data_parser`, which is shown in the
following snippet.

    data_parser_vm:
      type: dice.hosts.Medium
    
    data_parser:
      type: dice.components.misc.ScriptRunner
      properties:
        script: scripts/install-data-parser.sh
        language: bash
        arguments:
          - get_attribute: [ rabbitmq, fqdn ]
        resources:
          - resources/emitter.py
      relationships:
        - type: dice.relationships.ContainedIn
          target: data_parser_vm
        - type: dice.relationships.Needs
          target: rabbitmq

First part simply prepares virtual machine and is not really interesting.
Second part represents our `data_parser` and contains some important
properties. Let us have a closer look at those properties and explain what
they mean.

Script property points to a file that will be executed when our software needs
to be installed. You can do almost anything from this script, since you can
run sudo with no password.

Arguments property contains array (with single element in this case) of
command line arguments that will be passed to script when being executed. We
use this property to connect our parser with RabbitMQ in this example.

Resources property holds array of paths to files that will be placed alongside
our installation script and can be used by the script. We placed our mock
software in this array, which makes it really easy to bundle it with
blueprint.

Relationships should be mostly self explanatory. First relationship instructs
orchestrator to place our `data_parser` into proper virtual machine and the
second relationship makes sure that our parser will be installed after
RabbitMQ server is already up and running.

Next, we need to prepare RabbitMQ. For this purpose, we write down next piece
of code:

    rabbitmq_firewall:
      type: dice.firewall_rules.Base
      properties:
        rules:
          - remote_ip_prefix: 0.0.0.0/0
            port: 4369
          - remote_ip_prefix: 0.0.0.0/0
            port: 25672
          - remote_ip_prefix: 0.0.0.0/0
            port: 5672
          - remote_ip_prefix: 0.0.0.0/0
            port: 5671
          - remote_ip_prefix: 0.0.0.0/0
            port: 15672
    
    rabbitmq_vm:
      type: dice.hosts.Medium
      relationships:
        - type: dice.relationships.ProtectedBy
          target: rabbitmq_firewall
    
    rabbitmq:
      type: dice.components.misc.ScriptRunner
      properties:
        script: scripts/install-rabbitmq.sh
        language: bash
      relationships:
        - type: dice.relationships.ContainedIn
          target: rabbitmq_vm

Here we see something new: a firewall definition. Since we would like to
access RabbitMQ server, we need to make holes in firewall. In the example
above, we unblocked most common RabbitMQ ports for everybody.

To actually use this firewall, we need to connect virtual machine with
firewall definition. We did this by adding `dice.relationships.ProtectedBy`
relationship to `rabbitmq_vm`.

Last part should be familiar to us now. Because installation script for
RabbitMQ does not need any inputs or additional resources, `arguments` and
`resources` properties and not present at all.

For drools installation, we need to place next snippet into blueprint:

    drools_vm:
      type: dice.hosts.Medium
    
    drools:
      type: dice.components.misc.ScriptRunner
      properties:
        script: scripts/install-drools.sh
        arguments:
          - get_attribute: [ rabbitmq,       fqdn ]
          - get_attribute: [ cassandra_seed, fqdn ]
        resources:
          - resources/transmitter.py
      relationships:
        - type: dice.relationships.ContainedIn
          target: drools_vm
        - type: dice.relationships.Needs
          target: rabbitmq
        - type: dice.relationships.Needs
          target: cassandra_worker

The only new thing here is demonstration of how to pass multiple arguments to
installation script. In this case, we pass RabbitMQ and Cassandra addresses.

Last part that we need to provide is Cassandra cluster. Because Apache
Cassandra is one of the things that is natively supported by DICE TOSCA
library, we do not have to write much down.

    cassandra_firewall:
      type: dice.firewall_rules.cassandra.Common
    
    cassandra_seed_vm:
      type: dice.hosts.Medium
      relationships:
        - type: dice.relationships.ProtectedBy
          target: cassandra_firewall
    
    cassandra_seed:
      type: dice.components.cassandra.Seed
      relationships:
        - type: dice.relationships.ContainedIn
          target: cassandra_seed_vm
    
    cassandra_worker_vm:
      type: dice.hosts.Medium
      instances:
        deploy: 1
      relationships:
        - type: dice.relationships.ProtectedBy
          target: cassandra_firewall
    
    cassandra_worker:
      type: dice.components.cassandra.Worker
      relationships:
        - type: dice.relationships.ContainedIn
          target: cassandra_worker_vm
        - type: dice.relationships.cassandra.ConnectedToSeed
          target: cassandra_seed

There is a couple of interesting things to be seen here. First, because
Cassandra is built-in type, we do not need to write firewall rules ourselves.
We simply use proper type and that is it. Second, creating a larger cluster is
just a simple matter of changing `instances.deploy` number to something
larger. In our case, we created simple cluster with only two nodes for the
sake of simplicity.

And we are done with blueprint. There are some minor details that we left out
in this description, but they are all present in blueprint that is provided
alongside this document.


## Writing scripts

Now that we have a general layout, we need to actually write down the scripts
that we referenced in blueprint. Scripts should be placed relative to the main
blueprint file. For example, in `data_parser` node we referenced script as
`scripts/install-data-parser.sh`, which means that we must create directory
`scripts` alongside blueprint and place `install-data-parser.sh` inside.

Content of this script is really free form, since we are free to do just about
anything. But there is one catch: if we would like to create and use python's
virtual environment, we need to break out of any preexisting virtual
environment. Fortunately for us, this is really simple to achieve and is
demonstrated in sample installation script. Now let us write this installation
script for parser:

    #!/bin/bash
    
    # Next two lines are needed because virtualenv does not support nesting and
    # we would like to break free if we are running inside one right now
    unset VIRTUALENV
    export PATH=/usr/bin:$PATH
    
    INSTALL_DIR=$HOME/data-parser
    
    echo "Installing mock parser dependencies ..."
    sudo apt-get update -y
    sudo apt-get install python-virtualenv -y
    
    mkdir $INSTALL_DIR
    virtualenv $INSTALL_DIR/venv
    . $INSTALL_DIR/venv/bin/activate
    pip install pika
    
    echo "Installing mock parser ..."
    cp emitter.py $INSTALL_DIR
    
    echo "Starting mock parser ..."
    nohup python $INSTALL_DIR/emitter.py $1 \
      < /dev/null                           \
      >> $INSTALL_DIR/emitter.out           \
      2>> $INSTALL_DIR/emitter.err          &
    
    echo "All done"

Most of the stuff here is your standard "let us invent our own ansible"
content. But there are two interesting lines in there.

First interesting line contains `cp emitter.py $INSTALL_DIR`. We can execute
this line because we placed `emitter.py` inside resources array and
orchestrator placed it alongside our main script.

Second interesting line (or quartet of lines) is the one with the `nohup`
command. Why do we need to use `nohup` here? Because we want to have our
emitter running in the background even when our script terminates. And to be
on the safe side of things, we also redirect all opened streams before going
into the background. Last thing that is interesting here that `$1`. This is
the first argument that our installation script received and contains
RabbitMQ's address. Here, we pass this address to the application that will
actually use it.

It would be better to write an upstart or SysV init job for such cases, but
for demo purposes, quick-and-dirty method will suffice.

Other two installation scripts are pretty similar to this one and it does not
make sense to make this document even longer by describing them, so we skip to
the resources creation.


## Creating resources

Like scripts, resources are also free form and their paths have to be
relatively resolvable against main blueprint file. Note that relative path has
NO effect on final placement, it merely states that we would like to have this
file present in the same folder as the main script when being executed. This
also means that all of the resources should have unique names. In case of
duplicates, the last entry in resources array will overwrite all others.

Let us have a look at `emitter.py` script referenced in a resource in the
`data_parser` node template. As we can see from the previous listing, this
script is first installed by the `install-data-parser.sh` script, and then
executed in the background.

    import sys
    import time
    import pika
    
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(sys.argv[1])
    )
    channel = connection.channel()
    channel.queue_declare(queue="hello")
    
    while True:
        channel.basic_publish(exchange="", routing_key="hello", body="Hello")
        time.sleep(10)

This is pretty standard hello-world program for RabbitMQ. The only really
"novel" thing here is connection initialization. Instead of having a fixed
RabbitMQ address, we use first command line argument.

Again, other resource is pretty much exactly the same, so we will stop talking
about this here and skip to blueprint preparation.


## Preparing blueprint for upload

Preparing blueprint tarball follows the standard procedure that has been
described in [top level readme file][top-readme]. But for the sake of
completeness, we provide a shell commands that can be used to create tarball.

    $ T=$(mktemp -d)
    $ chmod 755 $T
    $ cp -r blueprint.yaml resources scripts $T
    $ tar -cvzf blueprint.tar.gz -C $(dirname $T) $(basename $T)
    $ rm -rf $T
    $ unset T
