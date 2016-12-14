# Deploying blueprint

These instructions demonstrate how to deploy ScyllaDB using Cloudify.


## Prerequisites

First, we need to install cloudify command-line tools. This is done by
executing

    mkdir ~/scylla-deploy && cd scylla-deploy
    virtualenv -p python2 venv
    . venv/bin/activate
    pip install cloudify==3.4

Next, we need to point client to our manager. If manager is accessible at
56.78.91.23 and credentials are set to `admin`/`pass`, we would run

    cfy init
    export CLOUDIFY_USERNAME=admin
    export CLOUDIFY_PASSWORD=pass
    cfy use -t 56.78.91.23

Replace username and password with real ones.

To check if everything is working, execute

    cfy status

If this prints some stats about Cloudify Manager, client is properly
configures.


## Preparing blueprint inputs

In order to successfully deploy scylla blueprint, we need to provide inputs
that are required by DICE TOSCA library. Make new file
`~/scylla-deploy/inputs.yaml` and paste next lines into it:

    large_image_id: ca290f2d-5163-483b-9dd5-fafe21517c0a
    large_flavor_id: 93e4960e-9b6d-454f-b422-0d50121b01c6
    agent_user: centos
    # This is not relevant in this case, but need to be present in order to
    # satisfy DICE TOSCA Library validation
    medium_image_id: dummy
    medium_flavor_id: dummy
    small_image_id: dummy
    small_flavor_id: dummy
    dns_server: dummy

Now modify `large_image_id` and `large_flavor_id` to fit your needs. Just make
sure image id points to CentOS 7 image.


## Deploying blueprint

Copy `scylla-openstack.yaml` to `~/scylla-deploy` folder and execute:

    cfy blueprints upload -p scylla-openstack.yaml -b scylla
    cfy deployments create -b scylla -d scylla -i inputs.yaml
    cfy executions start -w install -d scylla -l

After about 10-20 minutes, new ScyllaDB cluster should be ready.
