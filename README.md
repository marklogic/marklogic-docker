# Table of contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Supported tags](#supported-tags)
* [Architecture reference](#architecture-reference)
* [MarkLogic](#marklogic)
* [Using this Image](#using-this-image)
* [Configuration](#configuration)
* [Clustering](#clustering)
* [Upgrading to the latest MarkLogic Docker Release](#upgrading-to-the-latest-marklogic-docker-release)
* [Backing Up and Restoring a Database](#backing-up-and-restoring-a-database)
* [Debugging](#debugging)
* [Clean up](#clean-up)
* [Image Tag](#image-tag)
* [Container_Runtime_Detection](#container-runtime-detection)
* [Known Issues and Limitations](#known-issues-and-limitations)

## Introduction

This README serves as a technical guide for using MarkLogic Docker and MarkLogic Docker images. These tasks are covered in this README:

* How to use images to setup initialized/uninitialized MarkLogic servers
* How to use Docker compose and Docker swarm to setup single/multi node MarkLogic cluster
* How to join a TLS(HTTPS) enabled cluster
* How to enable security using Docker secrets
* How to mount volumes for Docker containers
* How to upgrade to the latest MarkLogic Docker release  
* How to back up and restore a database
* How to clean up MarkLogic Docker containers and resources

## Prerequisites

Note: In order to use the MarkLogic Image you need to request the Developer License. Refer to details on <https://developer.marklogic.com/free-developer/> for requesting it.

* All the examples in this readme use the latest MarkLogic Server Docker image.
* Examples in this document use Docker Engine and Docker CLI to create and manage containers. Follow the documentation for instructions on how to install Docker: see Docker Engine (<https://docs.docker.com/engine/>)
* To access the MarkLogic Admin interface and App Servers in our examples, you need a desktop browser. See "Supported Browsers" in the [support matrix](https://developer.marklogic.com/products/support-matrix/) for a list of supported browsers.

## Supported tags

Note: MarkLogic Server Docker images follow a specific tagging format: `{ML release version}-{platform}`

All Supported Tags: [https://hub.docker.com/r/marklogicdb/marklogic-db/tags](https://hub.docker.com/r/marklogicdb/marklogic-db/tags)

## Architecture reference

Docker images are maintained by MarkLogic. Send feedback to the MarkLogic Docker team: <docker@marklogic.com>

Supported Docker architectures: x86_64

Base OS: UBI, UBI-rootless and CentOS

Published image artifact details: <https://github.com/marklogic/marklogic-docker>, <https://hub.docker.com/r/marklogicdb/marklogic-db>

## MarkLogic

[MarkLogic Server](http://www.marklogic.com/) is a multi-model database that has both NoSQL and trusted enterprise data management capabilities. It is the most secure multi-model database, and it’s deployable in any environment.

MarkLogic documentation is available at [http://docs.marklogic.com](https://docs.marklogic.com/).

## Using this Image

With this image, you have the option to either create an initialized or an uninitialized MarkLogic Server.

* Initialized: admin credentials are set up as part of container startup process.
* Unintialized: admin credentials are created by the user after MarkLogic has started. To create the credentials you can use the GUI (see the MarkLogic Installation documentation: <https://docs.marklogic.com/guide/installation/procedures#id_84772>) or you can use APIs (see the scripting documentation: <https://docs.marklogic.com/10.0/guide/admin-api/cluster>).

### Initialized MarkLogic Server

For an initialized MarkLogic Server, admin credentials are required to be passed in while creating the Docker container. The Docker container will have MarkLogic Server installed and initialized, and databases and app servers created. A security database will be created to store user data, roles, and other security information. MarkLogic Server credentials, passed in as environment variable parameters while running a container, will be stored as part of the admin user in the security database. These admin credentials can be used to access MarkLogic Server Admin interface on port 8001 and other app servers with their respective ports.

To create an initialized MarkLogic Server, pass in the environment variables MARKLOGIC_ADMIN_USERNAME and MARKLOGIC_ADMIN_PASSWORD, and replace {insert admin username}/{insert admin password} with actual values for admin credentials. Use the optional environment variable MARKLOGIC_WALLET_PASSWORD and REALM to set the wallet password and authentication realm of the admin user. If not provided, the wallet-password will default to the value set for admin-password and realm will be set to public. Optionally, you can pass license information in `{insert license}`/`{insert licensee}` to apply your MarkLogic license. To do this, run this this command:

```bash
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e MARKLOGIC_WALLET_PASSWORD={insert wallet password} \
     -e REALM={insert authentication realm} \
     -e LICENSE_KEY="{insert license}" \
     -e LICENSEE="{insert licensee}" \
     marklogicdb/marklogic-db
```

Example run:

```bash
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \ 
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME='admin' \
     -e MARKLOGIC_ADMIN_PASSWORD='Areally!PowerfulPassword1337' \
     marklogicdb/marklogic-db
```

Wait about a minute for MarkLogic Server to initialize before checking the ports. To verify the successful installation and initialization, log into the MarkLogic Server Admin Interface using the admin credentials used in the command above. Go to <http://localhost:8001>. You can also verify the configuration by following the procedures outlined in the MarkLogic Server documentation. See the MarkLogic Installation documentation [here](https://docs.marklogic.com/guide/installation/procedures#id_84772).

### Uninitialized MarkLogic Server

For an uninitialized MarkLogic Server, admin credentials or license information are not required while creating the container. The Docker container will have MarkLogic Server installed and ports exposed for app servers as specified in the run command. Users can access the MarkLogic Admin Interface at <http://localhost:8001> and manually initialize the MarkLogic Server, create the admin user, databases, and install the license. See the MarkLogic Installation documentation [here](https://docs.marklogic.com/guide/installation/procedures#id_84772).

To create an uninitialized MarkLogic Server with [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/), run this command:

```bash
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     marklogicdb/marklogic-db
```

The example output will contain a hash of the image ID: `f484a784d99838a918e384eca5d5c0a35e7a4b0f0545d1389e31a65d57b2573d`

Wait for about a minute, before going to the MarkLogic Admin Interface at <http://localhost:8001>. If the MarkLogic container has started successfully on Docker, you should see a configuration screen allowing you to initialize the server as shown at: <https://docs.marklogic.com/guide/installation/procedures#id_60220>.  

Note that the examples in this document can interfere with one another.  We recommend that you stop all containers before running the examples. See the [Clean up](#clean-up) section at the end of this document for more details.

### Persistent Data Volume

A MarkLogic Docker container stores data in `/var/opt/MarkLogic` which is persistent in a Docker managed volume. We recommend that you use named volumes instead of bind mounts as suggested by the [Docker documentation](https://docs.docker.com/storage/volumes/).

The following command will list previously created volumes:

```bash
docker volume ls
```

If the instructions in the **Using this Image** section are followed, the previous command should output at least two volume identifiers:

```text
DRIVER    VOLUME NAME
local     0f111f7336a5dd1f63fbd7dc07740bba8df684d70fdbcd748899091307c85019
local     1b65575a84be319222a4ff9ba9eecdff06ffb3143edbd03720f4b808be0e6d18
```

The following command uses a named volume and named container in order to make management easier:

```bash
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     --name MarkLogic_cont_1 \
     --mount src=MarkLogic_vol_1,dst=/var/opt/MarkLogic \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     marklogicdb/marklogic-db
```

Above command will start a Docker container `MarkLogic_cont_1` running MarkLogic Server and associate the named Docker volume `MarkLogic_vol_1` with it.

Run this command to check the volumes:

```bash
docker volume ls
```

The output from should now contain a named volume `MarkLogic_vol_1`:

```text
DRIVER    VOLUME NAME
local     0f111f7336a5dd1f63fbd7dc07740bba8df684d70fdbcd748899091307c85019
local     1b65575a84be319222a4ff9ba9eecdff06ffb3143edbd03720f4b808be0e6d18
local     MarkLogic_vol_1
```

## Configuration

MarkLogic Server Docker containers are configured using a set of environment variables.

| env var                       | value                           | required                          | default   | description                                        |
| ------------------------------- | --------------------------------- | ----------------------------------- | ----------- | ---------------------------------------------------- |
| MARKLOGIC_INIT                | true                            | no                                |           | when set to true, will initialize MarkLogic           |
| MARKLOGIC_ADMIN_USERNAME      | jane_doe                        | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin user                           |
| MARKLOGIC_ADMIN_PASSWORD      | pass                            | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin password  
| MARKLOGIC_WALLET_PASSWORD      | pass                           | no                                | admin-password       | set MarkLogic Server wallet password
| REALM                          | public                         | no                                | public    | sets authentication realm of the admin user             |
| MARKLOGIC_ADMIN_USERNAME_FILE | secret_username                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin username via Docker secrets    |
| MARKLOGIC_ADMIN_PASSWORD_FILE | secret_password                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin password via Docker secrets    |
| MARKLOGIC_WALLET_PASSWORD_FILE | secret_wallet_password         | no                                | n/a       | set MarkLogic Server wallet password via Docker secrets    |
| MARKLOGIC_JOIN_CLUSTER        | true                            | no                                |           | will join cluster via MARKLOGIC_BOOTSTRAP_HOST          |
| MARKLOGIC_JOIN_TLS_ENABLED        | false                            | no                                |           | will join cluster using TLS and MARKLOGIC_JOIN_CACERT_FILE          |
| MARKLOGIC_JOIN_CACERT_FILE        | CA certificate/ certificate chain file                            | no                                |           | will join cluster using TLS and certificate          |
| MARKLOGIC_BOOTSTRAP_HOST           | someother.bootstrap.host.domain | no                                | bootstrap | must define if not connecting to default bootstrap |
| MARKLOGIC_GROUP           | dnode                     | no                                | n/a       | will join the host to the given MarkLogic group                  |
| LICENSE_KEY           | license key                     | no                                | n/a       | set MarkLogic license key                          |
| LICENSEE            | licensee information            | no                                | n/a       | set MarkLogic licensee information                 |
|INSTALL_CONVERTERS   | true                            | no                                | false     | Installs converters for the client if they are not already installed |
|OVERWRITE_ML_CONF   | true                            | no                                | false     | Deletes and rewrites `/etc/marklogic.conf` with the passed in env variables if set to true |

Note: MARKLOGIC_JOIN_TLS_ENABLED and MARKLOGIC_JOIN_CACERT_FILE should be used only for nodes joining the cluster. These two parameters will be ignored for bootstrap host configurations.

MarkLogic Server also can be configured through a configuration file on the image at `/etc/marklogic.conf`. To change the configuration file, pass in the parameter `OVERWRITE_ML_CONF` set to `true` The following env variables can also be written to the `/etc/marklogic.conf` file if the parameter is set.

 | env var                       | value                           | required                          | default   | description                                        |
| ------------------------------- | --------------------------------- | ----------------------------------- | ----------- | ---------------------------------------------------- |
| TZ      | /etc/localtime                        | no | n/a       | Timezone information setting for marklogic                           |                      |
| MARKLOGIC_ADMIN_USERNAME                | jane_doe                            | required if MARKLOGIC_INIT is set                                |   n/a        | set MarkLogic Server admin user           |
| MARKLOGIC_ADMIN_PASSWORD      | pass                        | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin password
| MARKLOGIC_WALLET_PASSWORD      | pass                        | no | admin-password       | set MarkLogic Server wallet password
| REALM      | public                        | no | public       | set authentication realm                           |
| MARKLOGIC_LICENSEE      | licensee information                         | no | n/a       | set MarkLogic licensee information                           |
| MARKLOGIC_LICENSE_KEY                | license key                             | no                                |   n/a        | set MarkLogic license key             |
| ML_HUGEPAGES_TOTAL      | 1000                        | no | n/a       | set the number of huge pages marklogic can utilize                          |

### Advanced Configuration

The following environment variables are only useful when building and extending the current docker image. For instance, setting `MARKLOGIC_USER` only will work if a user is set up and configured in the image.

| env var                       | value                           | required                          | default   | description                                        |
| ------------------------------- | --------------------------------- | ----------------------------------- | ----------- | ---------------------------------------------------- |
| MARKLOGIC_USER                | daniel                            | no                                |     n/a      | The username running MarkLogic within the docker container           |
| MARKLOGIC_DISABLE_JVM      | 0                        | no | n/a       | disable the JVM for MarkLogic
| JAVA_HOME                | /var/opt/java                            | no                                |  n/a         | set the java home location for MarkLogic           |
| CLASSPATH      | /var/opt/class/path                        | no| n/a       | set the java env class path                          |
| MARKLOGIC_PID_FILE      | /var/run/MarkLogic.pid                        | no| n/a       | The process ID file                         |
| MARKLOGIC_UMASK      | 022                        | no | n/a       | The permissions granted to MarkLogic through umask                          |

**IMPORTANT:** The use of [Docker secrets](https://docs.docker.com/engine/swarm/secrets/) is supported in the MarkLogic Docker image marklogicdb/marklogic-db:10.0-7.3-centos-1.0.0-ea onwards and will not work with older versions of the Docker EA image. The Docker compose examples that follow use secrets. If you want to use these examples with an older version of the image, you need to update the examples to use environment variables instead of secrets.

### Configuring swap space

MarkLogic recommends that swap space be configured for production deployments to reduce the possibility of ‘out of memory’ errors. For more details, see [MarkLogic recommendations for swap space](https://help.marklogic.com/knowledgebase/article/View/21/19/swap-space-requirements) and [configuring "swappiness"](https://help.marklogic.com/Knowledgebase/Article/View/linux-swappiness).

In Docker, the amount of memory and swap space that are available to MarkLogic Server can be controlled using the "--memory" and "--memory-swap" settings. See the Docker documentation [--memory-swap-details](https://docs.docker.com/config/containers/resource_constraints/#--memory-swap-details) for more details. For example, if you want to run a MarkLogic container with 64GB of memory and 32GB of swap, you would specify the following with your docker run command:

```text
--memory="64g" --memory-swap="96g"
```

If you want to limit memory to 64GB but allow MarkLogic Server to use swap space (up to the amount available on host system), specify the following with your docker run command:

```text
--memory="64g" --memory-swap="-1"
```

To allow MarkLogic Server to use unlimited memory and swap space (up to the amount available on the host system), do not specify either "--memory" or "--memory-swap".

### Configuring HugePages

By default, if HugePages are configured on the host, the MarkLogic instance running in a container will attempt to allocate up to 3/8 of the container memory limit as HugePages. For example, consider a host with 128GB of RAM, 48GB HugePages, and running two MarkLogic containers, each with 64GB memory limit. The MarkLogic instance in each container will only allocate up to 24GB in HugePages (3/8 * 64GB).

You can change the number of HugePages available to each MarkLogic container by setting the `ML_HUGEPAGES_TOTAL` environment variable. Set the variable for each MarkLogic container to the desired number of HugePages. For example, to disable the HugePages for specific container, specify the following with your Docker run command:

```text
-e ML_HUGEPAGES_TOTAL=0
```

## Clustering

MarkLogic Server Docker containers ship with a small set of scripts, making it easy to create clusters. See the [MarkLogic documentation](https://docs.marklogic.com/guide/concepts/clustering) for more about clusters. The following three examples show how to create MarkLogic Server clusters with Docker containers. The first two use Docker compose scripts to create one-node and three-node clusters. See the documentation for [Docker compose](https://docs.docker.com/compose/) for more details. The third example demonstrates a container setup on separate VMs.

The credentials for the admin user are configured using Docker secrets, and are stored in `mldb_admin_username.txt`, `mldb_admin_password.txt`, and `mldb_wallet_password.txt` files.

### Single node MarkLogic Server on a single VM

Single node configurations are used primarily on a development machine with a single user.

Create these files on your host machine: `marklogic-single-node.yaml`, `mldb_admin_username.txt`, `mldb_admin_password.txt`, and `mldb_wallet_password.txt`. Run the example Docker commands from the same directory that the files were created.

**marklogic-single-node.yaml**

```YAML
#Docker compose file sample to setup single node cluster
version: '3.6'
services:
    bootstrap:
      image: marklogicdb/marklogic-db
      container_name: bootstrap
      hostname: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_WALLET_PASSWORD_FILE=mldb_wallet_password
        - REALM=public
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_1n_vol1:/var/opt/MarkLogic
      secrets:
          - mldb_admin_username
          - mldb_admin_password
          - mldb_wallet_password
      ports:
        - 8000-8010:8000-8010
        - 7997:7997
      networks:
      - external_net
secrets:
  mldb_admin_username:
    file: ./mldb_admin_username.txt
  mldb_admin_password:
    file: ./mldb_admin_password.txt
  mldb_wallet_password:
    file: ./mldb_wallet_password.txt
networks:
  external_net: {}
volumes:
  MarkLogic_1n_vol1:
```

**mldb_admin_username.txt**

```text
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

{insert admin username}
```

**mldb_admin_password.txt**

```text
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

{insert admin password}
```

**mldb_wallet_password.txt**

```text
#This file will contain the MARKLOGIC_WAALET_PASSWORD value

{insert wallet password}
```

Once the files are ready, run this command to start the MarkLogic Server container.

```text
docker-compose -f marklogic-single-node.yaml up -d
```

The previous command starts a container running MarkLogic Server named "bootstrap".

Run this next command to verify if the container is running:

```text
docker ps
```

If the containers are running correctly, this command lists all the Docker containers running on the host.

After the container is initialized, you can access the MarkLogic Query Console on <http://localhost:8000> and the MarkLogic Admin Interface on <http://localhost:8001>. These ports can also be accessed externally via your hostname or IP address.

### Three node cluster on a single VM

The following is an example of a three-node MarkLogic server cluster created using Docker compose. Create these files on your host machine:  `marklogic-multi-node.yaml`, `mldb_admin_username.txt`, and `mldb_admin_password.txt`. Run example Docker commands from the same directory where the files created.

**marklogic-multi-node.yaml**

```YAML
#Docker compose file sample to setup a three node cluster
version: '3.6'
services:
    bootstrap_3n:
      image: marklogicdb/marklogic-db
      container_name: bootstrap_3n
      hostname: bootstrap_3n
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol1:/var/opt/MarkLogic
      secrets:
          - mldb_admin_password
          - mldb_admin_username
      ports:
        - 7100-7110:8000-8010
        - 7197:7997
      networks:
      - external_net
    node2:
      image: marklogicdb/marklogic-db
      container_name: node2
      hostname: node2
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - MARKLOGIC_BOOTSTRAP_HOST=bootstrap_3n
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol2:/var/opt/MarkLogic
      secrets:
        - mldb_admin_password
        - mldb_admin_username
      ports:
        - 7200-7210:8000-8010
        - 7297:7997
      depends_on:
      - bootstrap_3n
      networks:
      - external_net
    node3:
      image: marklogicdb/marklogic-db
      container_name: node3
      hostname: node3
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - MARKLOGIC_BOOTSTRAP_HOST=bootstrap_3n
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol3:/var/opt/MarkLogic
      secrets:
        - mldb_admin_password
        - mldb_admin_username
      ports:
        - 7300-7310:8000-8010
        - 7397:7997
      depends_on:
      - bootstrap_3n
      networks:
      - external_net
secrets:
  mldb_admin_password:
    file: ./mldb_admin_password.txt
  mldb_admin_username:
    file: ./mldb_admin_username.txt
networks:
  external_net: {}
volumes:
  MarkLogic_3n_vol1:
  MarkLogic_3n_vol2:
  MarkLogic_3n_vol3:
```

**mldb_admin_username.txt**

```text
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

{insert admin username}
```

**mldb_admin_password.txt**

```text
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

{insert admin password}
```

Once the files have been created, run the following command to start the MarkLogic Server container:

```text
docker-compose -f marklogic-multi-node.yaml up -d
```

This command will start three Docker containers running MarkLogic Server, named "bootstrap_3n", "node2" and, "node3".

Run this command to verify if the containers are running:

```bash
docker ps
```

This command lists all the Docker containers running on the host.

As in the previous single-node example, each node of the cluster can be accessed with localhost or host machine IP address. The MarkLogic Query Console and MarkLogic Admin UI ports for each container will be different. The ports are defined in the compose file created previously: <http://localhost:7101>, <http://localhost:7201>, <http://localhost:7301>, etc.

#### Using ENV for admin credentials in Docker compose

In the previous examples, Docker secrets files were used to specify admin credentials for the MarkLogic Server. If your environment prevents the use of Docker secrets, you can use environmental variables. This approach is less secure, but it is commonly used in development environments. This is **not** recommended for production environments. In order to use these environment variables in the Docker compose files, remove the secrets section at the end of the Docker compose yaml file, and remove the secrets section in each node. Then replace the MARKLOGIC_ADMIN_USERNAME_FILE/MARKLOGIC_ADMIN_PASSWORD_FILE/MARKLOGIC_WALLET_PASSWORD_FILE variables with MARKLOGIC_ADMIN_USERNAME/MARKLOGIC_ADMIN_PASSWORD/MARKLOGIC_WALLET_PASSWORD and provide the appropriate values.

Using Docker secrets, username and password information are secured when transmitting the sensitive data from Docker host to Docker containers. To prevent any attacks, the login information is not available as an environment variable. However, these values are stored in a text file and persisted in an in-memory file system inside the container. We recommend that you delete the Docker secrets information once the cluster is up and running.

#### How to use Docker Secrets with Docker Stack

1. Run this command to initialize the swarm setup:

```bash
  $docker swarm init
```

2. Create docker secrets using the following commands:

* Create mldb_admin_username_v1.txt file to add the mldb_admin_username_v1 secret for the admin username using the following command:

```bash
  $docker secret create mldb_admin_username_v1 mldb_admin_username_v1.txt
```

* Create mldb_admin_password_v1.txt file to add the mldb_admin_password_v1 secret for the admin password using the following command:

```bash
  $docker secret create mldb_admin_password_v1 mldb_admin_password_v1.txt
```

* Create mldb_wallet_password_v1.txt file to add the mldb_wallet_password_v1 secret for the wallet password using the following command:

```bash
  $docker secret create mldb_wallet_password_v1 mldb_wallet_password_v1.txt
```

3. Create marklogic-multi-node.yaml using below:

```YAML
version: '3.6'
services:
    bootstrap:
      image: marklogicdb/marklogic-db
      hostname: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_WALLET_PASSWORD_FILE=mldb_wallet_password
        - REALM=public
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol1:/var/opt/MarkLogic
      secrets:
          - source: mldb_admin_username_v1
            target: mldb_admin_username
          - source: mldb_admin_password_v1
            target: mldb_admin_password
          - source: mldb_wallet_password_v1
            target: mldb_wallet_password
      ports:
        - 7100-7110:8000-8010
        - 7197:7997
      networks:
      - external_net
    node2:
      image: marklogicdb/marklogic-db
      hostname: node2
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_WALLET_PASSWORD_FILE=mldb_wallet_password
        - REALM=public
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol2:/var/opt/MarkLogic
      secrets:
          - source: mldb_admin_username_v1
            target: mldb_admin_username
          - source: mldb_admin_password_v1
            target: mldb_admin_password
          - source: mldb_wallet_password_v1
            target: mldb_wallet_password
      ports:
        - 7200-7210:8000-8010
        - 7297:7997
      depends_on:
      - bootstrap
      networks:
      - external_net
    node3:
      image: marklogicdb/marklogic-db
      hostname: node3
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_WALLET_PASSWORD_FILE=mldb_wallet_password
        - REALM=public
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol3:/var/opt/MarkLogic
      secrets:
          - source: mldb_admin_username_v1
            target: mldb_admin_username
          - source: mldb_admin_password_v1
            target: mldb_admin_password
          - source: mldb_wallet_password_v1
            target: mldb_wallet_password
      ports:
        - 7300-7310:8000-8010
        - 7397:7997
      depends_on:
      - bootstrap
      networks:
      - external_net
secrets:
  mldb_admin_username_v1:
    external: true
  mldb_admin_password_v1:
    external: true
  mldb_wallet_password_v1:
    external: true
networks:
  external_net: {}
volumes:
  MarkLogic_3n_vol1:
  MarkLogic_3n_vol2:
  MarkLogic_3n_vol3:
```

4. Use the Docker stack command to deploy the cluster:

```bash
  $docker stack deploy -c marklogic-multi-node.yaml mlstack
```

All the cluster nodes will now be up and running.
Now that the nodes have been initialized, we rotate the secrets files to overwrite the initial secrets files.

5. Create docker secrets v2 using these commands:

* Create mldb_admin_username_v2.txt file and use the following command to add a new Docker secret for the admin username:

```bash
  $docker secret create mldb_admin_username_v2 mldb_admin_username_v2.txt
```

* Create mldb_admin_password_v2.txt and use the following command to add a new Docker secret for the admin password:

```bash
  $docker secret create mldb_admin_password_v2 mldb_admin_password_v2.txt
```

* Create mldb_wallet_password_v2.txt and use the following command to add a new Docker secret for the wallet password:

```bash
  $docker secret create mldb_wallet_password_v2 mldb_wallet_password_v2.txt
```

6. Use the following commands to rotate the Docker secrets for all the Docker services created above using Docker stack:

```bash
docker service update \
    --secret-rm mldb_admin_username_v1 \
    --secret-rm mldb_admin_password_v1 \
    --secret-rm mldb_wallet_password_v1 \
    --secret-add source=mldb_admin_username_v2,target=mldb_admin_username \
    --secret-add source=mldb_admin_password_v2,target=mldb_admin_password \
    --secret-add source=mldb_wallet_password_v2,target=mldb_wallet_password \
    mlstack_bootstrap
```

```bash
docker service update \
    --secret-rm mldb_admin_username_v1 \
    --secret-rm mldb_admin_password_v1 \
    --secret-rm mldb_wallet_password_v1 \
    --secret-add source=mldb_admin_username_v2,target=mldb_admin_username \
    --secret-add source=mldb_admin_password_v2,target=mldb_admin_password \
    --secret-add source=mldb_wallet_password_v2,target=mldb_wallet_password \
    mlstack_node2
```

```bash
docker service update \
    --secret-rm mldb_admin_username_v1 \
    --secret-rm mldb_admin_password_v1 \
    --secret-rm mldb_wallet_password_v1 \
    --secret-add source=mldb_admin_username_v2,target=mldb_admin_username \
    --secret-add source=mldb_admin_password_v2,target=mldb_admin_password \
    --secret-add source=mldb_wallet_password_v2,target=mldb_wallet_password \
    mlstack_node3
```

Above commands will remove secrets v1 and update services with new v2 secrets.

Wait for all the services to be updated. Secrets inside the containers under the /run/secrets directory will be updated with new v2 secrets.
Note: The MarkLogic cluster will still use the admin credentials set in the initial stack deployment with the v1 secrets.

### Three node cluster setup on multiple VMs

This next example shows how to create containers on separate VMs and connect them with each other using Docker Swarm. For more details on Docker Swarm, see <https://docs.docker.com/engine/swarm/>. All of the nodes inside the cluster must be part of the same network in order to communicate with each other. We use the overlay network that allows for container communication on separate hosts. For more information on overlay networks, please refer <https://docs.docker.com/network/overlay/>.

#### VM#1

Follow these steps to set up the first node ("bootstrap") on VM1.

Initialize the Docker Swarm with this command:

```bash
docker swarm init
```

Copy the output from this step. The other VMs will need this information to connect them to the swarm. The output will be similar to this: `docker swarm join --token xxxxxxxxxxxxx {VM1_IP}:2377`.

Use this command to create a new network:

```bash
docker network create --driver=overlay --attachable ml-cluster-network
```

Use this command to verify the ml-cluster-network has been created:

```bash
docker network ls
```

The `network ls` command will list all the networks on the host.

Run this command to start the Docker container, adding your username and password to the command. It will start the Docker container (named "bootstrap") with MarkLogic Server initialized.

```bash
$ docker run -d -it -p 7100:8000 -p 7101:8001 -p 7102:8002 \
     --name bootstrap -h bootstrap.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e MARKLOGIC_INIT=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     --dns-search "marklogic.com" \
     marklogicdb/marklogic-db
```

If successful, the command will output the ID for the new container. Give the container a couple of minutes to get initialized. Continue with the next section to create additional nodes for the cluster.

#### VM#n

Follow the next steps to set up an additional node (for example ml2) on VM#n.

Run the Docker `swarm join` command that you got as output when you set up VM#1 previously.

```text
docker swarm join --token xxxxxxxxxxxxx {VM1_IP}:2377
```

This command adds the current node to the swarm initialized earlier.

Start the Docker container (ml2.marklogic.com) with MarkLogic Server initialized, and join the container to the same cluster as you started/initialized on VM#1. Be sure to add your admin username and password for the bootstrap host in the Docker start up command that follows. To join this host to a specific MarkLogic Group, use the MARKLOGIC_GROUP environment parameter as below.

```bash
$ docker run -d -it -p 7200:8000 -p 7201:8001 -p 7202:8002 \
     --name ml2 -h ml2.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_JOIN_CLUSTER=true \
     -e MARKLOGIC_GROUP=dnode \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     marklogicdb/marklogic-db
```

When you complete these steps, you will have multiple containers; one on each VM, and all connected to each other on the 'ml-cluster-network' network. All the containers will be part of same cluster.

### How to join a TLS(HTTPS) enabled cluster

This example shows how to join a node to a TLS enabled cluster. There are two prerequistes for this configuration, first is TLS enabled bootstrap host App servers, second is the CA certificate or certificate chain of the host.

Below example uses docker stack for MarkLogic cluster deployment. It will create a docker stack named mlstack with two services named bootstrap and node2.

1. Create a bootstrap host using the following compose file:

```YAML
version: '3.6'
services:
    bootstrap_3n:
      image: marklogicdb/marklogic-db
      container_name: bootstrap_3n
      hostname: bootstrap_3n
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME=test_admin
        - MARKLOGIC_ADMIN_PASSWORD=test_admin_pass
        - REALM=public
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol1:/var/opt/MarkLogic
      ports:
        - 7100-7110:8000-8010
        - 7197:7997
      networks:
      - external_net
networks:
  external_net: {}
volumes:
  MarkLogic_3n_vol1:
```

2. Use the following command to create a stack and service:

```text
docker stack deploy -c bootstrap-compose.yaml mlstack
```

3. Once the bootstrap host is up and running, enable HTTPS on the Admin and Manage app servers (ports 8001 and 8002) using the procedures from the MarkLogic documentation <https://docs.marklogic.com/guide/security/SSL>.
4. Obtain the CA certificate for SSL enabled app servers on the bootstrap host and store it in the same directory as the compose file. The CA certificate/certificate chain used to join the cluster will be stored as Docker secret.
5. Create files `mldb_admin_username.txt` and `mldb_admin_password.txt` to set the admin username/password used for joining the bootstrap host.
6. Use the compose file below to create node2. Please note the {MARKLOGIC_JOIN_TLS_ENABLED} parameter is set to true and the {MARKLOGIC_JOIN_CACERT_FILE} is set as a Docker secret with the value set to the CA certificate/certificate chain file path. Please see the [Configuration](#configuration) section for more details on these two parameters.

```YAML
version: '3.6'
services:
    node2:
      image: marklogicdb/marklogic-db
      container_name: node2
      hostname: node2
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_TLS_ENABLED=true
        - MARKLOGIC_JOIN_CACERT_FILE=certificate.cer
        - MARKLOGIC_JOIN_CLUSTER=true
        - MARKLOGIC_BOOTSTRAP_HOST=bootstrap
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_2n_vol2:/var/opt/MarkLogic
      secrets:sta
        - source: mldb_admin_username
          target: mldb_admin_username
        - source: mldb_admin_password
          target: mldb_admin_password
        - source: certificate.cer
          target: certificate.cer
      ports:
        - 7200-7210:8000-8010
        - 7297:7997
      networks:
      - external_net
secrets:
  mldb_admin_password:
    file: ./mldb_admin_password.txt
  mldb_admin_username:
    file: ./mldb_admin_username.txt
  certificate.cer:
    file: ./certificate.cer
networks:
  external_net: {}
volumes:
  MarkLogic_2n_vol2:
```

4. Use below command to create the node2 Docker container:

```bash
docker stack deploy -c node2-compose.yaml mlstack
```

5. Verify the node2 joined the cluster using MarkLogic Admin console.

#### How to update CA certificate/certificate chain in a Docker container?

In case, CA certificate/certificate chain is renewed, it should be updated to ensure Docker container is running uninterrupted.
Follow below steps to update the certificate:

1. Create a new docker secret for new certificate for the host.

* For instance new certificate is stored in file certificate_v2.cer, use the following command to add a new Docker secret:

```bash
  $docker secret create certificate_v2.cer certificate_v2.cer
```

2. Use the below command to rotate the Docker secret for the mlstack_node2 Docker services created above using Docker stack:

```bash
docker service update \
    --secret-rm certificate_v1.cer \
    --secret-add source=certificate_v2.cer,target=certificate.cer \
    mlstack_node2
```

Above command will remove old certificate and update service with new certificate from certificate2.cer.
Wait for the service to be updated. Secret inside the container under /run/secrets directory will be updated with new certificate.

## Upgrading to the latest MarkLogic Docker Release

MarkLogic has extensive documentation about upgrades, see [https://docs.marklogic.com/guide/relnotes/chap2](https://docs.marklogic.com/guide/relnotes/chap2). Other than the uninstall and install of the MarkLogic RPMs, the overall processes and compatibility notes for upgrades remain the same when you run MarkLogic in containers. Instead of uninstalling and installing the MarkLogic RPMs, use the following procedure to upgrade a container instance to a newer release of MarkLogic. Be sure to follow the sequence described in the documentation for rolling upgrades [https://docs.marklogic.com/guide/admin/rolling-upgrades](https://docs.marklogic.com/guide/admin/rolling-upgrades) if you need to upgrade with zero downtime.

To upgrade MarkLogic Docker from release 10.x to the latest release, perform following steps:

Note: In the below example, we are upgrading an initialized MarkLogic host to the latest MarkLogic version supported for Docker.

1. Stop the MarkLogic Docker container.
Use following command to stop the container:

```bash
docker stop container_id
```

2. Now, run a MarkLogic Docker container using the latest release of the Docker image. Use the same volume, mounted to the container that was running the older release.

```bash
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     --name MarkLogic_cont_2 \
     --mount src=MarkLogic_vol_1,dst=/var/opt/MarkLogic \
    marklogicdb/marklogic-db
```

3. In a browser, open the MarkLogic Admin Interface for the container (http://<vm_ip>:8001/).
4. When prompted by the Admin Interface to upgrade the databases and configuration files, click the Ok button to confirm the upgrade.
5. Once the upgrade is complete, the Admin interface will reload with the new MarkLogic release.

## Backing Up and Restoring a Database

When creating a backup for a database on a MarkLogic Docker container, verify that the directory used for the backup is mounted to a directory on the Docker host machine or Docker volume. This is so that the database backup persists even after the container is stopped.

This command is an example of mounting the directory /space used for backup on a Docker volume, while running the MarkLogic Docker container.

```bash
$ docker run -d -it -p 7000:8000 -p 7001:8001 -p 7002:8002 \
     --mount src=MarkLogic_vol_1,dst=/var/opt/MarkLogic \
     --mount src=MarkLogic_vol_1,dst=/space \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     marklogicdb/marklogic-db
```

The /space mounted on the Docker volume can now be used as backup directory for backing up/restoring a database using the procedures described in the MarkLogic documentation: <https://docs.marklogic.com/guide/admin/backup_restore>

## Debugging

### View MarkLogic Server Startup Status

To check the MarkLogic Server startup status, run the below command to tail the MarkLogic log file

```bash
docker exec -it <container name> tail -f /var/opt/MarkLogic/Logs/ErrorLog.txt
```

### Accessing a MarkLogic Container while it's running

The following is a set of steps to run to access a container while it is running, and to do some basic debugging once you access the container.

1. Access the machine running the Docker container. This is typically done using SSH or by having physical access to the machine hosting the container.
2. Get the container ID for the MarkLogic container running on the machine. To do this, run the following command:

```bash
docker container ps --filter ancestor=marklogicdb/marklogic-db -q
```

In this example command `marklogicdb/marklogic-db` is an image ID. Your container ID may be different for your machine.

Example output:

```text
f484a784d998
```

If you don't know the image name, you can search for it without a filter:

```bash
docker container ps
```

Here's an example of unfiltered output from that command:

```text
CONTAINER ID   IMAGE                                                        COMMAND                  CREATED          STATUS          PORTS                                  NAMES
f484a784d998   marklogicdb/marklogic-db   "/usr/local/bin/star…"   16 minutes ago   Up 16 minutes   25/tcp, 7997-7999/tcp, 8003-8010/tcp, 0.0.0.0:8000-8002 8000-8002/tcp   vibrant_burnell
```

3. Run a command to access a remote shell on the container.

For this example command, `f484a784d998` is the container ID from the prior step. The one assigned to your container will be different.

```bash
docker exec -it f484a784d998 /bin/bash
```

4. To verify that MarkLogic is running, use this command:

```text
sudo service MarkLogic status
```

Example output:  

```text
MarkLogic (pid  34) is running...
```

5. To read the logs for the container, navigate to `/var/opt/MarkLogic/Logs`. View the logs using a reader like `vi`.

For example, you can list the 8001 error logs, and view them with a single command:

```text
sudo cd /var/opt/MarkLogic/Logs && ls && vi ./8001_ErrorLog.txt
```

6. To exit the container when you are through debugging, use the exit command:

```text
exit
```

## Clean up

### Basic Example Removal

These are the steps you can use to remove the containers created in the "Using this Image" section of the text. It is important to remove resources after development is complete to free up ports and resources when they are not in use.  

Use this command to stop a container, replacing `container_name` with the name(s) of the container(s) found when using the command: `docker container ps`.

```bash
docker stop container_name
```

Use this command to remove a stopped container:

```bash
docker rm container_name
```

### Multi and Single Node, Single VM cleanup

This section describes the teardown process for clusters set up on a single VM using Docker compose, as described in the earlier examples.

#### Remove compose resources

Resources such as containers, volumes, and networks that were created with compose command can be removed using this command:

```bash
docker-compose -f marklogic-single-node.yaml down
```

#### Remove volumes

Volumes can be removed in a few ways. Adding the `–rm` option while running a container will remove the volume when the container dies. You can also remove a volume by using `prune`. See the following examples for more information.

```bash
docker run --rm -v /foo -v awesome:/bar container image
```

To remove all other unused volumes use this command:

```bash
docker volume prune
```

If the process is successful, the output will list all of the removed volumes.

#### Multi-VM Cleanup

For multi-VM setup, first stop and remove all the containers on all the VMs using the commands described in the "Basic Example Removal" section.
Then remove all the volumes with the commands described in the "Remove volumes" section.

Finally, disconnect VMs from the swarm running the following command on each VM:

```bash
docker swarm leave --force
```

If the process is successful, a message saying the node has left the swarm will be displayed.

## Image Tag

The `marklogic` image tags allow the user to pin their applications to images for a specific release, a specific minor release, a specific major release, or the latest release of MarkLogic Server

### `{ML release version}-{platform}`

This tag points to the exact version of MarkLogic Server and the base OS. This allows an application to pin to a very specific version of the image and base OS (platform).

Platform can be `centos`, `ubi` (RedHat Universal Base Image) or `ubi-rootless` (RedHat Universal Base Image for rootless containers). When `latest` tag is used, the platform will default to `ubi-rootless`.

e.g. `11.2.0-centos` is the MarkLogic Server 11.2.0 release and CentOS base OS.

### `latest-xx.x`

This tag points to the latest patch release of a specific minor version of MarkLogic Server on UBI-rootless.

e.g. `latest-11.0` is the latest patch release of MarkLogic Server 11.0 (11.0.0, 11.0.1, etc.).

For MarkLogic 10, because the numbering scheme was changed, the maintenance release is equivalent to the minor release in MarkLogic 11. Use the `latest-10.0-x` tag to pin to a specific maintenance release of MarkLogic 10.

### `latest-xx`

This tag points to the latest minor and patch release of a specific major version of MarkLogic Server on UBI-rootless.

e.g. `latest-11` is the latest patch release of the latest minor release of MarkLogic Server 11 (11.0.0, 11.0.1, 11.1.0, 11.1.1, etc.)

For MarkLogic 10, because the numbering scheme was changed, the maintenance release is equivalent to the minor release in MarkLogic 11. Use the `latest-10` tag to get the latest patch release of the latest maintenance release MarkLogic 10.

### `latest`

This tag points to the latest minor, patch, and major release of MarkLogic Server on UBI-rootless.

It will pull the latest image and can cross patch, minor or major release numbers (11.0.0, 11.0.1, 11.1.0, 11.1.1, 12.0.0, etc.)

**Note: The 'latest' images should not be used in production**

## Container Runtime Detection

Since MarkLogic 11.2, MarkLogic is able to detect on which container runtime it is running on.

### Docker Engine

When running on Docker Engine the following entry will show up in the ErrorLogs.txt:

`2024-03-15 08:27:36.136 Info: MarkLogic Server is running in a container using Docker runtime.A maximum of 1152 huge pages will be used if available`

### Containerd Engine

When running on Containerd Engine the following entry will show up in the ErrorLogs.txt:

`2024-03-15 08:27:36.136 Info: MarkLogic Server is running in a container using Containerd runtime.A maximum of 1152 huge pages will be used if available`

### CRI-O Engine

When running on CRI-O Engine the following entry will show up in the ErrorLogs.txt:

`2024-03-15 08:27:36.136 Info: MarkLogic Server is running in a container using CRI-O runtime.A maximum of 1152 huge pages will be used if available`

## Known Issues and Limitations

1. The image must be run in privileged mode. At the moment if the image isn't run as privileged many calls that use `sudo` during the supporting script will fail due to lack of required permissions as the image will not be able to create a user with the required permissions.
2. Using the "leave" button in the Admin interface to remove a node from a cluster may not succeed, depending on your network configuration. Use the Management API to remove a node from a cluster. See: [https://docs.marklogic.com/REST/DELETE/admin/v1/host-config](https://docs.marklogic.com/REST/DELETE/admin/v1/host-config).
3. Rejoining a node to a cluster, that had previously left that cluster, may not succeed.
4. MarkLogic Server will default to the UTC timezone.
5. The latest released version of CentOS 7 has known security vulnerabilities with respect to glib2 (CVE-2015-8387, CVE-2015-8390, CVE-2015-8394), glibc (CVE-2019-1010022), pcre (CVE-2015-8380, CVE-2015-8387, CVE-2015-8390, CVE-2015-8393, CVE-2015-8394), SQLite (CVE-2019-5827), nss (CVE-2014-3566), and bind-license (CVE-2023-6516, CVE-2023-5679, CVE-2023-5517, CVE-2023-50868, CVE-2023-50387, CVE-2023-4408). These libraries are included in the CentOS base image but, to-date, no fixes have been made available. Even though these libraries may be present in the base image that is used by MarkLogic Server, they are not used by MarkLogic Server itself, hence there is no impact or mitigation required.