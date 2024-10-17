#!/bin/bash

# Check if the correct number of arguments is passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment: dev|prod> <namespace: dev|prod>"
    exit 1
fi

# Set variables based on input arguments
ENVIRONMENT=$1
NAMESPACE=$2

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    echo "Invalid environment specified. Please use 'dev' or 'prod'."
    exit 1
fi

# Create /env directory if it doesn't exist
if [ ! -d "./env" ]; then
    echo "Creating /env directory..."
    mkdir ./env
fi

# Create dev.env and prod.env if they don't exist
if [ ! -f "./env/dev.env" ]; then
    echo "Creating dev.env..."
    cat <<EOF > ./env/dev.env
FRONTEND_URL="http://react-express.local"
API_URL="http://react-express.local/api"
EOF
fi

if [ ! -f "./env/prod.env" ]; then
    echo "Creating prod.env..."
    cat <<EOF > ./env/prod.env
FRONTEND_URL="https://prod-react-express.com"
API_URL="https://prod-react-express.com/api"
EOF
fi

# Load environment variables from the corresponding env file
ENV_FILE="./env/${ENVIRONMENT}.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file $ENV_FILE does not exist."
    exit 1
fi

# Source the environment variables (FRONTEND_URL and API_URL)
source "$ENV_FILE"

# Create the Helm chart directory structure if it doesn't exist
CHART_NAME="react-express-app"
CHART_DIR="./${CHART_NAME}"

if [ ! -d "$CHART_DIR" ]; then
    echo "Creating Helm chart directory structure..."
    mkdir -p "$CHART_DIR/templates"
    mkdir -p "$CHART_DIR/values"
    
    # Create the Chart.yaml file
    cat <<EOF > "$CHART_DIR/Chart.yaml"
apiVersion: v2
name: $CHART_NAME
description: A Helm chart for Kubernetes
version: 0.1.0
EOF

    # Create the _helpers.tpl file
    cat <<EOF > "$CHART_DIR/templates/_helpers.tpl"
{{/*
Common helper functions
*/}}

{{- define "app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

metadata:
  name: {{ include "app.fullname" . }}
  labels:
    generator: helm
    deployedby: bansikah
    date: {{ now | htmlDate }}

{{- define "app.serviceName" -}}
{{- printf "%s-service" .Release.Name -}}
{{- end -}}

{{- define "app.ingress.hosts" -}}
{{- if .Values.ingress.enabled -}}
{{ .Values.ingress.hostname }} 
{{- end -}}
{{- end -}}

{{- define "app.backend.port" -}}
{{ .Values.backend.port }}
{{- end -}}

{{- define "app.frontend.port" -}}
{{ .Values.frontend.port }}
{{- end -}}
EOF

    # Create the Notes.txt file
    cat <<EOF > "$CHART_DIR/templates/NOTES.txt"
{{- if .Values.ingress.enabled -}}
Access your application at:
http://{{ include "app.ingress.hosts" . }}
{{- else -}}
Access your backend service at:
http://{{ include "app.fullname" . }}-backend:{{ include "app.backend.port" . }}

Access your frontend service at:
http://{{ include "app.fullname" . }}-frontend:{{ include "app.frontend.port" . }}
{{- end -}}
EOF

    # Create deployment and service templates for the backend and frontend
    cat <<EOF > "$CHART_DIR/templates/deployment-backend.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullname" . }}-backend
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "app.fullname" . }}-backend
  template:
    metadata:
      labels:
        app: {{ include "app.fullname" . }}-backend
    spec:
      containers:
        - name: backend
          image: {{ .Values.backend.image }}
          ports:
            - containerPort: {{ include "app.backend.port" . }}
          env:
            - name: PORT
              value: {{ .Values.backend.port | quote }}
            - name: FRONTEND_URL
              value: {{ .Values.backend.frontend_url | quote }}
          readinessProbe:
            httpGet:
              path: {{ .Values.backend.readinessProbe.path }}
              port: {{ .Values.backend.readinessProbe.port }}
            initialDelaySeconds: {{ .Values.backend.readinessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.backend.readinessProbe.periodSeconds }}
EOF

    cat <<EOF > "$CHART_DIR/templates/deployment-frontend.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullname" . }}-frontend
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "app.fullname" . }}-frontend
  template:
    metadata:
      labels:
        app: {{ include "app.fullname" . }}-frontend
    spec:
      containers:
        - name: frontend
          image: {{ .Values.frontend.image }}
          ports:
            - containerPort: {{ include "app.frontend.port" . }}
          env:
            - name: API_URL
              value: {{ .Values.frontend.api_url | quote }}
          # Optional readiness probe for frontend if needed.
EOF

    cat <<EOF > "$CHART_DIR/templates/service-backend.yaml"
apiVersion: v1
kind: Service
metadata:
  name: {{ include "app.fullname" . }}-backend
spec:
  type: {{ .Values.service.backend.type }}
  ports:
    - port: {{ .Values.service.backend.port }}
      targetPort: {{ include "app.backend.port" . }}
  selector:
    app: {{ include "app.fullname" . }}-backend
EOF

    cat <<EOF > "$CHART_DIR/templates/service-frontend.yaml"
apiVersion: v1
kind: Service
metadata:
  name: {{ include "app.fullname" . }}-frontend
spec:
  type: {{ .Values.service.frontend.type }}
  ports:
    - port: {{ .Values.service.frontend.port }}
      targetPort: {{ include "app.frontend.port" . }}
  selector:
    app: {{ include "app.fullname" . }}-frontend
EOF

    cat <<EOF > "$CHART_DIR/templates/ingress.yaml"
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "app.fullname" . }}-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: {{ include "app.ingress.hosts" . }}
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: {{ include "app.fullname" . }}-backend
                port:
                  number: {{ include "app.backend.port" . }}
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ include "app.fullname" . }}-frontend
                port:
                  number: {{ include "app.frontend.port" . }}
  ingressClassName: "nginx" # if you're using a specific ingress class like Nginx
{{- end -}}
EOF

    # Create values files for dev and prod environments
    cat <<EOF > "$CHART_DIR/values/values-dev.yaml"
replicaCount: 1

backend:
  image: "bansikah/express-backend:1.2"
  port: 5000
  frontend_url: "${FRONTEND_URL}"
  readinessProbe:
    path: /api/hello
    port: 5000
    initialDelaySeconds: 5
    periodSeconds: 10

frontend:
  image: "bansikah/react-frontend:1.2"
  port: 80
  api_url: "${API_URL}"

service:
  backend:
    enabled: true
    port: 5000
    type: NodePort
  frontend:
    enabled: true
    port: 80
    type: NodePort

ingress:
  enabled: true
  hostname: "react-express.local"
EOF

    cat <<EOF > "$CHART_DIR/values/values-prod.yaml"
replicaCount: 2

backend:
  image: "bansikah/express-backend:1.2"
  port: 5000
  frontend_url: "${FRONTEND_URL}"
  readinessProbe:
    path: /api/hello
    port: 5000
    initialDelaySeconds: 5
    periodSeconds: 10

frontend:
  image: "bansikah/react-frontend:1.2"
  port: 80
  api_url: "${API_URL}"

service:
  backend:
    enabled: true
    port: 5000
    type: ClusterIP
  frontend:
    enabled: true
    port: 80
    type: LoadBalancer

ingress:
  enabled: true
  hostname: "react-express.local"
EOF

fi

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Install the Helm chart
if helm install $CHART_NAME $CHART_DIR --namespace $NAMESPACE --values "$CHART_DIR/values/values-$ENVIRONMENT.yaml"; then
    echo "Deployment successful."
else
    echo "Deployment failed in `$$NAMESPACE`."
    exit 1
fi