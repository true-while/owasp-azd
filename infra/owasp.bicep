//https://johnnyreilly.com/output-connection-strings-and-keys-from-azure-bicep


param location string = resourceGroup().location
param name string

var abbrs = loadJsonContent('./abbreviations.json')
var str_acc_name=  '${abbrs.storageStorageAccounts}${uniqueString(resourceGroup().id)}'


resource eventhub_resource 'Microsoft.EventHub/namespaces@2024-05-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    geoDataReplication: {
      maxReplicationLagDurationInSeconds: 0
      locations: [
        {
          locationName: location
          roleType: 'Primary'
        }
      ]
    }
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: false
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: true
  }
}

resource storageAccounts_resource 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: str_acc_name
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: false
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_0'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource name_RootManageSharedAccessKey 'Microsoft.EventHub/namespaces/authorizationrules@2024-05-01-preview' = {
  parent: eventhub_resource
  name: 'RootManageSharedAccessKey'
  location: location
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource network_name_default 'Microsoft.EventHub/namespaces/networkrulesets@2024-05-01-preview' = {
  parent: eventhub_resource
  name: 'default'
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
    defaultAction: 'Allow'
    virtualNetworkRules: []
    ipRules: []
    trustedServiceAccessEnabled: false
  }
}

resource blob_name_default 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccounts_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource fileservice_name 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccounts_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource queueservice_name'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = {
  parent: storageAccounts_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource tableservice_name 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = {
  parent: storageAccounts_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}


resource apps_policy_name 'Microsoft.EventHub/namespaces/eventhubs/authorizationrules@2024-05-01-preview' = {
  parent: eventhub_resource_name
  name: 'apps'
  location: location
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

resource eventhub_consgroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2024-05-01-preview' = {
  parent: eventhub_resource_name
  name: '$Default'
  location: location
  properties: {}
}

resource capdata_container_name 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blob_name_default 
  name: 'capdate'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'Blob'
  }
}

resource eventhub_resource_name 'Microsoft.EventHub/namespaces/eventhubs@2024-05-01-preview' = {
  parent: eventhub_resource
  name: name
  location: location
  properties: {
    messageTimestampDescription: {
      timestampType: 'LogAppend'
    }
    retentionDescription: {
      cleanupPolicy: 'Delete'
      retentionTimeInHours: 24
    }
    messageRetentionInDays: 1
    partitionCount: 4
    status: 'Active'
    captureDescription: {
      enabled: true
      encoding: 'Avro'
      destination: {
        name: 'EventHubArchive.AzureBlockBlob'
        properties: {
          storageAccountResourceId: storageAccounts_resource.id
          blobContainer: 'capdate'
          archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
        }
      }
      intervalInSeconds: 900
      sizeLimitInBytes: 314572800
    }
  }
}

var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts_resource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccounts_resource.id, storageAccounts_resource.apiVersion).keys[0].value}'
var eventHubNamespaceConnectionString = listKeys(apps_policy_name.id, apps_policy_name.apiVersion).primaryConnectionString

output EH_AZD_BLOB_CONNECTION string = blobStorageConnectionString
output EH_AZD_EH_CONNECTION string = eventHubNamespaceConnectionString

