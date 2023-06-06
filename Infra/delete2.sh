# To delete all resources

kubectl delete deploy --all
kubectl delete svc --all
kubectl delete pvc --all
kubectl delete pv --all
kubectl delete ingress --all
kubectl delete secrets --all
kubectl delete certificates --all


kubectl delete deployments --all -n monitoring
kubectl delete pods --all -n monitoring
kubectl delete replicaset --all -n monitoring
kubectl delete statefulset --all -n monitoring
kubectl delete daemonset --all -n monitoring
kubectl delete svc --all -n monitoring
kubectl delete namespace monitoring

kubectl delete clusterrole prometheus-grafana-clusterrole
kubectl delete clusterrole prometheus-kube-state-metrics
kubectl delete clusterrole system:prometheus
kubectl delete clusterrolebinding --all -n monitoring