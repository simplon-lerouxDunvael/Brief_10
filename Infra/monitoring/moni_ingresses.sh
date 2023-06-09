# Set variables
apitoken="XK6pTRqfZMkBiEyeTcNeEKLB"
IngMoni="nginx-moni"
Moni="monitoring"

# install Prometheus, Grafana & Loki
echo "Installing Prometheus, Grafana & Loki..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add loki https://grafana.github.io/helm-charts # same https address
helm repo update

kubectl create namespace $Moni

helm install prometheus prometheus-community/kube-prometheus-stack --set retention=7d --namespace $Moni
helm install grafana grafana/grafana --namespace $Moni
helm install loki loki/loki-stack --namespace $Moni
echo "Prometheus, Grafana & Loki installed"

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
helm install $IngMoni nginx-stable/nginx-ingress --create-namespace -n $Moni --debug --set controller.ingressClass="$IngMoni"
echo "NGINX Ingress Controller installed."

# Break time for Nginx to initialize
echo "Let's take 2 to let Nginx settle in..."
sleep 120s
echo "Alright, let's steam ahead !"

# Extract External IP address
MoniIngIP=$(kubectl get svc $IngMoni-nginx-ingress-controller -n $Moni -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Monitoring Ingress Prometheus: $MoniIngIP"

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

# Apply Ingress layer
echo "Applying Ingress configuration files..."
kubectl apply -f ingress_moni1.yaml -n $Moni
echo "Ingress configuration files applied."

# Apply Issuer layer
echo "Applying Let's Encrypt Issuer configuration files..."
kubectl apply -f issuer_moni.yaml -n $Moni
echo "Let's Encrypt Issuer configuration files applied."

# Create Gandi API token secret
echo "Creating Gandi API token secret..."
kubectl create secret generic gandi-credentials --from-literal=api-token=$apitoken -n $Moni
echo "Gandi API token secret created."

# Create role and rolebinding for accessing secrets
echo "Creating role and rolebinding for accessing secrets..."
hookID=$(kubectl get pods -n cert-manager | grep "cert-manager-webhook-gandi-" | cut -d"-" -f5)
kubectl create role access-secrets --verb=get,list,watch,update,create --resource=secrets -n $Moni
kubectl create rolebinding --role=access-secrets default-to-secrets --serviceaccount=cert-manager:cert-manager-webhook-gandi-$hookID -n $Moni
echo "Role and rolebinding created."

# Waiting for certificates
echo "Let's take 2' to let Azure take a tea break..."
sleep 10s
echo "Alright, let's steam ahead !"

# Apply Certificate layer
echo "Applying Certificate configuration files..."
kubectl apply -f certif_moni.yaml -n monitoring
echo "Certificate configuration files applied."

# Apply Ingress layer2
echo "Applying Ingress configuration files..."
kubectl apply -f ingress_moni2.yaml -n $Moni
echo "Ingress configuration files applied."

# Waiting for certificates
echo "Let's take 2' to let certificates to be presented..."
sleep 120s
echo "Alright, let's steam ahead !"

# Check certificate
echo "Let's check our certificates"
kubectl get certificate --all-namespaces

# Display password for grafana
echo "The default login is admin"
echo "The default password is prom-operator"
