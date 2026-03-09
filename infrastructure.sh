#!/bin/bash

# Variables
RESOURCE_GROUP="lab4-rg"
LOCATION="westeurope"
APP_SERVICE_PLAN="myAppServicePlan"
WEB_APP_NAME="DennisWebApp123"  # Must be globally unique
SKU="B1"
RUNTIME="NODE:20-lts"

# Create Resource Group
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# Create App Service Plan
az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku "$SKU" \
  --is-linux

# Create Web App
az webapp create \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$APP_SERVICE_PLAN" \
  --runtime "$RUNTIME"

echo "Web App URL: https://$WEB_APP_NAME.azurewebsites.net"
