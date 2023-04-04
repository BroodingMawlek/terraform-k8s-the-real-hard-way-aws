# Notes

## Important

Manually changed sg rule to allow ssh from london office


## Changes

Changed provider configuration to 0.13\
Changed tags to tag in aws_autoscaling_group\
Moved all files into modules\
Moved user-data into ./user-data

## Documentation notes
To ssh to the bastion\
ssh -i <public_key ec2-user@<bastion-public-ip>\
Must use specific Kubernetes version or will get errors due to missing fields
Re-deploying servers will cause cert problems

## Improvements
Enable session manager and remove bastion\
Change the name of the internal and external elbs which are currently\
master - internal-master.eu-west-2.elb.amazonaws.com\
master - master.eu-west-2.elb.amazonaws.com

etcd\
serving insecure client requests on 127.0.0.1:2379, this is strongly discouraged

## Learning

ssh config


#####What is in  a kubeconfig file ?

###### cluster name
kubectl config set-cluster kubernetes-the-real-hard-way \
###### ca certificate
  --certificate-authority=ca.pem \
  --embed-certs=true \
###### ca server dns
  --server=https://${MASTER_ELB_PRIVATE}:6443 \
###### file name
  --kubeconfig=kube-proxy.kubeconfig\


````bash
apiVersion: v1 
clusters: 
- cluster: 
    server: "" 
  name: test-cluster 
contexts: null 
current-context: "" 
kind: Config 
preferences: {} 
users: null
````
##### Files on the master node

````
admin.kubeconfig
kube-controller-manager.kubeconfig
kube-scheduler.kubeconfig

ca-key.pem
ca.pem

kubernetes-key.pem
kubernetes.pem
service-account-key.pem
service-account.pem

encryption-config.yaml
````

### Questions
How is this set
echo $HOSTEDZONE_NAME\
echo $AWS_DEFAULT_REGION


From bastion this works\
``ssh ${master}``

This does not
````
ssh master1.internal.k8-the-hard-way.com\
ssh -i kube_rsa ubuntu@master1.internal.k8-the-hard-way.com
````

When using ssh without specifying a key or user the details from the ```~/.ssh/config``` files are used






