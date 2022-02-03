<!-- Space: ENGINEERING -->
<!-- Parent: MarkLogic Docker Documentation for DockerHub and GitHub -->
<!-- Title: EA3 Review -->

<!-- Include: wiki-disclaimer.md -->
<!-- Include: ac:toc -->
<!-- Include: dockerhub-tos.md -->

## Prerequisites

- Examples in this document use Docker Engine and Docker CLI to create and manage containers. Please follow Docker documentation for instructions on how to install Docker: [Docker Engine](https://docs.docker.com/engine/)
- In order to get the MarkLogic image from Dockerhub you need a Dockerhub account. Follow the instruction on [Docker Hub](https://hub.docker.com/signup) to create a Dockerhub account.
- To access MarkLogic Admin interface and App Servers in our examples, you will need a desktop browser. See "Supported Browsers" in the [support matrix](https://developer.marklogic.com/products/support-matrix/) for a list of supported browsers.

## Supported tags

Note: MarkLogic Server Docker images follow a specific tagging format: `{ML release version}-{platform}-{ML Docker release version}-ea`

- 10.0-8.3-centos-1.0.0-ea3 - This current release of the MarkLogic Server Developer Docker image includes all features and is limited to developer use
- [Older Supported Tags](#older-supported-tags)

## Quick reference

Docker images are maintained by MarkLogic. Send feedback to the MarkLogic Docker team: docker@marklogic.com

Supported Docker architectures: x86_64

Base OS: CentOS

Latest supported MarkLogic Server version: 10.0-8.3

Published image artifact details: https://github.com/marklogic/marklogic-docker, https://hub.docker.com/_/marklogic

## MarkLogic

[MarkLogic](http://www.marklogic.com/) is the only Enterprise NoSQL database. It is a new generation database built with a flexible data model to store, manage, and search JSON, XML, RDF, and more - without sacrificing enterprise features such as ACID transactions, certified security, backup and recovery. With these capabilities, MarkLogic is ideally suited for making heterogeneous data integration simpler and faster, and for delivering dynamic content at massive scale.

MarkLogic documentation is available at [http://docs.marklogic.com](https://docs.marklogic.com/).

## Using this Image

Optionally we can either create an initialized or an uninitialized MarkLogic Server. The difference between initialized and uninitialized pertains to when the username and password for the admin are setup. 

- Initialized: when admin credentials are setup at runtime prior to MarkLogic starting 
- Unintialized: when admin credentials are created by the user after MarkLogic has started, by navigating to localhost:8000 and using the GUI 

### Initialized MarkLogic Server
For an initialized MarkLogic Server, admin credentials are required to be passed while creating the Docker container. The Docker container will have MarkLogic Server installed and initialized. MarkLogic Server will have databases and app servers created. A security database will be created to store user data, roles and other security information. MarkLogic Server credentials, passed as env params while running a container, will be stored as admin user in the security database. These admin credentials can be used to access MarkLogic Server Admin interface on port 8001 and other app servers with respective ports.

To create an initialized MarkLogic Server, pass environment variables and replace {insert admin username}/{insert admin password} with actual values for admin credentials, optionally pass license information in {insert license}/{insert licensee} to apply license and, run this command: 

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e LICENSE_KEY="{insert license}" \
     -e LICENSEE="{insert licensee}" \
     store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
```
Example run:
```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \        
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=admin \
     -e MARKLOGIC_ADMIN_PASSWORD=Areally!PowerfulPassword1337 \
     store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
8834a1193994cc75405de27d6985eba632ee1e9a1f4519dac6ff833cecb9abb6
```
Wait about a minute for MarkLogic Server to initialize before checking the ports. To verify the successful installation and initialization, log into the MarkLogic Server Admin Interface using admin credentials used in the command above. This is done by navigating to http://localhost:8001. Additionally, you can verify the configuration by following the procedures outlined in the MarkLogic Server documentation. See the Installation documentation [here](https://docs.marklogic.com/guide/installation/procedures#id_84772).

### Uninitialized MarkLogic Server
For an Uninitialized MarkLogic Server, admin credentials or license information is not required while creating the container. The Docker container will have MarkLogic Server installed and ports exposed for app servers as specified in the run command. Users can access the Admin Interface via http://localhost:8001 and manually initialize the MarkLogic Server, create admin user, databases and install license. See the Installation documentation [here](https://docs.marklogic.com/guide/installation/procedures#id_84772).

To create an uninitialized MarkLogic Server with [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/), run this command:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
```
The example output will contain a hash of the image ID: `f484a784d99838a918e384eca5d5c0a35e7a4b0f0545d1389e31a65d57b2573d`

Wait for about a minute, before going to the Admin Interface on http://localhost:8001. If MarkLogic container is started successfully on Docker, you should see configuration screen allowing you to initialize the server as per https://docs.marklogic.com/guide/installation/procedures#id_60220.  


Note that examples in this document can interfere with each other and it is recommended to stop all the containers before running the examples. See [Clean up](#clean-up) section below for more details.

### Persistent Data Volume

A MarkLogic Docker container stores data in `/var/opt/MarkLogic` which is persistent in a Docker managed volume. It is reommended to use named volumes instead of bind mounts as per [Docker documentation](https://docs.docker.com/storage/volumes/).

The following command will list previously created volumes:

```
$ docker volume ls
```
If the instructions in the `Using this Image` section are followed, the above command should output at least two volume identifiers:
```
DRIVER    VOLUME NAME
local     0f111f7336a5dd1f63fbd7dc07740bba8df684d70fdbcd748899091307c85019
local     1b65575a84be319222a4ff9ba9eecdff06ffb3143edbd03720f4b808be0e6d18
```

The following command uses a named volume and named container in order to make management easier:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     --name MarkLogic_cont_1
     --mount src=MarkLogic_vol_1,dst=/var/opt/MarkLogic \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
```

Run 
```
$ docker volume ls
```

The output from should now contain a named volume `MarkLogic_vol_1`:
```
DRIVER    VOLUME NAME
local     0f111f7336a5dd1f63fbd7dc07740bba8df684d70fdbcd748899091307c85019
local     1b65575a84be319222a4ff9ba9eecdff06ffb3143edbd03720f4b808be0e6d18
local     MarkLogic_vol_1
```
Above command will start a Docker container `MarkLogic_cont_1` running MarkLogic Server and associate the named Docker volume `MarkLogic_vol_1` with it.

## Configuration

MarkLogic Server Docker containers are configured via a set of environment variables.


| env var                       | value                           | required                          | default   | description                                        |
| ------------------------------- | --------------------------------- | ----------------------------------- | ----------- | ---------------------------------------------------- |
| MARKLOGIC_INIT                | true                            | no                                |           | when set to true, will initialize MarkLogic           |
| MARKLOGIC_ADMIN_USERNAME      | jane_doe                        | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin user                           |
| MARKLOGIC_ADMIN_PASSWORD      | pass                            | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin password                       |
| MARKLOGIC_ADMIN_USERNAME_FILE | secret_username                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin username via Docker secrets    |
| MARKLOGIC_ADMIN_PASSWORD_FILE | secret_password                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin password via Docker secrets    |
| MARKLOGIC_JOIN_CLUSTER        | true                            | no                                |           | will join cluster via MARKLOGIC_BOOTSTRAP          |
| MARKLOGIC_BOOTSTRAP           | someother.bootstrap.host.domain | no                                | bootstrap | must define if not connecting to default bootstrap |
| LICENSE_KEY           | license key                     | no                                | n/a       | set MarkLogic license key                          |
| LICENSEE            | licensee information            | no                                | n/a       | set MarkLogic licensee information                 |

**IMPORTANT:** The use of [Docker secrets](https://docs.docker.com/engine/swarm/secrets/) is new in the store/marklogicdb/marklogic-server:10.0-7.3-centos-1.0.0-ea image and will not work with older versions of the Docker image. The Docker compose examples below use secrets. If you want to use the examples with an older version of the image, you will need to update the examples to use environment variables instead.

## Clustering

MarkLogic Server Docker containers ship with a small set of scripts, making it easy to [create clusters](https://docs.marklogic.com/guide/concepts/clustering). Below are three examples for creating MarkLogic Server clusters with Docker containers. The first two use [Docker compose](https://docs.docker.com/compose/) scripts to create one-node and three-node clusters. The third example demonstrates a container setup on separate VMs.

The credentials for the admin user are configured via Docker secrets, and are stored in mldb_admin_username.txt and mldb_admin_password.txt files.

### Single node MarkLogic Server on a single VM
Single node configurations are usually used on a development machine with a single user.

Create marklogic-centos.yml, mldb_admin_username.txt, and mldb_admin_password.txt files in your home directory, typically denoted as `~`, where the user has full access to run Docker as shown below.

**marklogic-centos.yml**

```
#Docker compose file sample to setup single node cluster
version: '3.6'
services:
    bootstrap:
      image: store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
      container_name: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_1n_vol1:/var/opt/MarkLogic
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
  MarkLogic_1n_vol1:
```

**mldb_admin_username.txt**

```
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

{insert admin username}
```

**mldb_admin_password.txt**

```
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

{insert admin password}
```

Once the files are ready, run the following command to start the MarkLogic Server container.

```
$ docker-compose -f marklogic-centos.yml up -d
```
Above command will start a Docker container running MarkLogic Server named bootstrap.
Run below command to verify if the container is running:
```
$ docker ps
```
If the containers are running correctly, the above command lists all the Docker containers running on the host.

After the container is initialized, you can access QConsole on http://localhost:8000 and the Admin UI on http://localhost:8001. The ports can also be accessed externally via your hostname or IP.

### Three node cluster on a single VM

Here is an example of a three node MarkLogic server cluster using Docker compose. Create marklogic-cluster-centos.yml, mldb_admin_username.txt, and mldb_admin_password.txt files on your host machine as shown below.

**marklogic-cluster-centos.yml**

```
#Docker compose file sample to setup a three node cluster
version: '3.6'
services:
    bootstrap:
      image: store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
      container_name: bootstrap_3n
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
      image: store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
      container_name: node2
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
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
      - bootstrap
      networks:
      - external_net
    node3:
      image: store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
      container_name: node3
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
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
  MarkLogic_3n_vol1:
  MarkLogic_3n_vol2:
  MarkLogic_3n_vol3:
```

**mldb_admin_username.txt**
```
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

{insert admin username}
```

**mldb_admin_password.txt**
```
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

{insert admin password}
```

Once the files are ready, run the following command to start the MarkLogic Server container.

```
$ docker-compose -f marklogic-cluster-centos.yml up -d
```

Above command will start three Docker containers running MarkLogic Server named bootstrap_3n, node2 and, node3. Run below command to verify if the conatiners are running,
```
$ docker ps
```
Above command lists all the Docker containers running on the host.

After the container is initialized, you can access the Query Console on http://localhost:8000 and the Admin Interface on http://localhost:8001. The ports can also be accessed externally via your hostname or IP.

As with the single node example, each node of the cluster can be accessed with localhost or host machine IP. Query Console and Admin Interface ports for each container are different, as defined in the compose file above: http://localhost:7101, http://localhost:7201, http://localhost:7301, etc.

#### Using ENV for admin credentials in Docker compose

In the examples above, Docker secrets files were used to specify admin credentials for the MarkLogic Server. A less managed approach would be to use environmental variables. If your environment prevents the use of Docker secrets, use environmental variables. This approach is less secure because credentials remain in the environment at runtime. In order to use these variables in the Docker compose files, remove the secrets section at the end of the Docker compose yml file, and remove the secrets section in each node. Finally, replace MARKLOGIC_ADMIN_USERNAME_FILE/MARKLOGIC_ADMIN_PASSWORD_FILE variables with MARKLOGIC_ADMIN_USERNAME/MARKLOGIC_ADMIN_PASSWORD and provide the appropriate values.

### Three node cluster setup on multiple VMs
In this example, containers will be created on separate VMs and connected them with each other using Docker Swarm. For more details on Docker Swarm see https://docs.docker.com/engine/swarm/. All of the nodes inside the cluster must be part of the same network in order to communicate with each other. We will use the overlay network which allows for container communication on separate hosts. For more information on overlay networks, please refer https://docs.docker.com/network/overlay/.

#### VM#1

Follow the steps below to set up the first node (bootstrap) on VM1.

Initialize the Docker Swarm with this command:

```
$ docker swarm init
```
Copy the output from this step as it will be needed for the other VMs to connect to them to the swarm. The output will be similar to `docker swarm join --token xxxxxxxxxxxxx {VM1_IP}:2377`. 

Create a new network with this command:

```
$ docker network create --driver=overlay --attachable ml-cluster-network
```

Verify that the ml-cluster-network has been created.

```
$ docker network ls
```
Above command will list all the networks on the host.

Start the Docker container (bootstrap) with MarkLogic Server initialized. Give the container a couple of minutes to get initialized.

```
$ docker run -d -it -p 7100:8000 -p 7101:8001 -p 7102:8002 \
     --name bootstrap -h bootstrap.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e MARKLOGIC_INIT=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     --dns-search "marklogic.com" \
     store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
```
If successful, the command will output the ID for the new container. Continue with the next section to create additonal nodes for the cluster.

#### VM#n

Follow the next steps to set up additonal node (for example ml2) on VM#n.

Run the Docker swarm join command that you got as output when you set up VM#1.

```
$ docker swarm join --token xxxxxxxxxxxxx {VM1_IP}:2377
```
Above command will add the current node to the swarm intialized above. 

Start the Docker container (ml2.marklogic.com) with MarkLogic Server initialized, and join to the same cluster as you started/initialized on VM#1

```
$ docker run -d -it -p 7200:8000 -p 7201:8001 -p 7202:8002 \
     --name ml2 -h ml2.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_JOIN_CLUSTER=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3
```

When you complete these steps, you will have multiple containers; one on each VM and all connected to each other on the 'ml-cluster-network' network. All the containers will be part of same cluster.

## Debugging

### Accessing a MarkLogic Container while its running

Below is a set of steps to run in order to access a container while it is running and do some basic debugging once access is obtained.

1. Access the machine running the Docker container, this is typically done through SSH or having physical access to the machine.
2. Get the container ID of the running MarkLogic container on the machine

- In the below command store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3 is an image ID this could be different on your machine.

```
$ docker container ps --filter ancestor=store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3 -q
```

- Example Output:

```
f484a784d998
```

- If you don't know the image you can search without a filter:

```
$ docker container ps
```

- Example unfiltered output:

```
CONTAINER ID   IMAGE                                                        COMMAND                  CREATED          STATUS          PORTS                                  NAMES
f484a784d998   store/marklogicdb/marklogic-server:10.0-8.3-centos-1.0.0-ea3   "/usr/local/bin/star…"   16 minutes ago   Up 16 minutes   25/tcp, 7997-7999/tcp, 8003-8010/tcp, 0.0.0.0:8000-8002 8000-8002/tcp   vibrant_burnell
```

3. Execute a command to access a remote shell onto the container.

In the below command f484a784d998 is the container ID from the prior step, the one given to your container will be different.

```
$ docker exec -it f484a784d998 /bin/bash
```

4. Verify MarkLogic is running:

```
$ sudo service MarkLogic status
```

Example Output:  

```
MarkLogic (pid  34) is running...
```

5. To read the logs Navigate to `/var/opt/MarkLogic/Logs` and view them in an reader like `vi`.

- As an example we can view the 8001 error logs, and list the log directory with a single command:

```
$ sudo cd /var/opt/MarkLogic/Logs && ls && vi ./8001_ErrorLog.txt
```

6. Exit the container, when you've completed debugging, with the exit command:

```
$ exit
```

## Clean up

### Docker secrets removal

Using Docker secrets, username and password information is secured when transmitting the sensitive data from Docker host to Docker containers. The information is not available as an environment variable, to prevent any attacks. Still these values are stored in a text file and persisted in an in-memory file system. It is recommended to delete the Docker secrets information once the cluster is up and running. In order to remove the secrets file, follow these steps:

First, stop the container, because secrets cannot be removed from running containers.

Then update the Docker service to remove secrets.

```
$ docker service update --secret-rm {secret-name}
```

Restart the Docker container.

MarkLogic recommends that you remove Docker secrets from the Docker host as well.

```
$ docker secret rm {secret-name}
```

#### Basic Example Removal
Below are the steps needed to remove the containers setup in the "Using this Image" section of the text. Removal of resources is important after development is complete in order to keep ports free, and resources free when they are not in use. 

Below replace `container_name` with the name of the container(s) found in `docker container ps`
```
$ docker stop container_name
```

Use below command to remove a stopped container

```
$ docker rm container_name
```
#### Multi and Single Node, Single VM cleanup
The below section describes the teardown process of clusters setup on a single VM using docker compose, as noted in the examples above.

#### Remove compose resources

Resources such as containers, volumes and networks that were created with compose command can be removed with the following command:

```
$ compose -f marklogic-centos.yml down
```

#### Remove volumes

 Volumes can be removed in a few ways by adding --rm option while running a container, this will remove the volume when the container dies and by using `prune`. See the below examples for further information. 
```
$ docker run --rm -v /foo -v awesome:/bar container image
```

To remove all other unused volumes use below command

```
$ docker volume prune
```
If successful, the output will list all removed volumes.

### Multi-VM Cleanup
For multi-VM setup, first stop and remove all the containers on all the VMs with commands described in the "Basic Example Removal" section.
Then remove all the volumes with the command described in the "Remove volumes" section.
Finally, disconnect each VM from the swarm with the following command:

```
docker swarm leave --force
```
If successful, the command will output a message that the node has left the swarm.

## Known Issues and Limitations

10.0-8.3-centos-1.0.0-ea3

1. Enabling huge pages for clusters containing single-host, multi-container configurations may lead to failure, due to incorrect memory allocation. MarkLogic recommends that you disable huge pages in such architectures.
2. Database replication will only work for configurations having a single container per host, with matching hostname.
3. Using the "leave" button in the Admin interface to remove a node from a cluster may not succeed, depending on your network configuration. Use the Management API remove a node from a cluster. See: [https://docs.marklogic.com/REST/DELETE/admin/v1/host-config](https://docs.marklogic.com/REST/DELETE/admin/v1/host-config).
4. Rejoining a node to a cluster, that had previously left that cluster, may not succeed.
5. MarkLogic Server will default to the UTC timezone.
6. By default, MarkLogic Server runs as the root user. To run MarkLogic Server as a non-root user, see the following references:
   1. [https://help.marklogic.com/Knowledgebase/Article/View/start-and-stop-marklogic-server-as-non-root-user](https://wiki.marklogic.com/pages/createpage.action?spaceKey=PM&title=1&linkCreation=true&fromPageId=220243563)
   2. [https://help.marklogic.com/Knowledgebase/Article/View/306/0/pitfalls-running-marklogic-process-as-non-root-user](https://wiki.marklogic.com/pages/createpage.action?spaceKey=PM&title=2&linkCreation=true&fromPageId=220243563)

## Older Supported Tags
- 9.0-12-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-12.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-13-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-13.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-13.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-3-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-4-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-4.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-4.4-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-5-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-5.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-5.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6.4-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-7-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-7.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-7.3-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-1-dev-ubi - MarkLogic Developer Docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-2-dev-ubi - MarkLogic Developer Docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-3-dev-ubi - MarkLogic Developer Docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-7.3-centos-1.0.0-ea - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-8.1-centos-1.0.0-ea2 - MarkLogic Developer Docker image includes all features and is limited to developer use
