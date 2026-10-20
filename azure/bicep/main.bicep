// =============================================================================
// Azure Bicep Infrastructure Specification: Nyaga Law Advocates
// Declarative Cloud Resources: ACR + Linux App Service Plan + Web App + Staging Slot + Log Analytics
// =============================================================================

@description('Primary deployment location')
param location string = resourceGroup().location

@description('Environment name (staging or production)')
@allowed(['develop', 'staging', 'production'])
param environmentName string = 'production'

@description('Name of Azure Container Registry')
param acrName string = 'acrnyagahfee'

@description('App Service Plan pricing tier')
param appServicePlanSku string = 'B1'

@description('Primary Web App name')
param webAppName string = 'nyagahkithinji-advocates'

// 1. Azure Log Analytics Workspace for Centralized Container Telemetry
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${webAppName}-${environmentName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// 2. Azure Container Registry (ACR)
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// 3. Linux App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'plan-${webAppName}-${environmentName}'
  location: location
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true
  }
}

// 4. Production Web App for Containers
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.properties.loginServer}/karani-backend:latest'
      alwaysOn: true
      healthCheckPath: '/api/v1/health'
      http20Enabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APP_ENV'
          value: environmentName
        }
        {
          name: 'PORT'
          value: '8000'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.properties.loginServer}'
        }
      ]
    }
    httpsOnly: true
  }
}

// 5. Staging Deployment Slot for Blue/Green Deployments & Zero Downtime Swaps
resource stagingSlot 'Microsoft.Web/sites/slots@2022-09-01' = {
  parent: webApp
  name: 'staging'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.properties.loginServer}/karani-backend:staging'
      alwaysOn: false
      healthCheckPath: '/api/v1/health'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

output acrLoginServer string = containerRegistry.properties.loginServer
output productionUrl string = 'https://${webApp.properties.defaultHostName}'
output stagingUrl string = 'https://${stagingSlot.properties.defaultHostName}'
