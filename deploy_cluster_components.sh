kubectl apply -k environment_kustomizations/cinchy-nonprod/cluster_components
kubectl label namespace argocd istio-injection=enabled
