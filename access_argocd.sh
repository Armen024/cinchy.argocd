echo "======= User Credentials ======="
echo "ArgoCD Username: admin"
echo -n "ArgoCD Password (Base64 Encoded): " && kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" && echo ""
echo "Port Forwarding to http://localhost:9090"
echo ""
kubectl port-forward svc/argocd-server -n argocd 9090:80 --address 0.0.0.0
