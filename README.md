# OpenShift 3.11 HA cluster deployment

1. Login to the bastion host

	``` bash
	 ssh -i <path/to/key> <login_id>@bastion.$GUID.example.opentlc.com
	 ```
2. Login as root user
	``` bash
	sudo su -
	```
3. Clone Repo
	``` bash
  	# git clone https://github.com/adnan-drina/ocp_311_deployment.git
	```
	``` bash
	# cd ocp_311_deployment/ 
	```
4. To start the installation
	``` bash
	# ansible-playbook ./ocp_deployment.yaml