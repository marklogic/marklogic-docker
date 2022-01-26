## Supported tags

Note: MarkLogic docker images follow a specific tagging format: `<ML release version>-<platform>-<ML Docker release version>-ea`

- 10.0-8.1-centos-1.0.0-ea2 - MarkLogic Developer docker image includes all features and is limited to developer use
- [Older Supported Tags](#older-supported-tags)

## Quick reference
Docker images are maintained by MarkLogic. Send feedback to the MarkLogic Docker team: docker@marklogic.com

Supported Docker architectures: x86_64

Base OS: CentOS

Latest supported MarkLogic Server version: 10.0-8.1

Published image artifact details: https://github.com/marklogic/marklogic-docker, https://hub.docker.com/_/marklogic

## MarkLogic

[MarkLogic](http://www.marklogic.com/) is the only Enterprise NoSQL database. It is a new generation database built with a flexible data model to store, manage, and search JSON, XML, RDF, and more - without sacrificing enterprise features such as ACID transactions, certified security, backup and recovery. With these capabilities, MarkLogic is ideally suited for making heterogeneous data integration simpler and faster, and for delivering dynamic content at massive scale.

MarkLogic documentation is available at [http://docs.marklogic.com](https://docs.marklogic.com/).

## Using this Image

To create an uninitialized MarkLogic server with [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/), run this command:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
```

To create an initialized MarkLogic server, and pass environment variables, run this command:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
```

Wait for about a minute for MarkLogic to initialize before checking the ports.

### Persistent Data Volume

A MarkLogic Docker container stores data in `/var/opt/MarkLogic` which should be persistent in Docker managed volume. It is reommended to use named volumes instead of bind mounts as per [Docker documentation](https://docs.docker.com/storage/volumes/).

The following command will list previously created volumes:

```
$ docker volume ls
```

The command should output at least two randomly generated volume identifiers from the previous commands.

The following command uses named volume in order to make it easier to manage:

```
$ mkdir ~/data
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     --mount src=MarkLogic,dst=/var/opt/MarkLogic \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
```

## Configuration

MarkLogic Docker containers are configured via a set of environment variables.


| env var                       | value                           | required                          | default   | description                                        |
| ------------------------------- | --------------------------------- | ----------------------------------- | ----------- | ---------------------------------------------------- |
| MARKLOGIC_INIT                | true                            | no                                | <br/>     | when set to true, will initialize server           |
| MARKLOGIC_ADMIN_USERNAME      | jane_doe                        | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin user                           |
| MARKLOGIC_ADMIN_PASSWORD      | pass                            | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin password                       |
| MARKLOGIC_ADMIN_USERNAME_FILE | secret_username                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin username via Docker secrets    |
| MARKLOGIC_ADMIN_PASSWORD_FILE | secret_password                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin password via Docker secrets    |
| MARKLOGIC_JOIN_CLUSTER        | true                            | no                                | <br/>     | will join cluster via MARKLOGIC_BOOTSTRAP          |
| MARKLOGIC_BOOTSTRAP           | someother.bootstrap.host.domain | no                                | bootstrap | must define if not connecting to default bootstrap |

**IMPORTANT:** The use of Docker secrets is new in the PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG image and will not work with older versions of the Docker image. The Docker compose examples below use secrets. If you want to use the examples with an older version of the image, you will need to update the examples to use environment variables instead.

## Clustering

MarkLogic Docker containers ship with a small set of scripts, making it easy to create clusters. Below are three examples for creating MarkLogic clusters with Docker containers. The first two use [Docker compose](https://docs.docker.com/compose/) scripts to create one-node and three-node clusters. The third example demonstrates a container setup on separate VMs.

The credentials for admin user are configured via Docker secrets, and are stored in mldb_admin_username.txt and mldb_admin_password.txt files.

### Single node MarkLogic on a single VM

Create marklogic-1n-centos.yaml, mldb_admin_username.txt, and mldb_admin_password.txt files as shown below.

**marklogic-1n-centos.yaml**

```
#Docker compose file sample to setup single node MarkLogic cluster

version: '3.6'

services:
    bootstrap:
      image: PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
      container_name: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - MarkLogic:/var/opt/MarkLogic
      secrets:
          - mldb_admin_password
          - mldb_admin_username
      ports:
        - 8000-8010:8000-8010
        - 7997:7997
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
  MarkLogic-1:
```

**mldb_admin_username.txt**

```
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

<insert admin username>
```

**mldb_admin_password.txt**

```
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

<insert admin password>
```

Once the files are ready, run the following command to start the MarkLogic container.

```
$ docker-compose -f marklogic-1n-centos.yaml up -d
```

After the container is initialized, you can access QConsole on http://localhost:8000 and the Admin UI on http://localhost:8001. The ports can also be accessed externally via your hostname or IP.

### Three node MarkLogic cluster on a single VM

Here is an example of the marklogic-3n-centos.yaml, mldb_admin_username.txt, and mldb_admin_password.txt files that need to be created in your host machine before running the Docker compose command.

**marklogic-3n-centos.yaml**

```
#Docker compose file sample to setup a three node MarkLogic cluster

version: '3.6'

services:
    bootstrap:
      image: PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
      container_name: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - MarkLogicVol1:/var/opt/MarkLogic
      secrets:
          - mldb_admin_password
          - mldb_admin_username
      ports:
        - 7100-7110:8000-8010
        - 7197:7997
      networks:
      - external_net
    node2:
      image: PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
      container_name: node2
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - MarkLogicVol2:/var/opt/MarkLogic
      secrets:
        - mldb_admin_password
        - mldb_admin_username
      ports:
        - 7200-7210:8000-8010
        - 7297:7997
      depends_on:
      - bootstrap
      networks:
      - external_net
    node3:
      image: PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
      container_name: node3
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - MarkLogicVol3:/var/opt/MarkLogic
      secrets:
        - mldb_admin_password
        - mldb_admin_username
      ports:
        - 7300-7310:8000-8010
        - 7397:7997
      depends_on:
      - bootstrap
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
  MarkLogicVol1:
  MarkLogicVol2:
  MarkLogicVol3:
```

**mldb_admin_username.txt**

```
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

<insert admin username>
```

**mldb_admin_password.txt**

```
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

<insert admin password>
```

Once the files are ready, run the following command to start the MarkLogic container.

```
$ docker-compose -f marklogic-3n-centos.yaml up -d
```

After the container is initialized, you can access the QConsole on http://localhost:8000 and the Admin UI on http://localhost:8001. The ports can also be accessed externally via your hostname or IP.

As with the single node example, each node of the cluster can be accessed with localhost or host machine IP. QConsole and Admin UI ports for each container are different, as defined in the Docker compose file: http://localhost:7101, http://localhost:7201, http://localhost:7301, etc.

The node2, node3 use MARKLOGIC_JOIN_CLUSTER to join the cluster once they are running.

#### Using ENV for admin credentials in Docker compose

In the examples above, Docker secrets files were used to specify admin credentials for MarkLogic. An alternative approach would be to use MARKLOGIC_ADMIN_USERNAME/MARKLOGIC_ADMIN_PASSWORD environmental variables. This approach is less secure because credentials remain in the environment at runtime. In order to use these variables in the Docker compose files, remove the secrets section at the end of the Docker compose yaml file, and remove the secrets section in each node. Finally, replace MARKLOGIC_ADMIN_USERNAME_FILE/MARKLOGIC_ADMIN_PASSWORD_FILE variables with MARKLOGIC_ADMIN_USERNAME/MARKLOGIC_ADMIN_PASSWORD and provide the appropriate values.

### Three node MarkLogic cluster setup on multiple VM

This setup will create and initialize MarkLogic on 3 different VMs/hosts, and connect them with each other using [Docker Swarm](https://docs.docker.com/engine/swarm/).

#### VM#1

Follow the steps below to setup the first node (bootstrap) on VM1.

Initialize the Docker Swarm with this command:

```
$ docker swarm init
```

Write down the output from this step. It will be needed for the other VMs to connect to them to the swarm. The output will be "docker swarm join --token random-string-of-characters-generated-by-docker-swarm-command <VM1_IP>:2377"

Create an overlay network. All of the nodes inside the MarkLogic cluster must be part of this network in order to communicate with each other.

```
$ docker network create --driver=overlay --attachable ml-cluster-network
```

Verify that the ml-cluster-network has been created.

```
$ docker network ls
```

Start the Docker container (bootstrap) with MarkLogic initialized. Give the container a couple of minutes to get initialized.

```
$ docker run -d -it -p 7100:8000 -p 7101:8001 -p 7102:8002 \
     --name bootstrap -h bootstrap.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     -e MARKLOGIC_INIT=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     --dns-search "marklogic.com" \
     PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
```

#### VM#2

Follow the next steps to set up the second node (ml2) on VM2.

Run the Docker swarm join command that you got as output when you set up VM#1.

```
$ docker swarm join --token random-string-of-characters-generated-by-docker-swarm-command <VM1_IP>:2377
```

Start the Docker container (ml2.marklogic.com) with MarkLogic initialized, and join to the same cluster as you started/initialized on VM#1

```
$ docker run -d -it -p 7200:8000 -p 7201:8001 -p 7202:8002 \
     --name ml2 -h ml2.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_JOIN_CLUSTER=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
```

#### VM#3

Follow the next steps to set up the third node (ml3) on VM3.

Run the Docker swarm join command that you got as output when you set up VM#1.

```
$ docker swarm join --token random-string-of-characters-generated-by-docker-swarm-command <VM1_IP>:2377
```

Start the Docker container (ml3.marklogic.com) with MarkLogic initialized, and join to the same cluster as you started/initialized on VM#1

```
$ docker run -d -it -p 7300:8000 -p 7301:8001 -p 7302:8002 \
     --name ml3 -h ml3.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_JOIN_CLUSTER=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     PLACEHOLDER-FOR-DOCKER-IMAGE:DOCKER-TAG
```

When you complete these steps, you will have three containers; one on each VM and all connected to each other on the 'ml-cluster-network' network. All of the three containers will be part of same cluster.

## Docker secrets removal

Using Docker secrets, username and password information is secured when transmitting the sensitive data from Docker host to Docker containers. The information is not available as an environment variable, to prevent any attacks. Still these values are stored in a text file and persisted in an in-memory file system. MarkLogic recommends that you delete the Docker secrets information once the cluster is up and running. In order to remove the secrets file, follow these steps:

First, stop the container, because secrets cannot be removed from running containers.

Then update the Docker service to remove secrets.

```
$ docker service update --secret-rm <secret-name>
```

Restart the Docker container.

MarkLogic recommends that you remove Docker secrets from the Docker host as well.

```
$ docker secret rm <secret-name>
```

## Known Issues and Limitations

10.0-7.3-centos-1.0.0-ea

1. Enabling huge pages for clusters containing single-host, multi-container configurations may lead to failure, due to incorrect memory allocation. MarkLogic recommends that you disable huge pages in such architectures.
2. Database replication will only work for configurations having a single container per host, with matching hostname.
3. Using the "leave" button in the Admin interface to remove a node from a cluster may not succeed, depending on your network configuration. Use the Management API remove a node from a cluster. See: [https://docs.marklogic.com/REST/DELETE/admin/v1/host-config](https://docs.marklogic.com/REST/DELETE/admin/v1/host-config).
4. Rejoining a node to a cluster, that had previously left that cluster, may not succeed.
5. MarkLogic will default to the UTC timezone.
6. By default, MarkLogic runs as the root user. To run MarkLogic as a non-root user, see the following references:
   1. [https://help.marklogic.com/Knowledgebase/Article/View/start-and-stop-marklogic-server-as-non-root-user](https://wiki.marklogic.com/pages/createpage.action?spaceKey=PM&title=1&linkCreation=true&fromPageId=220243563)
   2. [https://help.marklogic.com/Knowledgebase/Article/View/306/0/pitfalls-running-marklogic-process-as-non-root-user](https://wiki.marklogic.com/pages/createpage.action?spaceKey=PM&title=2&linkCreation=true&fromPageId=220243563)

## Older Supported Tags
- 9.0-12-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 9.0-12.2-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 9.0-13-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 9.0-13.1-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 9.0-13.2-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-1-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-2-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-3-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-4-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-4.2-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-4.4-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-5-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-5.1-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-5.2-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-6-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-6.1-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-6.2-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-6.4-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-7-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-7.1-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-7.3-dev-centos- MarkLogic Developer docker image includes all features and is limited to developer use
- 10.0-1-dev-ubi- MarkLogic Developer docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-2-dev-ubi- MarkLogic Developer docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-3-dev-ubi- MarkLogic Developer docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-7.3-centos-1.0.0-ea - MarkLogic Developer docker image includes all features and is limited to developer use