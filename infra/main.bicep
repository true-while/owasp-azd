targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

param wspName string = ''

@minLength(1)
@description('Primary location for all resources')
param location string


// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}


module owasp 'workspacedeploy.bicep' = {
  scope: rg
  name: 'workspacedeploy'
  params: {
    workspaceName: !empty(wspName) ? wspName : '${abbrs.eventHubNamespaces}${resourceToken}'
    location: location
  }
}

