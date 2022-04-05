# Docker-in-Docker on Kubernetes
## _Run your native docker builds in Kubernetes_

This is a solution for securely running container builds in docker while on Kubernenets. 

_Works great for Jenkin's workers on Kubernetes allowing them to do Docker images builds!_

## Installation

Clone Repo
```sh
git clone https://github.com/se7enack/Docker-In-Docker-on-Kubernetes.git
```

Create PEMs

```sh
cd Docker-In-Docker-on-Kubernetes
./PemsToSecureDockerSock.sh
```

Add the pems to Kubernetes
```sh
# Run from the clientkeys directory
kubectl create configmap dind-ca.pem --from-file=ca.pem -n {POD NAMESPACE}
kubectl create configmap dind-cert.pem --from-file=cert.pem -n {POD NAMESPACE}
kubectl create configmap dind-key.pem --from-file=key.pem -n {POD NAMESPACE}
```
```sh
# Run from the serverkeys directory
kubectl create configmap dind-server-cert.pem --from-file=server-cert.pem -n {POD NAMESPACE}
kubectl create configmap dind-server-key.pem --from-file=server-key.pem -n {POD NAMESPACE}
```
Create Persistent Volume Claim for the Docker Pod Cache
```sh
cd ..
# Edit the yaml below to reflect your namespace
kubectl apply -f ./CreatePVC.yaml
```
Create Secure Docker-in-Docker Pod
```sh
# Edit the yaml below to reflect your namespace
kubectl apply -f ./SecureDockerPod.yaml
```
Create a Build Pod to use the Secure Docker-in-Docker
```sh
# Edit the yaml below to reflect your namespace, build pod image, and FQDN of your docker pod
kubectl apply -f ./BuildPodExample.yaml
```
* _Note that you will need docker installed on your build pods image._
