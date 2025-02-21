targetScope = 'subscription'

@minLength(1)
@maxLength(15)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string


@description('The name of the web Virtual Machine Admin User')
param vmAdminUser string ='azd-admin'

@secure()
param vmAdminPass string = newGuid()

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The current user id. Will be supplied by azd')
param currentUserId string = newGuid()

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

@description('Monitoring workspace')
module wrks 'workspacedeploy.bicep' = {
  scope: rg
  name: 'workspacedeploy'
  params: {
    workspaceName: '${abbrs.networkVirtualNetworks}${resourceToken}'
    location: location
  }
}


@description('the vault used to store vm passwords')
#disable-next-line secure-secrets-in-params - Individual secrets are marked
module vault 'br/public:avm/res/key-vault/vault:0.11.1' = {
  scope: rg
  name: 'vaultDeployment'
  params: {
    name: '${abbrs.keyVaultVaults}${environmentName}'
    enablePurgeProtection: false
    location: rg.location
    tags: tags
    diagnosticSettings: [
      {
        workspaceResourceId: wrks.outputs.WORKSPACE_ID
      }
    ]
    secrets: [
      {
        name: 'vmAdminPass'
        value: vmAdminPass
      }
    ]
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Key Vault Secrets Officer'
        principalId: currentUserId
      }
    ]
  }
}



@description('VNet with VMs')
module vent 'vnet.bicep' = {
  scope: rg
  name: 'vnet'
  params: {
    envName: environmentName
    Workspaceid: wrks.outputs.WORKSPACE_ID
    DefaultPassword: vmAdminPass
    DefaultUserName: vmAdminUser
    location: location
  }
}

