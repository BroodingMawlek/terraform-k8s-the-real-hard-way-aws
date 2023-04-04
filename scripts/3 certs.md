
For parallel execution on multiple instances at once, use tmux and this multiplexer script: https://gist.github.com/dmytro/3984680.

Both are already installed on the Bastion Host (the multiplexer script can be found in ec2-user $HOME directory).

Later, use tmux and execute tmux-multi.sh script to run commands on multiple instances (all etcd/master/worker nodes) at once.

But first we are creating the certificates on the Bastion Host and transfer them to the instances.

##Certificate Authority

For our Certificate Authority (Lifetime 17520h => 2 years)

CA config file

```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "17520h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "17520h"
      }
    }
  }
}
EOF
```
CA Certificate Signing Requests (CSRs) for the 4096-bit RSA key
```
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "DE",
      "L": "Munich",
      "O": "Kubernetes",
      "OU": "Kubernetes The Real Hard Way",
      "ST": "$HOSTEDZONE_NAME"
    }
  ]
}
EOF
```
```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```
#Client and Server Certificates

Now create client and server certificates with their corresponding CSRs:

##Admin Client Certificate
```
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "DE",
      "L": "Munich",
      "O": "system:masters",
      "OU": "Kubernetes The Real Hard Way",
      "ST": "$HOSTEDZONE_NAME"
    }
  ]
}
EOF
```
##Admin client key:
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```
##Kubelet Client Certificates

Here we get all the Worker nodes, identify them via their LaunchConfiguration name and create the CSRs:
```
WORKERCOUNT=$(aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[?starts_with(LaunchConfigurationName, `worker`)].[InstanceId]' --output text | wc -l)
i=1
while [ "$i" -le "$WORKERCOUNT" ]; do
  cat > worker${i}-csr.json <<EOF
  {
    "CN": "system:node:worker${i}.internal.${HOSTEDZONE_NAME}",
    "key": {
      "algo": "rsa",
      "size": 4096
    },
    "names": [
      {
        "C": "DE",
        "L": "Munich",
        "O": "system:nodes",
        "OU": "Kubernetes The Real Hard Way",
        "ST": "${HOSTEDZONE_NAME}"
      }
    ]
  }
EOF
  i=$(($i + 1))
done
```
##Kubelet keys
```
i=1
while [ "$i" -le "$WORKERCOUNT" ]; do
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=worker${i}.internal.${HOSTEDZONE_NAME} \
    -profile=kubernetes \
    worker${i}-csr.json | cfssljson -bare worker${i}
  i=$(($i + 1))
done
```
## kube-controller-manager certificate

Generate the kube-controller-manager client certificate
```
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "DE",
      "L": "Munich",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Real Hard Way",
      "ST": "${HOSTEDZONE_NAME}"
    }
  ]
}
EOF

```
kube-controller-manager private key
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
```

##kube-proxy Client Certificate

```
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "DE",
      "L": "Munich",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Real Hard Way",
      "ST": "$HOSTEDZONE_NAME"
    }
  ]
}
EOF
```
kube-proxy key
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
```
##kube-scheduler 

Client Certificate


```
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "DE",
      "L": "Munich",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Real Hard Way",
      "ST": "$HOSTEDZONE_NAME"
    }
  ]
}
EOF
```
Private Key
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
```
##kube-controller-manager ServiceAccount Token

To sign ServiceAccount tokens by the kube-controller-manager (see Documentation)

Certificate 

```
cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "DE",
      "L": "Munich",
      "O": "Kubernetes",
      "OU": "Kubernetes The Real Hard Way",
      "ST": "$HOSTEDZONE_NAME"
    }
  ]
}
EOF
```
Private key

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
  
```
##Kubernetes API Server Certificate

Certificate

```
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 4096
  },
  "names": [
    {
      "C": "DE",
      "L": "Munich",
      "O": "Kubernetes",
      "OU": "Kubernetes The Real Hard Way",
      "ST": "$HOSTEDZONE_NAME"
    }
  ]
}
EOF
```
Keys

For generating the kube-apiserver keys, we need to define all the IPs which will access the Apiserver.

ℹ️ NOTE: 10.32.0.1 ==> kubernetes.default.svc.cluster.local.

https://github.com/kelseyhightower/kubernetes-the-hard-way/issues/105

First get the Kubernetes Master ELBs DNS names via their prefixes and assign them to envvars:

```
export MASTER_ELB_PRIVATE=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[? starts_with(DNSName, `internal-master`)]| [].DNSName' --output text)
export MASTER_ELB_PUBLIC=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[? starts_with(DNSName, `master`)]| [].DNSName' --output text)
```
Generate the API Server certificate key but 

###Adapt the number of etcd, worker and master nodes to your setup.

We use the EnvVars we created earlier:
```
cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-hostname=10.32.0.1,${ETCD1_INTERNAL},${MASTER1_INTERNAL},${WORKER1_INTERNAL},\
etcd1.internal.${HOSTEDZONE_NAME},master1.internal.${HOSTEDZONE_NAME},worker1.internal.${HOSTEDZONE_NAME},\
${MASTER_ELB_PRIVATE},${MASTER_ELB_PUBLIC},127.0.0.1,kubernetes.default \
-profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
```
