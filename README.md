# OKD 3.11 Installing Istio Service Mesh

1. Install 3.11 version of the OpenShift Container Platform command line utility (the oc client tool). For installation instructions, see the OpenShift Container Platform Command Line Reference document.

	``` 
		$ oc version
		oc v3.11.0+0cbc58b
		kubernetes v1.11.0+d4cacc0
	 ```
2. Start your local cluster (--base-dir Directory on Docker host for cluster up configuration)
	``` 
		$ oc cluster up --base-dir=./okd/cluster-up-istio
	```
3. Create users
	``` 
		$ oc login -u system:admin
		$ sudo htpasswd -c -b /etc/origin/master/htpasswd admin r3dh4t1!
		$ sudo htpasswd -c -b /etc/origin/master/htpasswd developer r3dh4t1!
		$ oc adm policy add-cluster-role-to-user cluster-admin admin
	```
4. Make the following changes on each master within your OpenShift Container Platform installation:

	Change to the directory containing the master configuration file (for example, /etc/origin/master/master-config.yaml).

	Create a file named master-config.patch with the following contents:

	```	
		admissionConfig:
		  pluginConfig:
		    MutatingAdmissionWebhook:
		      configuration:
		        apiVersion: apiserver.config.k8s.io/v1alpha1
		        kubeConfigFile: /dev/null
		        kind: WebhookAdmission
		    ValidatingAdmissionWebhook:
		      configuration:
		        apiVersion: apiserver.config.k8s.io/v1alpha1
		        kubeConfigFile: /dev/null
		        kind: WebhookAdmission
	```
	In the same directory, issue the following commands to apply the patch to the master-config.yaml file:

	``` 
		$ cp -p master-config.yaml master-config.yaml.prepatch
		$ oc ex config patch master-config.yaml.prepatch -p "$(cat master-config.patch)" > master-config.yaml
		$ docker container restart <docker_id>
	```
5. Upgrade the node configuretion on each node within your OpenShift Container Platform
	```
		docker exec -it <container name> /bin/bash
	```
	```
		$ touch /etc/sysctl.d/99-elasticsearch.conf
		$ vi /etc/sysctl.d/99-elasticsearch.conf
	```
	```
		vm.max_map_count = 262144
	```
	Execute the following command:
	```	
		$ sysctl vm.max_map_count=262144
	``` 

# Installing Service Mesh

6. The following commands install the Service Mesh operator
	```
		$ oc new-project istio-operator
		$ oc new-app -f https://raw.githubusercontent.com/adnan-drina/istio-origin-311/master/istio_operator_template_origin.yaml
	```
7. To deploy the control plane, run the following command:
	```
		$ oc create -f https://raw.githubusercontent.com/adnan-drina/istio-origin-311/master/istio-install.yaml -n istio-operator
	```

8. Verifying the installation
	After the openshift-ansible-istio-installer-job has completed, run the following command:
	```
		$ oc get pods -n istio-system
	```
	Verify that you have a state similar to the following:
	```
		NAME                                          READY     STATUS      RESTARTS   AGE
		elasticsearch-0                               1/1       Running     0          2m
		grafana-6887dd6bd6-rqh8b                      1/1       Running     0          2m
		istio-citadel-55df4f4fcd-4bkd7                1/1       Running     0          3m
		istio-egressgateway-7c8fc8c488-cl8l2          1/1       Running     0          3m
		istio-galley-5988bfff67-q6pn8                 1/1       Running     0          3m
		istio-ingressgateway-6985bccb6c-kxbl5         1/1       Running     0          3m
		istio-pilot-6dc5cffcf5-q2f88                  2/2       Running     0          3m
		istio-policy-5c5d47ccf4-z77nl                 2/2       Running     0          3m
		istio-sidecar-injector-c568c7959-8b6x5        1/1       Running     0          3m
		istio-telemetry-9bc946ccc-j4d29               2/2       Running     0          3m
		jaeger-agent-cxr5p                            1/1       Running     0          2m
		jaeger-collector-565dffbb9b-f67v6             1/1       Running     1          2m
		jaeger-query-6bb87dcb78-jjbwj                 1/1       Running     1          2m
		kiali-594cbc76f8-8rhvg                        1/1       Running     0          2m
		openshift-ansible-istio-installer-job-6hwqm   0/1       Error       0          6m
		openshift-ansible-istio-installer-job-mlzht   0/1       Error       0          6m
		openshift-ansible-istio-installer-job-trs2d   0/1       Completed   0          5m
		prometheus-76db5fddd5-txmlm                   1/1       Running     0          3m
	```

ref: https://docs.openshift.com/container-platform/3.11/servicemesh-install/servicemesh-install.html