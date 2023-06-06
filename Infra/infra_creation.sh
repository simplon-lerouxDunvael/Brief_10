#!/usr/bin/env -S bash -Eeuxo pipefail

# Set variables
rgname="b10duna"
aksname="AKSClusterDuna"
rgloc="francecentral"
redusrqua="devuserqua"
redpassqua="password_redis_154"
redusrprod="devuserprod"
redpassprod="password_redis_265"
apitoken="XK6pTRqfZMkBiEyeTcNeEKLB"
certvers="v1.10.1"
IngQua="nginx-qua"
IngProd="nginx-prod"


# Create resource group
echo "Creating resource group..."
az group create --location $rgloc --name $rgname
echo "Resource group created."

# Create AKS cluster
echo "Creating AKS cluster..."
az aks create -g $rgname -n $aksname --enable-managed-identity --node-count 2 --enable-addons monitoring --enable-msi-auth-for-monitoring --generate-ssh-keys
echo "AKS cluster created."

# Get AKS cluster credentials
echo "Getting AKS cluster credentials..."
az aks get-credentials --resource-group $rgname --name $aksname
echo "AKS cluster credentials retrieved."

# Install K9s
echo "Installing K9s..."
curl -sS https://webinstall.dev/k9s | bash
echo "The watchdog is here."

# Create Prod & Qua namespaces
echo "Creating Prod & Qua namespaces for QAL & Public deploy"
kubectl create namespace qua
kubectl create namespace prod
echo "Namespaces created"

# Create Redis database secret
echo "Creating Redis database secret for namespace qua..."
kubectl create secret generic redis-secret-duna --from-literal=username=$redusrqua --from-literal=password=$redpassqua -n qua
echo "Redis database secret created."
echo "Creating Redis database secret for namespace prod..."
kubectl create secret generic redis-secret-duna --from-literal=username=$redusrprod --from-literal=password=$redpassprod -n prod
echo "Redis database secret created."

# Create Redis database secret
echo "Creating Redis database secret..."
kubectl apply -f azure-vote.yaml -n qua
kubectl apply -f azure-vote.yaml -n prod
echo "Redis database secret created."

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install $IngQua nginx-stable/nginx-ingress --create-namespace -n qua --debug --set controller.ingressClass="$IngQua"
helm install $IngProd nginx-stable/nginx-ingress --create-namespace -n prod --debug --set controller.ingressClass="$IngProd"
echo "NGINX Ingress Controller installed."

# Break time for Nginx to initialize
echo "Let's take 5 to let Nginx settle in..."
sleep 30s
echo "Alright, let's steam ahead !"

# Extract External IP address
QuaIngIP=$(kubectl get svc nginx-qua-nginx-ingress-controller -n qua -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
ProdIngIP=$(kubectl get svc nginx-prod-nginx-ingress-controller -n prod -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "QUA Ingress: $QuaIngIP"
echo "Prod Ingress: $ProdIngIP"

# Insert a pause in the script so that users can report IP to DNS
read -n1 -r -p "Press Y to continue, or N to stop: " key

echo

if [ "$key" = 'Y' ] || [ "$key" = 'y' ]; then
    echo "Continuing..."
    # your code to execute if user presses Y goes here
elif [ "$key" = 'N' ] || [ "$key" = 'n' ]; then
    echo "Stopping..."
    exit 1
else
    # do nothing
    :
fi

# Add Jetstack Helm repository
echo "Adding Jetstack Helm repository..."
helm repo add jetstack https://charts.jetstack.io
echo "Jetstack Helm repository added."

# Install cert-manager with custom DNS settings
echo "Installing cert-manager..."
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --version v1.10.1 --set 'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
echo "Cert-manager installed."

# Install cert-manager-webhook-gandi Helm chart
echo "Installing cert-manager-webhook-gandi Helm chart..."
helm install cert-manager-webhook-gandi --repo https://bwolf.github.io/cert-manager-webhook-gandi --version v0.2.0 --namespace cert-manager --set features.apiPriorityAndFairness=true --set logLevel=6 --generate-name
echo "cert-manager-webhook-gandi Helm chart installed."

# Apply applicative layers
echo "Applying applicative configuration files..."
kubectl apply -f azure-vote.yaml -n qua
kubectl apply -f azure-vote.yaml -n prod
echo "Applicative configuration files applied"

# Apply Ingress layer
echo "Applying Ingress configuration files..."
kubectl apply -f ingress_qua1.yaml -n qua
kubectl apply -f ingress_prod1.yaml -n prod
echo "Ingress configuration files applied."

# Apply Issuer layer
echo "Applying Let's Encrypt Issuer configuration files..."
kubectl apply -f issuer-qua.yaml -n qua
kubectl apply -f issuer-prod.yaml -n prod
echo "Let's Encrypt Issuer configuration files applied."

# Create Gandi API token secret
echo "Creating Gandi API token secret..."
kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken
kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken -n qua
kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken -n prod
echo "Gandi API token secret created."

# Create role and rolebinding for accessing secrets
echo "Creating role and rolebinding for accessing secrets..."
hookID=$(kubectl get pods -n cert-manager | grep "cert-manager-webhook-gandi-" | cut -d"-" -f5)
kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets -n qua
kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets -n prod
kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-$hookID -n qua
kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-$hookID -n prod
echo "Role and rolebinding created."

# Apply Certificate layer
echo "Applying Certificate configuration files..."
kubectl apply -f certif_qua.yaml -n qua
kubectl apply -f certif_prod.yaml -n prod
echo "Certificate configuration files applied."

# Apply Ingress layer
echo "Applying Ingress configuration files..."
kubectl apply -f ingress_qua2.yaml -n qua
kubectl apply -f ingress_prod2.yaml -n prod
echo "Ingress configuration files applied."

# Waiting for certificates
echo "Let's take 2' to let certificates to be presented..."
sleep 120s
echo "Alright, let's steam ahead !"

# Creating Kubeconfig for Azure Devops
echo "Creating the Kubeconfig for Azure DevOps..."
az aks get-credentials --resource-group $rgname --name $aksname -f kubeconfig.yaml
echo "Kubeconfig file generated."

# Check certificate
echo "Let's check our certificates"
kubectl get certificate --all-namespaces

# Check ingresses
echo "Let's check our ingresses"
kubectl get ing --all-namespaces
echo ""
echo "Be sure to get the data from kubeconfig.yaml and remove it if it is created in your git."