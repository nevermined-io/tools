[![banner](https://raw.githubusercontent.com/nevermined-io/assets/main/images/logo/banner_logo.png)](https://nevermined.io)

# Nevermined Tools

> Swiss army knife used for running Nevermined Data Platform

[![Tests](https://github.com/nevermined-io/tools/workflows/Test%20Nevermined%20Tools/badge.svg)](https://github.com/nevermined-io/tools/actions)

---


* [Nevermined Tools](#nevermined-tools)
   * [Prerequisites](#prerequisites)
   * [Get Started](#get-started)
      * [Cleaning your environment first (optional)](#cleaning-your-environment-first-optional)
   * [Get Started on Mac](#get-started-on-mac)
   * [Options](#options)
      * [Component Versions](#component-versions)
      * [All Options](#all-options)
   * [Docker Building Blocks](#docker-building-blocks)
      * [Command Line Interface (CLI)](#command-line-interface-cli)
      * [Marketplace](#marketplace)
      * [Minio](#minio)
      * [The Graph](#the-graph)
      * [Marketplace API](#marketplace-api)
      * [Node](#node)
      * [Compute API](#compute-api)
      * [Keeper Node](#keeper-node)
      * [Faucet](#faucet)
      * [OpenLdap](#openldap)
      * [Dashboard](#dashboard)
   * [Local Network](#local-network)
   * [Compute Stack](#compute-stack)
   * [Local Mnemonic](#local-mnemonic)
   * [Attribution](#attribution)
   * [License](#license)


## Prerequisites

You need to have the newest versions of:

* Linux or macOS. Windows is not currently supported. If you are on Windows, we recommend running the tools inside
  a Linux VM. Another option might be to use the
  [Windows Subsystem for Linux (WSL)](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux).
* [Docker](https://www.docker.com/get-started)
* [Docker Compose](https://docs.docker.com/compose/)
* If you want to use Azure Storage (and you might not), then you must edit the file [`node.env`](node.env) to have
  your Azure credentials.

## Get Started

Once you have all the pre-requisites installed, the first thing we need to do is download the software.

```bash
$ git clone https://github.com/nevermined-io/tools.git
```

If you don't have a Git client, you can download the software from the following URL and unpack in the folder you want:
```
https://github.com/nevermined-io/tools/archive/refs/heads/master.zip
```

Once Nevermined Tools is downloaded (and unpacked) you can go to the folder with the software and run it without any parameters.
The following command will run the main components of a Nevermined deployment:

* A local Ethereum node using Geth with the Nevermined [Smart Contracts](../architecture/contracts/) deployed on it
* An instance of the [Marketplace API](../architecture/marketplace-api/) allowing to register assets Metadata
* An instance of the [Node](../architecture/node/) giving access to off-chain data and services
* An instance of a [Faucet](https://github.com/nevermined-io/faucet/) that can be used to get some ETH in the local network
* An instance of a [SubGraph](https://github.com/nevermined-io/subgraph) node indexing all the events emitted by the Smart Contracts and exposing them via GraphQL

```
$ cd tools
$ ./start_nevermined.sh
```

After running the command you should see something like this:

<img width="486" alt="Welcome to Nevermined" src="Welcome_to_nevermined.png">


After a few minutes you can run the following command to check that all the Contracts were deployed and Nevermined is ready:

```bash
$ ./scripts/wait-nevermined.sh 

Using conf dir: /home/aitor/.nevermined

◯ Waiting for contracts to be generated...
✔ Found new contract artifacts.
[...]
✔ Copied new contract artifacts and circuits.
✔ Nevermined is up and runnning !!!.

```

### Cleaning your environment first (optional)

It's overkill, but to be _sure_ that you use exactly the Docker images and volumes you want, you can prune all the Docker things in your system first:

```bash
docker system prune --all --volumes
```


## Get Started on Mac

Due to the differences between Mac and Linux networking and the imposed limitations by Docker, it might happen that the traditional
_Get Started_ steps won't work on the new M1 Macs.

Additionally in MacOS you will need to export the variable `IP` to your hosts ip. This ip must be resolved by your host instance and the containers.
The IP assigned in your local network should work. If your Mac has only one network interface, you can get run:

```bash
export IP=$(ipconfig getifaddr en0)
```

If you have multiple network interfaces (i.e.: ethernet and wireless), use `en0` if you are connected using ethernet/cable, or `en1` if you are connected using wireless.

We strongly adivse to try out the first path, but if you happen to have difficulties, follow the next steps:

```bash
git clone git@github.com:nevermined-io/tools.git nevermined-tools
cd nevermined-tools

./start_nevermined.sh --latest --no-marketplace
```

This way, a subset of the Nevermined stack will be run, with the Legacy Marketplace ommitted.

The focal point of the setup is the Marketplace API. To try the APIs out navigate to the Swagger API description at

```url
http://metadata:5000/api/v1/docs/
```

You can try it out with exploring the exposed endpoints & dummy requests.

## Options

The startup script comes with a set of options for customizing various things.

### Component Versions

The default versions are always a combination of component versions which are considered stable.

| Contracts       | Marketplace API | Node   | Faucet   |
| --------------- | --------- | -------- | ----------------- |
| `v2.1.0`        | `latest`  | `latest` | `v0.2.2`          |

You can use the `--latest` option to pull the most recent Docker images for all components, which are always tagged as
`latest` in Docker. The `latest` Docker image tag derives from the default main branch of the component's Git repo.

You can override the Docker image tag used for a particular component by setting its associated environment variable before calling `start_nevermined.sh`:

* `MARKETPLACE_API_VERSION`
* `NODE_VERSION`
* `KEEPER_VERSION`
* `MARKETPLACE_CLIENT_VERSION`
* `MARKETPLACE_SERVER_VERSION`
* `FAUCET_VERSION`

For example:

```bash
export NODE_VERSION=v0.3.0
./start_nevermined.sh
```

will use the default Docker image tags for Metadata API, Nevermined Contracts and Marketplace, but `v0.4.3` for the Node.

> If you use the `--latest` option, then the `latest` Docker images will be used _regardless of whether you set any environment variables beforehand._

### All Options

| Option                     | Description                                                                                           |
| -------------------------- | ----------------------------------------------------------------------------------------------------- |
| `--latest`                 | Pull Docker images tagged with `latest`.                                                              |
| `--no-marketplace`         | Start up without the `marketplace` Building Block. Helpful when you are developing the `marketplace`. |
| `--no-metadata`            | Start up without the `metadata` Building Block.                                                       |
| `--no-gateway`             | Start up without the `gateway` Building Block.                                                        |
| `--no-secret-store`        | Start up without the `secret-store` Building Block.                                                   |
| `--no-faucet`              | Start up without the `faucet` Building Block.                                                         |
| `--no-elastic`             | Start up without ElasticSearch.                                                                       |
| `--no-graph`               | Start up without the `graph` node for the Nevermined events.                                     |
| `--compute`                | Start up with the Nevermined compute components.                                                      |
| `--ldap`                   | Start an OpenLdap instance use for keeping the users and groups authentication.                       |
| `--dashboard`              | Start up with the `dashboard` for monitoring containers.                                              |
| `--minio`                  | Start up with the `minio` for the Nevermined arts marketplace.                                                            |
| `--polygon-localnet`       | Start up with the a polygon local node for the Nevermined events.                                     |
| `--local-ganache-node`     | Runs a local `ganache` node.                                                                          |
| `--local-node` or `--geth` | Runs a node of the local `geth-localnet` network. This is the default.                                        |
| `--local-rinkeby-node`     | Runs a local parity node and connects the node to the `rinkeby` testnet network                       |
| `--local-integration-node` | Runs a local parity node and connects the node to the `integration` network.                          |
| `--local-staging-node`     | Runs a local parity node and connects the node to the `staging` network.                              |
| `--local-production-node`  | Runs a local parity node and connects the node to the `production` network                            |
| `--reuse-ganache-database` | Configures a running `ganache` node to use a persistent database.                                     |
| `--force-pull`             | Force pulling the latest revision of the used Docker images.                                          |
| `--purge`                  | Removes the Docker containers, volumes, artifact folder and networks used by the script.              |
| `--exposeip`               | Binds the components to that specific ip. Exemple: ./start_nevermined.sh --exposeip 192.168.0.1       |
| `--deattached`             | Starts the Docker containers in deattached mode                                                       |

## Docker Building Blocks

Barge consists of a set of building blocks that can be combined to form a local test environment. By default all
building blocks will be started by the `start_nevermined.sh` script.

### Command Line Interface (CLI)

The command line interface allows to interact with your Nevermined environment in an easy way.
If you want to use the CLI in your shell we recommend to install in your local environment using the command:

```bash
yarn global add @nevermined-io/cli

OR 

npm install -g @nevermined-io/cli
```

This will allow to interact with Nevermined using the `ncli` command.

For more information about different options and/or configuration please visit the [CLI repository](https://github.com/nevermined-io/cli).

### Marketplace

By default it will start two containers (client & server). If the Marketplace is running, you can open the **Marketplace Frontend**
application in your browser:

[http://localhost:3000](http://localhost:3000)

This Building Block can be disabled by setting the `--no-marketplace` flag.

| Hostname             | External Port | Internal URL                     | Local URL               | Description                                                        |
| -------------------- | ------------- | -------------------------------- | ----------------------- | ------------------------------------------------------------------ |
| `marketplace-client` | `3000`        | <http://marketplace-client:3000> | <http://localhost:3000> | [Marketplace Client](https://github.com/nevermined-io/marketplace) |
| `marketplace-server` | `4000`        | <http://marketplace-server:4000> | <http://locahost:4000>  | [Marketplace Server](https://github.com/nevermined-io/marketplace) |


### Minio

When passing `--minio` option it will start a minio container

[http://localhost:9000](http://localhost:9000)

| Hostname           | External Port | Internal URL                   | Local URL               | Description           |
| ------------------ | ------------- | ------------------------------ | ----------------------- | --------------------- |
| `nevermined-minio` | `9000`        | <http://nevermined-minio:9000> | <http://localhost:9000> | Minio used by bazaart |

### The Graph

When passing `--graph` option it will start a graph-node container to index Nevermined events.

[http://localhost:9000](http://localhost:9000)

| Hostname           | External Port | Internal URL                   | Local URL               | Description                  |
| ------------------ | ------------- | ------------------------------ | ----------------------- | ---------------------------- |
| `nevermined-graph` | `9000`        | <http://nevermined-graph:9000> | <http://localhost:9000> | The Graph used by Nevermined |


### Marketplace API

The Marketplace API is a RESTful micro-service that exposes common functionalities that allow building Marketplaces or Dapps around digital assets. 
When passing `--marketplace-api` option it will start the [Marketplace API](https://github.com/nevermined-io/marketplace-api) container. If the API is running, you can open the **API Swagger interface** in your browser:

[http://localhost:3100/api/v1/docs](http://localhost:3100)

| Hostname         | External Port | Internal URL                 | Local URL               | Description                                                   |
| ---------------- | ------------- | ---------------------------- | ----------------------- | ------------------------------------------------------------- |
| `marketplace-api` | `3100`        | <http://marketplace-api:3100> | <http://locahost:3100>  | [Marketplace API](https://github.com/nevermined-io/marketplace-api) |

### Node

By default it will start one container. This Building Block can be disabled by setting the `--no-node` flag.

| Hostname  | External Port | Internal URL          | Local URL               | Description                                         |
| --------- | ------------- | --------------------- | ----------------------- | --------------------------------------------------- |
| `node` | `8030`        | <http://node:8030> | <http://localhost:8030> | [Node](https://github.com/nevermined-io/node-ts) |

### Compute API

By default it will start one container. This Building Block can be enabled by setting the `--compute` flag.

| Hostname      | External Port | Internal URL              | Local URL               | Description                                                 |
| ------------- | ------------- | ------------------------- | ----------------------- | ----------------------------------------------------------- |
| `compute-api` | `8050`        | <http://compute-api:8050> | <http://localhost:8050> | [Compute API](https://github.com/nevermined-io/compute-api) |

### Keeper Node

Controlled by the `--local-*-node` config switches will start a container `keeper-node` that uses port `8545` to expose an rpc endpoint to the Ethereum Protocol.
You can find a detailed explanation of how to use this in the [script options](#script-options) section of this document.

| Hostname      | External Port | Internal URL              | Local URL               | Description          |
| ------------- | ------------- | ------------------------- | ----------------------- | -------------------- |
| `keeper-node` | `8545`        | <http://keeper-node:8545> | <http://localhost:8545> | An Ethereum RPC node |

This node can be one of the following types (with the default being `geth-localnet`):

| Node          | Description                                                                                                                                                                                                              |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `ganache`     | Runs a local [ganache-cli](https://github.com/trufflesuite/ganache-cli) node that is not persistent by default. The contracts from the desired `nevermined-contracts` version will be deployed upon launch of this node. |
| `geth-localnet`       | This is the default. Runs a local node of the `geth-localnode` Network. The contracts from the desired `nevermined-contracts` version will be deployed upon launch of this node.   |
| `rinkeby`     | Runs a local node connected to the Ethereum [Rinkeby Testnet](https://www.rinkeby.io/).                                                                                                                                  |
| `integration` | Runs a local node connected to the Integration Network.                                                                                                                                                                  |
| `staging`     | Runs a local node connected to the Staging Network.                                                                                                                                                                      |
| `production`  | Runs a local node connected to the Production Network.                                                                                                                                                                   |

### Faucet

By default it will start two containers, one for Faucet server and one for its database (ElasticSearch). This Building Block can be disabled by setting the `--no-faucet` flag.

| Hostname | External Port | Internal URL         | Local URL               | Description                                       |
| -------- | ------------- | -------------------- | ----------------------- | ------------------------------------------------- |
| `faucet` | `3001`        | <http://faucet:3001> | <http://localhost:3001> | [Faucet](https://github.com/nevermined-io/faucet) |

By default the Faucet allows requests every 24hrs. To disable the timespan check you can pass `FAUCET_TIMESPAN=0` as
environment variable before starting the script.

### OpenLdap

If the `--ldap` flag is given an OpenLdap service will be started.

* User: `admin`
* Password: `nevermined`

| Hostname   | External Port | Internal URL        | Local URL             | Description                                           |
| ---------- | ------------- | ------------------- | --------------------- | ----------------------------------------------------- |
| `openldap` | `1389`        | ldap://openldap:389 | ldap://localhost:1389 | [OpenLdap](https://github.com/dinkel/docker-openldap) |

### Dashboard

This will start a `portainer` dashboard with the following admin credentials and connects to the local docker host. This Building Block can be enabled by setting the `--dashboard` flag.

* User: `admin`
* Password: `nevermined`

| Hostname    | External Port | Internal URL            | Local URL               | Description                                         |
| ----------- | ------------- | ----------------------- | ----------------------- | --------------------------------------------------- |
| `dashboard` | `9000`        | <http://dashboard:9000> | <http://localhost:9000> | [Portainer](https://github.com/portainer/portainer) |

## Local Network

If you run the `./start_nevermined.sh` script with the `--local` or `--geth` option (please see [Keeper Node](#keeper-node) section of this document for more details),
you will have available a keeper node in the local and private network with the following accounts enabled:

| Account                                      | Type     | Password/Key                 | Balance          |
| -------------------------------------------- | -------- | ---------------------------- | ---------------- |
| `0x00Bd138aBD70e2F00903268F3Db08f2D25677C9e` | key      | node0                        | 1000000000 Ether |
| `0x068Ed00cF0441e4829D9784fCBe7b9e26D4BD8d0` | key      | secret                       | 1000000000 Ether |
| `0xA99D43d86A0758d5632313b8fA3972B6088A21BB` | key      | secret                       | 1000000000 Ether |
| `0xe2DD09d719Da89e5a3D0F2549c7E24566e947260` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0xBE5449a6A97aD46c8558A3356267Ee5D2731ab5e` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0xA78deb2Fa79463945C247991075E2a0e98Ba7A09` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0x02354A1F160A3fd7ac8b02ee91F04104440B28E7` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0xe17D2A07EFD5b112F4d675ea2d122ddb145d117B` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0xA32C84D2B44C041F3a56afC07a33f8AC5BF1A071` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0xFF3fE9eb218EAe9ae1eF9cC6C4db238B770B65CC` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0x529043886F21D9bc1AE0feDb751e34265a246e47` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0xe08A1dAe983BC701D05E492DB80e0144f8f4b909` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |
| `0xbcE5A3468386C64507D30136685A99cFD5603135` | mnemonic | [info here](#local-mnemonic) | 1000000000 Ether |

Use one of the above accounts to populate `PROVIDER_ADDRESS`, `PROVIDER_PASSWORD` and `PROVIDER_KEYFILE` in `start_nevermined.sh`.
This account will is used in `node` and `events-handler` as the `provider` account which is important for processing the
service agreements flow. The `PROVIDER_KEYFILE` must be placed in the `accounts` folder and must match the ethereum
address from `PROVIDER_ADDRESS`. The `PROVIDER_ADDRESS` is also set in `marketplace` instance so that published assets get
assigned the correct provider address.

## Compute Stack

To facilitate the deployment in local of the Nevermined compute stack there is a script called `scripts/setup_compute_stack.sh`.
This script will be in charge of:

* Install Minikube
* Install Helm
* Install the Argo Helm chart
* Configure the namespace and permissions

So if you want to run the compute stack locally, before running the `start_nevermined.sh` you can run the `scripts/setup_compute_stack.sh` script.

## Local Mnemonic

The accounts from type mnemonic can be access with this seedphrase:

`taxi music thumb unique chat sand crew more leg another off lamp`

## Attribution

This project is based in the [Ocean Protocol Barge](https://github.com/oceanprotocol/barge).
It keeps the same Apache v2 License and adds some improvements. See [NOTICE file](NOTICE).

## License

```
Copyright 2022 Nevermined AG
This product includes software developed at
BigchainDB GmbH and Ocean Protocol (https://www.oceanprotocol.com/)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
