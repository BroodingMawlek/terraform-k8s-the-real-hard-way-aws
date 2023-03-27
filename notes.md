# Notes 

## Changes

Changed provider configuration to 0.13\
Changed tags to tag in aws_autoscaling_group\
Moved all files into modules
Moved user-data into ./user-data

## Documentation notes
To ssh to the bastion\
ssh -i id_rsa ec2-user@<bastion-public-ip>

## Improvements
Enable session manager and remove bastion\

Change the name of the internal and external elbs which are currently\

master - internal-master.eu-west-2.elb.amazonaws.com\
master - master.eu-west-2.elb.amazonaws.com

## Questions
How is this set
echo $HOSTEDZONE_NAME\
echo $AWS_DEFAULT_REGION



cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-hostname=10.32.0.1,${ETCD1_INTERNAL},\
${MASTER1_INTERNAL},\
${WORKER1_INTERNAL},\
etcd1.internal.${HOSTEDZONE_NAME},\
master1.internal.${HOSTEDZONE_NAME},\
worker1.internal.${HOSTEDZONE_NAME},\
${MASTER_ELB_PRIVATE},${MASTER_ELB_PUBLIC},\
127.0.0.1,kubernetes.default \
-profile=kubernetes \
kubernetes-csr.json | cfssljson -bare kubernetes







