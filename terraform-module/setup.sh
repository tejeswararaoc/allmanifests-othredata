#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <RESOURCE_GROUP_NAME> <AKS_CLUSTER_NAME>"
  exit 1
fi

RESOURCE_GROUP_NAME="$1"
AKS_CLUSTER_NAME="$2"

# Install Azure CLI
echo "Installing Azure CLI..."
if ! curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; then
  echo "Failed to install Azure CLI"
  exit 1
fi

# Install kubectl
echo "Installing kubectl..."
if ! sudo az aks install-cli; then
  echo "Failed to install kubectl"
  exit 1
fi

# Authenticate with Azure using the managed identity
echo "Authenticating with Azure..."
if ! az login --identity; then
  echo "Failed to authenticate with Azure"
  exit 1
fi

# Get AKS credentials
echo "Getting AKS credentials..."
if ! az aks get-credentials --resource-group "$RESOURCE_GROUP_NAME" --name "$AKS_CLUSTER_NAME" --overwrite-existing --admin; then
  echo "Failed to get AKS credentials"
  exit 1
fi

# Verify kubectl access
echo "Verifying kubectl access..."
if ! kubectl get nodes; then
  echo "Failed to get nodes from AKS"
  exit 1
fi

# Apply the nginxingrss.yaml configuration
echo "Applying nginxingrss.yaml..."
if ! kubectl apply -f /tmp/nginxingrss.yaml; then
  echo "Failed to apply nginxingrss.yaml"
  exit 1
fi

echo "Script completed successfully"
