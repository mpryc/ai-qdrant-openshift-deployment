# Qdrant OpenShift Deploy Script

This project provides a simple script to deploy the [Qdrant](https://qdrant.tech/) vector search engine on OpenShift.

The script sets up the necessary resources, including the namespace, Qdrant deployment, and services.

It also ensures that the Qdrant service is accessible and provides instructions for port-forwarding to access the Qdrant dashboard locally.

This setup is intended for **development playgrounds**. It uses unencrypted HTTP communication and is not intended for production use.

## Features

- Automatically creates a namespace in OpenShift if it doesn't exist.
- Deploys Qdrant and required persistent volume.
- Waits for the Qdrant route to become available.
- Checks if the Qdrant service is accessible via HTTP.
- Provides instructions for accessing the Qdrant dashboard locally using port-forwarding.

## Prerequisites

- OpenShift CLI (`oc`) must be installed and available in your `PATH`.
- You must have access to an OpenShift cluster and the necessary permissions to create namespaces and deploy resources.

## Usage

1. **Clone the repository** and navigate to the project directory.
2. Deploy
Run the deploy script with optional namespace, which by default is set to `vector-db`:
   ```bash
   ./deploy-qdrant.sh [namespace]
   [...]
   Qdrant service is accessible and responding correctly!
   ****************************************
   Access your Qdrant API by pointing it to host='qdrant-vector-db.-<truncated>',port='80')

   You can also run the following command to access the Qdrant dashboard locally:
   oc port-forward -n qdrantabca svc/vector-db-service 6333:6333
   Then, visit: http://localhost:6333/dashboard
   ****************************************

   ```
   
3. Cleanup
Simply remove namespace to remove the deployment
   ```bash
   oc delete ns [namespace]
   ```
