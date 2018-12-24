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
		$ sudo htpasswd -c -b /etc/origin/master/htpasswd developer developer
		$ sudo htpasswd -c -b /etc/origin/master/htpasswd developer developer
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
		$ docker container restart
	```
5. Upgrade the node configuretion on each node within your OpenShift Container Platform

	Create a file named /etc/sysctl.d/99-elasticsearch.conf with the following contents:
	```
		vm.max_map_count = 262144
	```
	Execute the following command:
	```	
		$ sysctl vm.max_map_count=262144
	``` 

6. 