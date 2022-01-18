## Prerequisites
- [Docker Engine](https://docs.docker.com/engine/)
    - To use dockerd, docker cli, docker APIs
- Desktop Browser
    - To access MarkLogic Admin interface and App Servers
    - See "Supported Browsers" in the [support matrix](https://developer.marklogic.com/products/support-matrix/)
## Supported tags

Note: MarkLogic Server docker images follow a specific tagging format: `<ML release version>-<platform>-<ML Docker release version>-ea`

- 10.0-8.1-centos-1.0.0-ea2 - MarkLogic Server Developer docker image includes all features and is limited to developer use
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

Optionally we can either create an initialized or an uninitialized MarkLogic Server. 

For an initialized MarkLogic Server, admin credentials are required to be passed while creating the docker container. The docker container will have MarkLogic Server installed and initialized. MarkLogic Server will have databases and app servers created. A security database will be created to store user data,roles and other security information. MarkLogic Server credentials, passed as env params while running a container, will be stored as admin user in the security database. These admin credentials can be used to access MarkLogic Server Admin interface on port 8001 and other app servers with respective ports.

To create an initialized MarkLogic Server, pass environment variables and replace <insert admin username> and <insert admin password> with actual values for admin credentials, optionally pass license information in <insert license> and, <insert licensee> to apply license and, run this command: 

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     -e MARKLOGIC_LICENSE="<insert license>" \
     -e MARKLOGIC_LICENSEE="<insert licensee>" \
     store/marklogicdb/marklogic-server:10.0-8.1-centos-1.0.0-ea2
```
Example run 
```
> docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \                                                                                                                                                   ─╯
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=admin \
     -e MARKLOGIC_ADMIN_PASSWORD=Areally!PowerfulPassword1337 \
     store/marklogicdb/marklogic-server:10.0-8.1-centos-1.0.0-ea2
8834a1193994cc75405de27d6985eba632ee1e9a1f4519dac6ff833cecb9abb6
```
Wait about a minute for MarkLogic Server to initialize before checking the ports. To verify the successful installation and initialization, login to MarkLogic Server admin interface using admin credentials provided while running the container, this is achieved by navigating to http://localhost:8000. After the initial login, you should see app servers and databases created on the host and admin user in the security database. Optionally you can check logs on admin interface from the logs tab.


For an Uninitialized MarkLogic Server, admin credentials or license information is not required while creating the container. The docker container will have MarkLogic Server installed and ports exposed for app servers as specified in the run command. Users can access Admin interface on port 8001 and manually initialize the MarkLogic Server, create admin user, databases and install license.

To create an uninitialized MarkLogic Server with [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/), run this command:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     store/marklogicdb/marklogic-server:10.0-8.1-centos-1.0.0-ea2
```
Example output will just contain a hash of the image ID IE: `f484a784d99838a918e384eca5d5c0a35e7a4b0f0545d1389e31a65d57b2573d`

Wait for about a minute, before going to admin interface on http://localhost:8001. If MarkLogic Server is installed successfully, you should see an initialize button on admin interface to initialize MarkLogic Server. Once the MarkLogic Server is initialized, access Manage app server on  http://localhost:8002 to see all the app servers and databases information. Optionally you can check logs on admin interface from the logs tab.

### Persistent Data Directory

A MarkLogic Server Docker container is always instantiated with a volume (`/var/opt/MarkLogic`).

Run the following command to instantiate a container:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     marklogic-server:10.0-8.1-centos-1.0.0-ea2
```
Above command will start a docker container running MarkLogic Server.

Verify volume creation with this command:

```
$ docker volume ls
```
Above command will list all docker volumes on the host

Alternately, you can bind a volume at runtime using the `-v` option:

```
$ mkdir ~/data
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     -v ~/data/MarkLogic:/var/opt/MarkLogic \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     marklogic-server:10.0-8.1-centos-1.0.0-ea2
```
Above command will start a docker container running MarkLogic Server and dind the given docker volume to it.

## Configuration

MarkLogic Server Docker containers are configured via a set of environment variables.


| env var                       | value                           | required                          | default   | description                                        |
| ------------------------------- | --------------------------------- | ----------------------------------- | ----------- | ---------------------------------------------------- |
| MARKLOGIC_INIT                | true                            | no                                | <br/>     | when set to true, will initialize MarkLogic           |
| MARKLOGIC_ADMIN_USERNAME      | jane_doe                        | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin user                           |
| MARKLOGIC_ADMIN_PASSWORD      | pass                            | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin password                       |
| MARKLOGIC_ADMIN_USERNAME_FILE | secret_username                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin username via Docker secrets    |
| MARKLOGIC_ADMIN_PASSWORD_FILE | secret_password                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic admin password via Docker secrets    |
| MARKLOGIC_JOIN_CLUSTER        | true                            | no                                | <br/>     | will join cluster via MARKLOGIC_BOOTSTRAP          |
| MARKLOGIC_BOOTSTRAP           | someother.bootstrap.host.domain | no                                | bootstrap | must define if not connecting to default bootstrap |
| MARKLOGIC_LICENSE             | license key                     | no                                | n/a       | set MarkLogic license key                          |
| MARKLOGIC_LICENSEE            | licensee information            | no                                | n/a       | set MarkLogic licensee information                 |

**IMPORTANT:** The use of Docker secrets is new in the marklogic-server:10.0-8.1-centos-1.0.0-ea2 image and will not work with older versions of the Docker image. The Docker compose examples below use secrets. If you want to use the examples with an older version of the image, you will need to update the examples to use environment variables instead.

## Clustering

MarkLogic Server Docker containers ship with a small set of scripts, making it easy to create clusters. Below are three examples for creating MarkLogic Server clusters with Docker containers. The first two use [Docker compose](https://docs.docker.com/compose/) scripts to create one-node and three-node clusters. The third example demonstrates a container setup on separate VMs.

The credentials for admin user are configured via Docker secrets, and are stored in mldb_admin_username.txt and mldb_admin_password.txt files. Make sure the yaml files for Docker compose have the desired image label and volume path (~/data/MarkLogic). All of these scripts were tested with version 20.10 of Docker.

### Single node MarkLogic on a single VM

Create marklogic-1n-centos.yaml, mldb_admin_username.txt, and mldb_admin_password.txt files in your home directory where the user has full access to run docker as shown below.

**marklogic-1n-centos.yaml**

```
#Docker compose file sample to setup single node MarkLogic cluster

version: '3.6'

services:
    bootstrap:
      image: marklogic-server:10.0-8.1-centos-1.0.0-ea2
      container_name: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - ~/data/MarkLogic:/var/opt/MarkLogic
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

Once the files are ready, run the following command to start the MarkLogic Server container.

```
$ docker-compose -f marklogic-1n-centos.yaml up -d
```
Above command will start a docker container running MarkLogic Server named bootstrap. Run below command to verify if the container is running,
```
$ docker ps
```
Above command lists all the docker containers running on the host.

After the container is initialized, you can access QConsole on http://localhost:8000 and the Admin UI on http://localhost:8001. The ports can also be accessed externally via your hostname or IP.

### Three node MarkLogic cluster on a single VM

Here is an example of the marklogic-3n-centos.yaml, mldb_admin_username.txt, and mldb_admin_password.txt files that need to be created in your host machine before running the Docker compose command.

**marklogic-3n-centos.yaml**

```
#Docker compose file sample to setup a three node MarkLogic Server cluster

version: '3.6'

services:
    bootstrap:
      image: marklogic-server:10.0-8.1-centos-1.0.0-ea2
      container_name: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - ~/data/MarkLogic1:/var/opt/MarkLogic
      secrets:
          - mldb_admin_password
          - mldb_admin_username
      ports:
        - 7100-7110:8000-8010
        - 7197:7997
      networks:
      - external_net
    node2:
      image: marklogic-server:10.0-8.1-centos-1.0.0-ea2
      container_name: node2
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - ~/data/MarkLogic2:/var/opt/MarkLogic
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
      image: marklogic-server:10.0-8.1-centos-1.0.0-ea2
      container_name: node3
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - ~/data/MarkLogic3:/var/opt/MarkLogic
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

Once the files are ready, run the following command to start the MarkLogic Server container.

```
$ docker-compose -f marklogic-3n-centos.yaml up -d
```

Above command will start three docker containers running MarkLogic Server named bootstrap, node2 and, node3. Run below command to verify if the conatiners are running,
```
$ docker ps
```
Above command lists all the docker containers running on the host.

After the container is initialized, you can access the QConsole on http://localhost:8000 and the Admin UI on http://localhost:8001. The ports can also be accessed externally via your hostname or IP.

As with the single node example, each node of the cluster can be accessed with localhost or host machine IP. QConsole and Admin UI ports for each container are different, as defined in the Docker compose file: http://localhost:7101, http://localhost:7201, http://localhost:7301, etc.

The node2, node3 use MARKLOGIC_JOIN_CLUSTER to join the cluster once they are running.

#### Using ENV for admin credentials in Docker compose

In the examples above, Docker secrets files were used to specify admin credentials for MarkLogic Server. An alternative approach would be to use MARKLOGIC_ADMIN_USERNAME/MARKLOGIC_ADMIN_PASSWORD environmental variables. This approach is less secure because credentials remain in the environment at runtime. In order to use these variables in the Docker compose files, remove the secrets section at the end of the Docker compose yaml file, and remove the secrets section in each node. Finally, replace MARKLOGIC_ADMIN_USERNAME_FILE/MARKLOGIC_ADMIN_PASSWORD_FILE variables with MARKLOGIC_ADMIN_USERNAME/MARKLOGIC_ADMIN_PASSWORD and provide the appropriate values.

### Three node MarkLogic cluster setup on multiple VM

This setup will create and initialize MarkLogic Server on 3 different VMs/hosts, and connect them with each other using [Docker Swarm](https://docs.docker.com/engine/swarm/).

#### VM#1

Follow the steps below to setup the first node (bootstrap) on VM1.

Initialize the Docker Swarm with this command:

```
$ docker swarm init
```

Write down the output from this step. It will be needed for the other VMs to connect to them to the swarm. The output will be "docker swarm join --token random-string-of-characters-generated-by-docker-swarm-command <VM1_IP>:2377"

Create an overlay network. All of the nodes inside the MarkLogic cluster must be part of this network in order to communicate with each other.
For more information on overlay network, please refer https://docs.docker.com/network/overlay/

```
$ docker network create --driver=overlay --attachable ml-cluster-network
```

Verify that the ml-cluster-network has been created.

```
$ docker network ls
```
Above command will list all the networkd on host

Start the Docker container (bootstrap) with MarkLogic Server initialized. Give the container a couple of minutes to get initialized.

```
$ docker run -d -it -p 7100:8000 -p 7101:8001 -p 7102:8002 \
     --name bootstrap -h bootstrap.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     -e MARKLOGIC_INIT=true \
     -v ~/data/MarkLogic:/var/opt/MarkLogic \
     --network ml-cluster-network \
     --dns-search "marklogic.com" \
     marklogic-server:10.0-8.1-centos-1.0.0-ea2
```

#### VM#n

Follow the next steps to set up additonal node (for example ml2) on VM#n.

Run the Docker swarm join command that you got as output when you set up VM#1.

```
$ docker swarm join --token random-string-of-characters-generated-by-docker-swarm-command <VM#1_IP>:2377
```
Above command will add the current node to the swarm intialized above. 

Start the Docker container (ml2.marklogic.com) with MarkLogic Server initialized, and join to the same cluster as you started/initialized on VM#1

```
$ docker run -d -it -p 7200:8000 -p 7201:8001 -p 7202:8002 \
     --name ml2 -h ml2.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME=<insert admin username> \
     -e MARKLOGIC_ADMIN_PASSWORD=<insert admin password> \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_JOIN_CLUSTER=true \
     -v ~/data/MarkLogic:/var/opt/MarkLogic \
     --network ml-cluster-network \
     marklogic-server:10.0-8.1-centos-1.0.0-ea2
```

When you complete these steps, you will have multiple containers; one on each VM and all connected to each other on the 'ml-cluster-network' network. All the containers will be part of same cluster.

## Debugging

### Accessing a MarkLogic Container while its running
Below is a set of steps to run in order to access a container while it is running and do some basic debugging once access is obtained

1. Access the machine running the docker container, this is typically done through SSH or having physical access to the machine.
2. Get the container ID of the running MarkLogic container on the machine

- In the below command store/marklogicdb/marklogic-server:10.0-8.1-centos-1.0.0-ea2 is an image ID this could be different on your machine. 
```
docker container ps --filter ancestor=store/marklogicdb/marklogic-server:10.0-8.1-centos-1.0.0-ea2 -q
```
- Example Output
```
f484a784d998  
```
- If you don't know the image you can search without a filter
```
docker container ps
```

- Example unfiltered output
```
CONTAINER ID   IMAGE                                                        COMMAND                  CREATED          STATUS          PORTS                                  NAMES
f484a784d998   store/marklogicdb/marklogic-server:10.0-8.1-centos-1.0.0-ea2   "/usr/local/bin/star…"   16 minutes ago   Up 16 minutes   25/tcp, 7997-7999/tcp, 8003-8010/tcp, 0.0.0.0:8000-8002->8000-8002/tcp   vibrant_burnell
```
3. Execute a command to access a remote shell onto the container

- In the below command f484a784d998 is the container ID from the prior step, the one given to your container will be different. 
```
docker exec -it f484a784d998 /bin/bash  
```

4. Verify MarkLogic is running
```
sudo service MarkLogic status
```
Example Output:  

```
MarkLogic (pid  34) is running...
```  

5. To read the logs Navigate to `/var/opt/MarkLogic/Logs` and view them in an reader like `vi`
- As an example we can view the 8001 error logs, and list the log directory with a single command
```
sudo cd /var/opt/MarkLogic/Logs && ls && vi ./8001_ErrorLog.txt
```

6. Exit the container, when you've completed debugging, with the exit command
```
exit
```


## Clean up

### Docker secrets removal

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

### Remove volumes

Anonymous volumes can be removed by adding --rm option while running a container. So when the container is removed this anonymous volume will be removed as well.

```
$docker run --rm -v /foo -v awesome:/bar container image
```

To remove all other volumes use below command
```
$docker volume prune
```

### Stop a container

Use below command to stop a running container
```
$docker stop container_name
```

### Remove a container

Use below command to remove a stopped container
```
$docker rm container_name
```

## Known Issues and Limitations

10.0-7.3-centos-1.0.0-ea

1. Enabling huge pages for clusters containing single-host, multi-container configurations may lead to failure, due to incorrect memory allocation. MarkLogic recommends that you disable huge pages in such architectures.
2. Database replication will only work for configurations having a single container per host, with matching hostname.
3. Using the "leave" button in the Admin interface to remove a node from a cluster may not succeed, depending on your network configuration. Use the Management API remove a node from a cluster. See: [https://docs.marklogic.com/REST/DELETE/admin/v1/host-config](https://docs.marklogic.com/REST/DELETE/admin/v1/host-config).
4. Rejoining a node to a cluster, that had previously left that cluster, may not succeed.
5. MarkLogic Server will default to the UTC timezone.
6. By default, MarkLogic Server runs as the root user. To run MarkLogic Server as a non-root user, see the following references:
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