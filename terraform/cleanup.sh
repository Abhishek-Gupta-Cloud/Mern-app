#!/bin/bash

kubectl delete ingress --all -A
kubectl delete svc --all -A
kubectl delete pvc --all -A

helm uninstall aws-load-balancer-controller -n kube-system