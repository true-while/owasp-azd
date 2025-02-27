@description('Specify the name of the workspace.')
param workspaceName string

@description('Specify the location for the workspace.')
param location string

@description('Specify the pricing tier: PerGB2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium) which are not available to all customers.')
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param sku string = 'PerGB2018'

@description('Specify the number of days to retain data.')
param retentionInDays int = 120

@description('Specify true to use resource or workspace permissions, or false to require workspace permissions.')
param resourcePermissions bool = true

@description('Specify the number of days to retain data in Heartbeat table.')
param heartbeatTableRetention int = 120

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: resourcePermissions
    }
  }
}

resource WaitSection 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  name: 'WaitSection'
  location: location
  properties: {
    azPowerShellVersion: '3.0'
    scriptContent: 'start-sleep -Seconds 200'
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
  }
  dependsOn: [
    workspace
  ]
}

resource workspaceName_Heartbeat 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: workspace
  name: 'Heartbeat'
  properties: {
    retentionInDays: heartbeatTableRetention
  }
  dependsOn: [
    WaitSection
  ]
}


output WORKSPACE_ID string = workspace.id
