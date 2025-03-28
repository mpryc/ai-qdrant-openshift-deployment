#!/bin/bash

if ! command -v oc &> /dev/null; then
    echo "Error: OpenShift CLI (oc) is not installed or not in PATH."
    exit 1
fi

# Set default namespace if not provided
NAMESPACE=${1:-vector-db}

echo "Using namespace: ${NAMESPACE}"

# Check if the namespace exists
if oc get namespace "${NAMESPACE}" &> /dev/null; then
    echo "Namespace ${NAMESPACE} already exists."
    echo "Remove your namespace first."
    echo "This simple deployer is not designed to perform updates nor upgrades."
    exit 1
else
    echo "Namespace ${NAMESPACE} does not exist. Creating..."
    oc create namespace "${NAMESPACE}"
fi

for file in qdrant_deploy/*.yaml; do
    echo "Applying yaml: ${file} in namespace: ${NAMESPACE}"
    echo "-----------------------"
    oc apply -f "${file}" -n "${NAMESPACE}"
done

watch_route() {
    local route_name="$1"
    local namespace="$2"
    local timeout=30
    local interval=1

    echo "Waiting for the route to be available..."

    for ((i=0; i<$timeout; i++)); do
        ROUTE=$(oc get route "${route_name}" -n "${namespace}" --output=jsonpath='{.spec.host}' 2>/dev/null)
        if [ -n "$ROUTE" ]; then
            echo "Route for Qdrant service is available at: http://${ROUTE}"
            return 0
        fi
        echo "Still checking..."
        sleep "$interval"
    done

    echo "Timeout: Route not found after ${timeout} seconds."
    return 1
}

ROUTE_NAME="qdrant"

if ! watch_route "$ROUTE_NAME" "$NAMESPACE"; then
    echo "No route found for Qdrant service after waiting for 30 seconds."
    exit 1
fi

# Once we have route let's check if the service is accessible
check_qdrant_accessibility() {
    local url="$1"
    local timeout=10
    local retries=100
    local delay=5

    echo "Checking if Qdrant service is accessible at: ${url}"

    # Retry logic for curl request
    for ((i=1; i<=retries; i++)); do
        response=$(curl --silent --max-time "$timeout" "$url")
        if echo "$response" | grep -q '"title":"qdrant - vector search engine"'; then
            echo "Qdrant service is accessible and responding correctly!"
            return 0
        fi

        echo "Retry #$i: Qdrant service not accessible or response unexpected. This may take a while... retrying..."
        sleep "$delay"
    done

    echo "Error: Qdrant service is not accessible after ${retries} retries."
    exit 1
}

ROUTE_HOST=$(oc get route "$ROUTE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.host}')
URL="http://${ROUTE_HOST}"

check_qdrant_accessibility "$URL"

echo "****************************************"
echo "Access your Qdrant API by pointing it to: (host='${ROUTE_HOST}',port='80')"
echo
echo "You can also run the following command to access the Qdrant dashboard locally:"
echo "$ oc port-forward -n ${NAMESPACE} svc/vector-db-service 6333:6333"
echo "Then, visit: http://localhost:6333/dashboard"
echo "****************************************"

