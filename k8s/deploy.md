```bash
chmod +x deploy.sh
./deploy.sh dev dev    # Deploys to the dev namespace
./deploy.sh prod prod  # Deploys to the prod namespace
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get ingress -n dev
helm uninstall react-express-app -n dev
echo "$(minikube ip) react-express.local" | sudo tee -a /etc/hosts
minikube addons enable ingress
kubectl delete pods -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx
### Debugging nginx 502 Bad Gateway error 
kubectl get pods -o wide
kubectl get pods -n ingress-nginx
kubectl logs ingress-nginx-controller-7c6974c4d8-m8ghr -n ingress-nginx
kubectl delete pod react-express-app-react-express-app-backend-86d6cb8dcb-h89xn -n dev
kubectl delete pod ingress-nginx-controller-7c6974c4d8-m8ghr -n ingress-nginx
##Fix page 404 Not Found error
curl -I -X OPTIONS http://react-express.local/api/submit ## test cors configuration
kubectl run -it --rm curl-test --image=curlimages/curl -- sh
curl -X POST http://react-express-app-backend:5000/api/submit -H "Content-Type: application/json" -d '{"input": "test"}'

```
