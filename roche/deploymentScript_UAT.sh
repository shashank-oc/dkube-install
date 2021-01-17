#!/bin/bash

# --> SCRIPT IS CONFIGURED TO BE RUN ON ROCHE UAT SETUP <--

# Prints on stdout in colour fonts
RED='\033[0;31m'
GREEN='\033[0;32m'

#******************************************************************************************#
#									USER DEFINED VARIABLES								   #
#******************************************************************************************#
#Enter corresponding value between double quotes
TOKEN=""
HOMEDIR=""
MOUNTNAME=""
VOLUMEHANDLE=${HOMEDIR}

printf "${GREEN}\nPatching dkube-platform-cfg file\n"

kubectl get cm dkube-platform-cfg -n dkube -o json > cm-old.json

#Backup old config file
cp cm-old.json cm-new.json

#Remove dkube rstudio images
jq 'del(.frameworks[].versions[] | select(.caps[] | contains("r-ide")))' cm-new.json > tmp && mv tmp cm-new.json

#Add base domain
jq '.access."base-domain" = "https://www.uat.us.mlaas.apollo.roche.com"' cm-new.json > tmp && mv tmp cm-new.json

#Add jupyter images
jq '.frameworks[3] += {"name":"jupyter", "versions":[]}' cm-new.json > tmp && mv tmp cm-new.json
jq '.frameworks[3].versions += [{"name":"python36", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python36", "port":"8000", "ssl":"false", "caps":[ "jnb-ide"]},{"name":"python36-R351", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python36-R351", "port":"8000", "ssl":"false", "caps":[ "jnb-ide"]},{"name":"python37-R361", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python37-R361", "port":"8000", "ssl":"false", "caps":[ "jnb-ide"]},{"name":"python37", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python37", "port":"8000", "ssl":"true", "caps":[ "jnb-ide"]}]' cm-new.json > tmp && mv tmp cm-new.json

#Add jupyterlab images
jq '.frameworks[4] += {"name":"jupyterlab", "versions":[]}' cm-new.json > tmp && mv tmp cm-new.json
jq '.frameworks[4].versions += [{"name":"tf2.0-py38-cpu", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab-tf2:cpu-tf2", "port":"8000", "ssl":"true", "caps":[ "jlab-ide"]},{"name":"tf2.0-py38-gpu", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab-tf2:gpu-py38", "port":"8000", "ssl":"true", "caps":[ "jlab-ide"]},{"name":"tf2.0-py37-cpu", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab-tf2:cpu-py37", "port":"8000", "ssl":"true", "caps":[ "jlab-ide"]},{"name":"tf2.0-py37-gpu", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab-tf2:gpu-py37", "port":"8000", "ssl":"true", "caps":[ "jlab-ide"]},{"name":"python36", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python36", "port":"8000", "ssl":"false", "caps":[ "jlab-ide"]},{"name":"python36-R351", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python36-R351", "port":"8000", "ssl":"false", "caps":[ "jlab-ide"]},{"name":"python37-R361", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python37-R361", "port":"8000", "ssl":"false", "caps":[ "jlab-ide"]},{"name":"python37", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/jupyterlab:python37", "port":"8000", "ssl":"true", "caps":[ "jlab-ide"]}]' cm-new.json > tmp && mv tmp cm-new.json

#Add rstudio images
jq '.frameworks[5] += {"name":"rstudio", "versions":[]}' cm-new.json > tmp && mv tmp cm-new.json
jq '.frameworks[5].versions += [{"name":"r4.0.0-rstudio1.3", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/rstudio:r4.0.0-rstudio1.3", "port":"8787", "ssl":"true", "caps":[ "r-ide"]},{"name":"r3.6.3-rstudio1.3", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/rstudio:r3.6.3-rstudio1.3", "port":"8787", "ssl":"true", "caps":[ "r-ide"]},{"name":"r3.6.3-rstudio1.2", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/rstudio:r3.6.3-rstudio1.2", "port":"8787", "ssl":"true", "caps":[ "r-ide"]},{"name":"r3.6.1-rstudio1.2", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/rstudio:r3.6.1-rstudio1.2", "port":"8787", "ssl":"true", "caps":[ "r-ide"]},{"name":"r3.5.3-rstudio1.2", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/rstudio:r3.5.3-rstudio1.2", "port":"8787", "ssl":"true", "caps":[ "r-ide"]},{"name":"r3.5.2-rstudio1.2", "image":"507987312224.dkr.ecr.us-west-2.amazonaws.com/rstudio:r3.5.2-rstudio1.2", "port":"8787", "ssl":"true", "caps":[ "r-ide"]}]' cm-new.json > tmp && mv tmp cm-new.json

kubectl create configmap dkube-platform-cfg --from-file=config\.json=cm-new.json -n dkube -o yaml --dry-run | kubectl apply -f -

if [ $? -ne 0 ]; then
	printf "${RED}Failed to patch dkube-platform-cfg\n"
	exit 1
fi

rm -f cm-new.json cm-old.json

printf "${GREEN}\nCreate FSx user profile\n"
curl --insecure -XPOST -H 'Authorization: Bearer ${TOKEN}' -H "Content-type: application/json" -d '{"Kind":"inline","Inline":{"Name":"global","Homedir":"fsx://${HOMEDIR}.fsx.us-west-2.amazonaws.com","options":[{"key":"volumeHandle","value":"${VOLUMEHANDLE}"},{"key":"mountname","value":"${MOUNTNAME}"}],"Limits":{"Cpus":"1"}}}' 'https://www.uat.us.mlaas.apollo.roche.com/dkube/v2/controller/userprofiles'

if [ $? -ne 0 ]; then
	printf "${RED}Failed to create FSx user profile\n"
	exit 1
fi

printf "${GREEN}\nApplying redshift configmap\n"
cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  database_path: /sbx/datasets
  endpoint: https://apollo-datamgmt-sbx.aws.science.roche.com
  metadata_path: /sbx/metadata
  token: 1NfVraHdkX5kfhw0OkbjJ2bOzNKav0pN8XwICg44
kind: ConfigMap
metadata:
  name: redshift-access-info
  namespace: dkube
EOF

if [ $? -ne 0 ]; then
	printf "${RED}Failed to apply redshift configmap\n"
	exit 1
fi

printf "${GREEN}\nAll done!\n"
