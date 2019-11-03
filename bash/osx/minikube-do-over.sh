#!/bin/bash
echo "Stopping minikube instance..."
minikube stop

echo "Deleting VM for minikube..."
minikube delete

echo "Starting new minikube..." #minikube config set bootstrapper kubeadm
minikube start --vm-driver=hyperkit --kubernetes-version=v1.8.6 --bootstrapper=kubeadm 

echo "Enabling Heapster Minikube addon..."
minikube addons enable heapster

echo "Setting docker to use minikube's docker environment..."
eval $(minikube docker-env)

echo "Iniitalizing helm..."
helm init

