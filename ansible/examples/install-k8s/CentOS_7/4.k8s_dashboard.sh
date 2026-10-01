#!/bin/bash
kubectl apply -f k8s_dashboard/k8s-dashboard-v2.0.0.yaml
kubectl apply -f k8s_dashboard/service_account.yml
kubectl apply -f k8s_dashboard/cluster_role_binding.yml
kubectl -n kube-system create token admin
