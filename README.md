# Setup for K8s Workshop

# Settings
Create a file .env and set

```shell
NUM_VMS=3
# VM_NAMES_FILE="${PROJECT_DIR}/.vm-names.env"
GROUP=vm-test
VM_USER=ubuntu
VM_ID_FILE=$HOME/.ssh/aws-ssh-sn-azubi-lab.pem
LAB_USER=lab
LAB_PASSWD="My-1-Secret!"
CLOUDFLARE_API_TOKEN=myCloudflareToken
```
# Create Resources
The script `setup.sh` creates a security group, the EC2 instances and the DNS records in Cloudflare.

```shell
./setup.sh
```
# Delete Resources
The script `clean.sh` deletes all resources created by `setup.sh`.
