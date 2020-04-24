# Tyk Demo

This repo provides an example installation of Tyk. It uses Docker Compose to provide a quick, simple demo of the Tyk stack, this includes the Gateway, the Dashboard and the Portal.

# Getting Started

Note that all commands provided here should be run from the root directory of the repo.

## Step 1: Add your Dashboard licence

The `docker-compose.yml` file uses a Docker environment variable to set the dashboard licence. To set this, create a file called `.env` in the root directory of the repo, then set the content of the file as follows, replacing `<YOUR_LICENCE>` with your Dashboard licence:

```
DASHBOARD_LICENCE=<YOUR_LICENCE>
```

## Step 2: Initialise the Docker containers

Run Docker compose:

```
docker-compose up -d
```

Using `-d` creates the containers in detached mode, running them in the background.

Please note that this command may take a while to complete, as Docker needs to download images and provision the containers.

## Step 3: Install dependencies

### JQ

The bootstrap script uses JQ for extracting data from JSON object. Can be installed as follows:

```
brew install jq
```

## Step 4: Bootstrap the system

Now we will run the bootstrap script, which will complete the remaining items needed to get started. But before the `bootstrap.sh` file can be run, it must be made executable:

```
chmod +x bootstrap.sh
```

Now you can run the file, passing the admin user's `Tyk Dashboard API Access Credentials` and `Organisation ID` as arguments:

```
./bootstrap.sh
```

## Step 5: Log into the Dashboard

Check the last few lines of output from the `bootstrap.sh` command, these will contain your Dashboard login credentials.

When you log into the Dashboard, you will find the imported APIs and Policies are now available.

## Step 6: Import API requests into Postman

There is a Postman collection built to compliment the API definitions, such that you can start using Tyk features and functionality straight away.

Import the `Tyk Demo.postman_collection.json` into your Postman to start making requests.

# Resetting

The purpose of the `bootstrap.sh` script is to enable the environment to be easily set up from scratch. If you want to reset your environment then you need to remove the volumes associated with the container as well as the containers themselves.

To bring down the containers and delete asscociated volumes:

```
docker-compose down -v
```

Or, if you want to retain the existing data then just remove the containers:

```
docker-compose down
```

# Applications available

The following applications are available once the system is bootstrapped:

- [Tyk Dashboard](http://localhost:3000)
- [Tyk Dashboard using SSO](http://localhost:3001)
- [Tyk Dashboard environment 2](http://localhost:3002)
- [Tyk Portal](http://localhost:3000/portal)
- [Tyk Gateway](http://localhost:8080/basic-open-api/get)
- [Tyk Gateway using TLS](https://localhost:8081/basic-open-api/get) (using self-signed certificate, so expect a warning)
- [Tyk Gateway environment 2](http://localhost:8085/basic-open-api/get)
- [Kibana](http://localhost:5601)

# Synchronisations of API and Policies

The files in `data/tyk-sync` are API and Policy definitions which are used to store the common APIs and Policies which this demo uses.

There are two scenarios for working with this data:

1. You have made changes and want to commit them so that others can get them
2. You want to get the changes other people have made

## Scenario 1: Committing changes

If you have changed APIs and Policies in your Dashboard, and want to commit these so other people can use them, use the `dump.sh` script, which is pre-configured to call the `tyk-sync dump` command using your local Dashboard user API credentials:

```
./dump.sh
```

This will update the files in the `data/tyk-sync` directory. You can then commit these files into the repo.

## Scenario 2: Synchronising updates

If you want to get the changes other people have made, first pull from the repo, then use the `sync.sh` script, which calls the `tyk-sync sync` command using your local `.organisation-id` and `.dashboard-user-api-credentials` files.

**Warning:** This command is a hard sync which will **delete** any APIs and Policies from your Dashboard that do not exist in the source data.

```
./sync.sh
```

# Using Elasticsearch & Kibana

The Tyk Pump is already configured to push data to the Elasticsearch container, so Kibana can visualise this data.

The bootstrap process creates an Index Pattern and Visualization which can be used to view API analytics data.

Go to http://localhost:5601/app/kibana to access Kibana and view the visualisation.

# SSO Dashboard

**Note:** This example is not very configurable right now, since it relies on a specific Okta setup which is only configurable by the owner of the Okta account (i.e. not you!). Would be good to change this at some point to use a self-contained method which can be managed by anyone. Please feel free to implement such a change an make a pull request. Anyway, here's the SSO we have...

The `dashboard-sso` container is set up to provide a Dashboard using SSO. It works in conjunction with the Identity Broker and Okta to enable this.

If you go to SSO-enabled Dashboard http://localhost:3001 (in a private browser session to avoid sending any pre-existing auth cookies) it will redirect you to the Okta login page, where you can use these credentials to log in:

  - Admin user:
    - Username: `dashboard.admin@example.org`
    - Password: `Abcd1234`
  - Read-only user:
    - Username: `dashboard.readonly@example.org`
    - Password: `Abcd1234`
  - Default user: (lowest permissions)
    - Username: `dashboard.default@example.org`
    - Password: `Abcd1234`

This will redirect back to the Dashboard, using a temporary session created via the Identity Broker and Dashboard SSO API.

Functionality is based on the `division` attribute of the Okta user profile and ID token. The value of which is matched against the `UserGroupMapping` property of the `tyk-dashboard` Identity Broker profile.

# Scaling the solution

Run the `add-gateway.sh` script to create a new Gateway instance. It will behave like the existing `tyk-gateway` container as it will use the same configuration. The new Gateway will be mapped on a random port, to avoid collisions.

# Jenkins

Jenkins is used to provide an automated way of pushing API Definitions and Policies to different Tyk environments. It uses the `tyk-sync` CLI tool and a Github repository to achieve this.

The `docker-compose.yml` has some services prefixed with `e2`. These represent a separate Tyk environment, with an independent Gateway, Dashboard, Pump and databases. We can use Jenkins to automate the deployment of API Definitions and Policies from the default environment to the e2 environment.

## Setup

Setting up Jenkins is a manual process:

1. Browse to [Jenkins web UI](http://localhost:8070)
2. Use the Jenkins admin credentials provided by the `bootstrap.sh` script to log in
3. Install suggested plugins
4. Add credentials: (these are needed by `tyk-sync` to push data into the e2 Dashboard)
  - Kind: Secret text
  - Scope: Global (this is just a PoC...)
  - Secret: The e2 Dashboard API credentials, shown in `Creating Dashboard user for environment 2` section of the `bootstrap.sh` output
  - ID: `tyk-dash-secret`
  - Description: `Tyk Dashboard Secret`
5. Create a new job:
  - Name: `APIs and Policies`
  - Type: Multibranch Pipeline
  - Branch Source: Github
  - Branch Source Credentials: Your Github credentials (to avoid using anonymous GitHub API usage, which is very restrictive)
  - Branch Source -> Repository HTTPS URL: Github URL for this repository
  - Build Configuration -> Script Path: `data/jenkins/Jenkinsfile`

Ideally, this will be automated in the future.

## Usage

After the setup process is complete, the CI/CD functionality can be demonstrated as follows:

1. Log into the [e2 Dashboard](http://localhost:3002) (using credentials shown in `bootstrap.sh` output, and a private browser session to avoid invalidating your session cookie for the default Dashboard)
2. You will see that there are no API Definitions or Policies
3. Build the `APIs and Polcies` job in Jenkins
4. Check the e2 Dashboard again, you will now see that it has the same API Definitions and Policies as the default Dashboard.
5. Check that the e2 Gateway can proxy requests for these APIs by making a request to the [Basic Open API](http://localhost:8085/basic-open-api)

## Jenkins CLI

The Jenkins CLI is set up as part of the `bootstrap.sh` process. This may be useful for importing job data etc. See [the Jenkins wiki](https://wiki.jenkins.io/display/JENKINS/Jenkins+CLI) and [Jenkins commands](http://localhost:8070/cli/) for reference.

Commands can be sent to the CLI via docker. Here's an example which gets the 'APIs and Policies' Job we created, but replace `f284436d222a4d73841ae92ebc5928e8` with your Jenkins admin password:

```
docker-compose exec jenkins java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080/ -auth admin:f284436d222a4d73841ae92ebc5928e8 -webSocket get-job 'APIs and Policies'
```
