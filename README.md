# Blueprint examples for DICE deployment tool

This repository contains various working examples of OASIS TOSCA
blueprints. To test and run them, use the [DICE Deployment Service][dds].

[dds]: https://github.com/dice-project/DICE-Deployment-Service


# Notes on content

There are currently blueprints for two platforms provided: for OpenStack and
FCO. Template part of the blueprints is identical, since DICE TOSCA library
abstracts away the differences in this part of the blueprint.

Platforms have different requirements when it comes to imports and inputs,
since each platform needs to be configured separately.


# Deploying samples

In this section, we get our hands dirty and demonstrate how to deploy
different kinds of blueprints. We will assume that `dice-deploy-cli` tool is
in your search path. If this is not true, execute

    $ export PATH=/path/to/dice-tools:$PATH

This should take care of that. We will also assume that `dice-deploy-cli` is
already configured for usage. If not, execute

    $ dice-deploy-cli use ...
    $ dice-deploy-cli authenticate ...

You need to replace `...` with proper data. For more information on what data
commands expect, consult built-in help.


## Deploying standalone blueprints

Standalone blueprints have no bundled resources. Deploying such blueprints is
really easy, because all we need is blueprint YAML file.

Example of standalone blueprint would be `spark`. When we want to deploy it,
we execute

    $ dice-deploy-cli create "Apache Storm deployment"
    $ dice-deploy-cli deploy UUID storm/storm-openstack.yaml

Replace UUID placeholder in second command with output of the first command.
And this is it.


## Deploying blueprint with bundled resources

Deploying such blueprints is a bit more complicated, because we need to
prepare gzipped tarball that contains blueprint and resources. We will
demonstrate steps that are needed to deploy such blueprint on `script`
example.

First, we will move ourselves to `script`folder and then create new temporary
folder that will hold contents of tarball.

    $ cd script
    $ TMP_FOLDER=$(mktemp -d)
    $ chmod 755 $TMP_FOLDER
    $ echo $TMP_FOLDER
    /tmp/tmp.M5XxPuDt4M

Next, we will copy the YAML file and all resources that blueprint references
to this temporary folder, making sure that we place all resources into proper
subfolders to make sure paths, that are used in blueprint, can be resolved
relative to blueprint location. Note that YAML file that contains main
blueprint, needs to be named `blueprint.yaml` in order for DICE Deployment
Service to know where to start.

    $ cp script-openstack.yaml $TMP_FOLDER/blueprint.yaml
    $ cp -r resources $TMP_FOLDER

The layout should look something like this:

    $ tree $TMP_FOLDER
    /tmp/tmp.M5XxPuDt4M
    ├── blueprint.yaml
    └── resources
        └── test-script.sh

Now, we need to create tarball.

    $ tar -cvzf blueprint.tar.gz \
          -C $(dirname $TMP_FOLDER) $(basename $TMP_FOLDER)
    tmp.M5XxPuDt4M/
    tmp.M5XxPuDt4M/scripts/
    tmp.M5XxPuDt4M/scripts/test-script.sh
    tmp.M5XxPuDt4M/blueprint.yaml

After all this is done, we can remove temporary folder and upload the tarball
exactly the same way that we uploaded standalone blueprint.

    $ rm -rf $TMP_FOLDER
    $ unset TMP_FOLDER
    $ dice-deploy-cli create "Bash script test"
    $ dice-deploy-cli deploy UUID blueprint.tar.gz

And finally, we clean after ourselves.

    $ rm blueprint.tar.gz

Example `script` folder already contains `create-tar.sh` script that performs
tarball creation. Simply run it and then perform deploy as described above.


# Acknowledgement

This work is a result of the [DICE] project, which has received funding from
the [European Union’s Horizon 2020][H2020] research and innovation programme
under grant agreement No. 644869.

[DICE]: http://dice-h2020.eu/
[H2020]: http://ec.europa.eu/programmes/horizon2020/
