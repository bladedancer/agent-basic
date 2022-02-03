# Helm chart for Amplify Gateway's proxy

## Note
This chart is for the **Proxy** only. You will need to install the Amplify Gateway **Governance Agent**
chart also. It is recommended that you install the main **ampgw** chart in order to ensure your
environment is provisioned correctly. The main chart will install all sub-charts. If you install the charts
individually you must manually provision the following api-server resources in Central:
* `Environment`
* `Secret`
* `AmplifyConfig`
* `GovernanceAgent`

## Prerequisites

In order to install this chart you need the following:

* Access to a Kubernetes cluster
* Kubernetes client i.e. kubectl
* Helm client
* Access to Amplify Platform and Amplify Central

## Installation steps

Before installing this chart you need to create the following things:

* An Amplify Platform service account. You can create this in the Amplify Platform UI on https://platform.axway.com.
* Your Amplify Platform organization ID, this can be found on the Amplify Platform UI if you navigate to your 
  Organization page.
* A private key and certificate for the Amplify Gateway listener port for API traffic.
* A Kubernetes secret that contains the key pair for the service account required to connect to
  Amplify Platform
* A YAML file to customize the chart to your environment if you wish to override any defaults

### Create a Self Signed key pair for the Listener

You can use a self-signed certificate for demo purposes. The certificate created below has a wildcard CN of
`*.ampgw.com`. There is no requirement for it to be `*.ampgw.com`. Edit this to be whatever you require.
When you deploy your virtual APIs you must set the `virtualHost` value to something ending in `.ampgw.com`
e.g. `myapi.ampgw.com`.

All deployed APIs will be available on `https://???.ampgw.com:4443`.

Create a self-signed key pair as follows:
``` sh
openssl req -x509 -newkey rsa:4096 -keyout listener_private_key.pem -nodes -out listener_certificate.pem \
-days 365 -subj '/CN=*.ampgw.com/O=Axway/C=IE'
``` 

### Create the Kubernetes secret

Before you run the command below you must have the following files in your current directory:-
* **private_key.pem** - The private key for the Platform service account
* **public_key.pem** - The public key for the Platform service account
* **listener_private_key.pem** - The private key for the data plane listener TLS port
* **listener_certificate.pem** - The certificate for the data plane listener TLS port

Edit the command below if your filenames or paths on your local machine differ.
You must not edit the names **privateKey**, **publicKey**, **listenerPrivateKey**, **listenerCertificate**,
**orgId**, or **clientId** as the Helm charts depend on these.

You must also have the following info:-
* The service account client ID
* Your org ID

Create the Kubernetes secret named **ampgw-secret** as follows:-

``` sh
kubectl create secret generic ampgw-secret \
    --from-file serviceAccPrivateKey=private_key.pem \
    --from-file serviceAccPublicKey=public_key.pem \
    --from-file listenerPrivateKey=listener_private_key.pem  \
    --from-file listenerCertificate=listener_certificate.pem \
    --from-literal orgId=<YOUR PLATFORM ORG ID> \
    --from-literal clientId=<YOUR PLATFORM SERVICE ACCOUNT CLIENT ID>
```

The output should be :

``` sh
secret/ampgw-secret created
```
This secret must be named <b>ampgw-secret</b>, do not rename it as the Helm charts depend on this name.

### Customize the chart to you environment

Run this command to list all values that can be customized.
`chart_url` is the URL of this chart.

``` sh
kubectl show values <chart_url>
```

For a basic setup you do not need to override any settings. Optionally, customize the default settings via an
override file as below to change the following:-

* Create the Environment with a non-default
  name such as _my-env_, (the default is _amplify-gateway-env_).
* Use 5555 as the data plane listener port, (the default is 4443).
* Set log levels to debug for envoy.
* Expose the proxy admin port on 9901.

```yaml
global:
  environment: my-env
  listenerPort: 5555
  exposeProxyAdminPort: true

env:
  LOGLEVEL: debug
```

Copy these keys into a new yaml file and update the values according to your requirements.
This file can be used when installing the chart if you pass it using `-f` at the command line, see below.

### Install the chart

To install, use `helm install` as follows:

``` sh
helm install <name> <chart_url>
```

where `name` is the name of your helm release, and `chart_url` the URL of the chart.

Alternatively, use an override file as follows:

``` sh
helm install <name> <chart_url> -f your_values.yaml
```

where `your_values.yaml` is the yaml file with your override settings.

