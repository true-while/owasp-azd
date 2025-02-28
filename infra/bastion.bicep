param environmentName string
param vnetID1 string 
param vnetID2 string 
param location string

var bastionHostsName = 'b-${environmentName}'

resource bastionHosts_vnet1_name_resource 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: '${bastionHostsName}1'
  location: location
  sku: {
    name: 'Developer'
  }
  properties: {
    scaleUnits: 2
    virtualNetwork: {
      id: vnetID1
    }
    ipConfigurations: []
  }
}


resource bastionHosts_vnet2_name_resource 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: '${bastionHostsName}2'
  location: location
  sku: {
    name: 'Developer'
  }
  properties: {
    scaleUnits: 2
    virtualNetwork: {
      id: vnetID2
    }
    ipConfigurations: []
  }
}
