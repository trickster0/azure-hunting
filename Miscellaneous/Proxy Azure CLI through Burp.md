# Proxy Azure CLI through Burp

Proxying Azure CLI through Burp Suite can be very useful to get a list of pre-constructed and working requests to the ARM or Graph API.


# Instructions

#### 1. Enable a proxy listener in Burp on its <u>external</u>-facing interface (i.e. not localhost!)


#### 2. Export your Burp Certificate in DER format

`Proxy > Options > CA Certificate > Export in DER format`


#### 3. Convert the certificate from DER to PEM

`openssl x509 -inform der -in cacert.der -out burp.pem`


#### 4. Set the Azure CLI specific and system proxy environment variables

`$ export REQUESTS_CA_BUNDLE=<path_to_burp_certificate_in_PEM_format>`

`$ export HTTP_PROXY=http://<ip_address_of_host_running_burp>:8080`

`$ export HTTPS_PROXY=https://<ip_address_of_host_running_burp>:8080`


# Usage

Use Azure CLI as normal


# Reference

https://docs.microsoft.com/en-us/cli/azure/use-cli-effectively?view=azure-cli-latest#work-behind-a-proxy


# Extra

## Looking for proxying curl through Burp?

`$ curl -k --proxy <ip_address_of_host_running_burp>:8080 http://www.google.com`

## Looking for proxying kubectl through Burp?

kubectl allows seeing the requests that are sent by the client using the `-v=10` switch
