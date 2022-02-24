#!/bin/bash

. ./env.sh

eksctl create cluster --name ${ENVIRONMENT} --version 1.21 --region us-east-1 --nodegroup-name ${ENVIRONMENT}-nodes --node-type t2.medium --nodes 3

# Set the context?
aws eks update-kubeconfig --name ${ENVIRONMENT}

# For out-of-tree AWS annotations you need the AWS controller:
# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html#lbc-install-controller