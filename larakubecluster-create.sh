#!/bin/bash

# Cluster specific variables
RG=(
   sample-gatekeeper
)

CLUSTER=(
     sample-gatekeeper-cluster
)

ACR=(
    acrgatekeeper
)

# Common variables
VERSION=1.20.9
ACR_SKU=Basic
REGION=eastus2
VM_SIZE=Standard_B2ms
LB_SKU=standard
NODE_COUNT=1


# Counters
COUNT=${#RG[@]}


for (( i=1; i<${COUNT}+1; i++ ));
do
        echo $i " / " ${COUNT} " : " ${RG[$i-1]}
        echo $i " / " ${COUNT} " : " ${CLUSTER[$i-1]}
        echo $i " / " ${COUNT} " : " ${ACR[$i-1]} ""

        # Create Resource Group
        echo "Creating Resource Group with name ${RG[$i-1]}..."
        az group create --location $REGION --name ${RG[$i-1]}

        # Create ACR
        echo "Creating ACR with name ${ACR[$i-1]}..."
        az acr create -g ${RG[$i-1]} --name ${ACR[$i-1]} --sku $ACR_SKU

        # Create Cluster
        echo "Creating cluster... This will take time, go grab a cup of coffee... "
        az aks create -n ${CLUSTER[$i-1]} -g ${RG[$i-1]} --attach-acr ${ACR[$i-1]} \
            --vm-set-type VirtualMachineScaleSets \
            --node-count $NODE_COUNT \
            --node-vm-size $VM_SIZE\
            --kubernetes-version $VERSION \
            --generate-ssh-keys \
            --load-balancer-sku $LB_SKU

        # Attach ACR to already created AKS
        echo "Attaching ACR to the newly created cluster..."
        az aks update --resource-group ${RG[$i-1]} --name ${CLUSTER[$i-1]} --attach-acr ${ACR[$i-1]}

        # Create Service Principle
        #echo "Creating service principal..."
        #az ad sp create-for-rbac --name ${CLUSTER[$i-1]} > ./${CLUSTER[$i-1]}.json

        echo "Cloning kubeconfig to access from local machine..."
        az aks get-credentials --resource-group ${RG[$i-1]} --name ${CLUSTER[$i-1]}

        echo "Verifying cluster objects..."
        kubectl get nodes

        echo "Install Ingress NGINX controller"
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/cloud/deploy.yaml

        kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

done

echo "Cluster setup completed!"


