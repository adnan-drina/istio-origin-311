#!/usr/bin/env bash

echo "###############################################################################"
echo "#  MAKE SURE YOU ARE LOGGED IN:                                               #"
echo "#  $ oc login http://console.your.openshift.com                               #"
echo "###############################################################################"

function usage() {
    echo
    echo "Usage:"
    echo " $0 [base-dir] [run]"
    echo " $0 --help"
    echo
    echo "Example:"
    echo " $0 --base-dir ./okd/istio/cluster-up --run 01"
    echo
    echo "OPTIONS:"
    echo "   --base-dir [directory]     The directory for storing cluster configuration"
    echo "   --run [number] 			Installation run identifier"
    echo
}

# Turn colors in this script off by setting the NO_COLOR variable in your
# environment to any value:
#
# $ NO_COLOR=1 test.sh
NO_COLOR=${NO_COLOR:-""}
if [ -z "$NO_COLOR" ]; then
  header=$'\e[1;33m'
  reset=$'\e[0m'
else
  header=''
  reset=''
fi

ARG_BASEDIR=./okd/istio/cluster-up-istio
while :; do
    case $1 in
        --base-dir)
            if [ -n "$2" ]; then
                ARG_BASEDIR=$2
                shift
            else
                printf 'ERROR: "--base-dir" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        --run)
            if [ -n "$2" ]; then
                ARG_RUN=-$2
                shift
            else
                printf 'ERROR: "--run" requires a non-empty value.\n' >&2
                usage
                exit 255
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *) # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

function header_text {
  echo "$header$*$reset"
}

header_text "Starting Istio tinstallation on OpenShift Origin!"

echo "Using oc version:"
oc version

header_text "Writing config"
#oc cluster up --write-config
#oc cluster up --base-dir=./okd/istio/cluster-up-istio
oc cluster up --base-dir=$ARG_BASEDIR$ARG_RUN --write-config
sed -i -e 's/"admissionConfig":{"pluginConfig":null}/"admissionConfig": {\
    "pluginConfig": {\
        "ValidatingAdmissionWebhook": {\
            "configuration": {\
                "apiVersion": "v1",\
                "kind": "DefaultAdmissionConfig",\
                "disable": false\
            }\
        },\
        "MutatingAdmissionWebhook": {\
            "configuration": {\
                "apiVersion": "v1",\
                "kind": "DefaultAdmissionConfig",\
                "disable": false\
            }\
        }\
    }\
}/' $ARG_BASEDIR$ARG_RUN/kube-apiserver/master-config.yaml
#openshift.local.clusterup/kube-apiserver/master-config.yaml

header_text "Starting OpenShift"
oc cluster up --base-dir=$ARG_BASEDIR$ARG_RUN --server-loglevel=5

header_text "Logging in as system:admin and setting up default namespace"
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin

header_text "Upgrade the node configuretion"
NODE=$(docker ps -f name=origin --format "{{.ID}}")
docker cp https://raw.githubusercontent.com/adnan-drina/istio-origin-311/master/99-elasticsearch.conf $NODE:/etc/sysctl.d/99-elasticsearch.conf
docker exec -it $NODE sysctl vm.max_map_count=262144

header_text "Setting up the istio operator"
oc new-project istio-operator
oc new-app -f https://raw.githubusercontent.com/adnan-drina/istio-origin-311/master/istio_operator_template_origin.yaml

header_text "Installing istio components"
oc create -f https://raw.githubusercontent.com/adnan-drina/istio-origin-311/master/istio-installation.yaml -n istio-operator

header_text "Waiting for components to become ready"
sleep 5; while echo && oc get pods -n istio-system | grep -v -E "(Running|Completed|STATUS)"; do sleep 5; done
