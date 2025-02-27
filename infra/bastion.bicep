param environmentName string
param vnetID string 
param location string

var bastionHostsName = 'b-${environmentName}'

resource bastionHosts_alextest_name_resource 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionHostsName
  location: location
  sku: {
    name: 'Developer'
  }
  properties: {
    scaleUnits: 2
    virtualNetwork: {
      id: vnetID
    }
    ipConfigurations: []
  }
}
