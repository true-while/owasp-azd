@description('Specify the location for the workspace.')
param location string

@description('Specify environment name')
param envName string

@description('Builtin\\Administrator account\'s name for the Virtual Machines. This is not a domain account.')
param DefaultUserName string = ''

@description('Password for the Built-in Administrator account. Default is \'H@ppytimes123!\'')
@secure()
param DefaultPassword string = ''

@description('Provide the workspace ID')
param Workspaceid string

var VN_Name1 = 'VN-HUB-${envName}'
var VN_Name2 = 'VN-SPOKE1-${envName}'
var VN_Name3 = 'VN-SPOKE2-${envName}'
var DDosPLanName = 'ddos-${envName}'
var bastionHostName = 'b-${envName}'
var VN_Name1Prefix = '10.0.25.0/24'
var VN_Name1Subnet1Name = 'AGWAFSubnet'
var VN_Name1Subnet1Prefix = '10.0.25.64/26'
var VN_Name1Subnet2Name = 'AzureFirewallSubnet'
var VN_Name1Subnet2Prefix = '10.0.25.0/26'
var VN_Name2Prefix = '10.0.27.0/24'
var VN_Name2Subnet1Name = 'SPOKE1-SUBNET1'
var VN_Name2Subnet1Prefix = '10.0.27.0/26'
var VN_Name2Subnet2Name = 'SPOKE1-SUBNET2'
var VN_Name2Subnet2Prefix = '10.0.27.64/26'
var VN_Name3Prefix = '10.0.28.0/24'
var VN_Name3Subnet1Name = 'SPOKE2-SUBNET1'
var VN_Name3Subnet1Prefix = '10.0.28.0/26'
var VN_Name3Subnet2Name = 'SPOKE2-SUBNET2'
var VN_Name3Subnet2Prefix = '10.0.28.64/26'
var Subnet_serviceEndpoints = [
  {
    service: 'Microsoft.Web'
  }
  {
    service: 'Microsoft.Storage'
  }
  {
    service: 'Microsoft.Sql'
  }
  {
    service: 'Microsoft.ServiceBus'
  }
  {
    service: 'Microsoft.KeyVault'
  }
  {
    service: 'Microsoft.AzureActiveDirectory'
  }
]
var publicIpAddressName1 = 'SOCNSFWPIP-${envName}'
var publicIpAddressName2 = 'SOCNSAGPIP-${envName}'
var FW_Name = 'SOC-NS-FW-${envName}'
var firewallPolicyName = 'SOC-NS-FWPolicy'
var AppGatewayPolicyName = 'SOC-NS-AGPolicy'
var FrontdoorPolicyName = 'SOCNSFDPolicy'
var AG_Name = 'SOC-NS-AG-WAFv2'
var AppGateway_IPAddress = '10.0.25.70'
var FrontDoorName = 'Demowasp-${uniqueString(resourceGroup().id)}'
var RT_Name1 = 'SOC-NS-DEFAULT-ROUTE'
var NSG_Name1 = 'SOC-NS-NSG-SPOKE1'
var NSG_Name2 = 'SOC-NS-NSG-SPOKE2'
var Site_Name1 = 'owaspdirect-${uniqueString(resourceGroup().id)}'
var Site_HPN_var = 'OWASP-ASP-${envName}'
var NIC_Name1 = 'Nic1'
var NIC_Name2 = 'Nic2'
var NIC_Name3 = 'Nic3'
var NIC_Name1Ipaddress = '10.0.27.4'
var NIC_Name2Ipaddress = '10.0.27.68'
var NIC_Name3Ipaddress = '10.0.28.4'
var VM_Name1 = 'VM-Win11'
var VM_Name3 = 'VM-Win2019'

resource AG 'Microsoft.Network/applicationGateways@2020-04-01' = {
  name: AG_Name
  location: location
  tags: {}
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: VN_Name1_VN_Name1Subnet1.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIpAddress2.id
          }
        }
      }
      {
        name: 'appGwPrivateFrontendIp'
        properties: {
          subnet: {
            id: VN_Name1_VN_Name1Subnet1.id
          }
          privateIPAddress: AppGateway_IPAddress
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_8080'
        properties: {
          port: 8080
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'PAAS-APP'
        properties: {
          backendAddresses: [
            {
              fqdn: '${Site_Name1}.azurewebsites.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'Default'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          hostName: '${Site_Name1}.azurewebsites.net'
          pickHostNameFromBackendAddress: false
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'Public-HTTP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', AG_Name, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', AG_Name, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'PublicIPRule'
        properties: {
          ruleType: 'Basic'

          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', AG_Name, 'Public-HTTP')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', AG_Name, 'PAAS-APP')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', AG_Name, 'Default')
          }
        }
      }
    ]
    enableHttp2: false
    firewallPolicy: {
      id: AppGatewayPolicy.id
    }
  }
  dependsOn: [ 
    publicIpAddress1
  ]
}

resource applicationGatewayDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: AG
  name: 'DiagService'
  properties: {
    workspaceId: Workspaceid
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
  }
}

resource AppGatewayPolicy 'Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies@2019-09-01' = {
  name: AppGatewayPolicyName
  location: location
  tags: {}
  properties: {
    customRules: [
      {
        name: 'SentinelBlockIP'
        priority: 10
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: false
            matchValues: [
              '104.210.223.108'
            ]
            transforms: []
          }
        ]
      }
      {
        name: 'BlockGeoLocationChina'
        priority: 20
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            negationConditon: false
            matchValues: [
              'CN'
            ]
            transforms: []
          }
        ]
      }
      {
        name: 'BlockInternetExplorer11'
        priority: 30
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'User-Agent'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'rv:11.0'
            ]
            transforms: []
          }
        ]
      }
    ]
    policySettings: {
      fileUploadLimitInMb: 100
      maxRequestBodySizeInKb: 128
      mode: 'Prevention'
      requestBodyCheck: true
      state: 'Enabled'
    }
    managedRules: {
      exclusions: []
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.1'
          ruleGroupOverrides: [
            {
              ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
              rules: [
                {
                  ruleId: '920350'
                  state: 'Disabled'
                }
                {
                  ruleId: '920320'
                  state: 'Disabled'
                }
              ]
            }
          ]
        }
      ]
    }
  }
  dependsOn: []
}
resource variables_DDoSPlan 'Microsoft.Network/ddosProtectionPlans@2020-04-01' = {
  name: DDosPLanName
  location: resourceGroup().location
  properties: {}
}

resource VN_1 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: VN_Name1
  location: location
  tags: {
    displayName: VN_Name1
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        VN_Name1Prefix
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource VN_Name1_VN_Name1Subnet1 'Microsoft.Network/virtualNetworks/subnets@2020-03-01' = {
  parent: VN_1
  name: VN_Name1Subnet1Name
  properties: {
    addressPrefix: VN_Name1Subnet1Prefix
    serviceEndpoints: Subnet_serviceEndpoints
  }
}



resource VN_Name1_VN_Name1Subnet2 'Microsoft.Network/virtualNetworks/subnets@2020-03-01' = {
  parent: VN_1
  name: VN_Name1Subnet2Name
  properties: {
    addressPrefix: VN_Name1Subnet2Prefix
    serviceEndpoints: Subnet_serviceEndpoints
  }
  dependsOn: [
    VN_Name1_VN_Name1Subnet1
  ]
}

resource VN_Name1_microsoft_insights_VN1Diagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: VN_1
  name: 'DiagService'
  properties: {    
    workspaceId: Workspaceid
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

resource VN_2 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: VN_Name2
  location: location
  tags: {
    displayName: VN_Name2
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        VN_Name2Prefix
      ]
    }
    enableDdosProtection: true
    enableVmProtection: false
    ddosProtectionPlan: {
      id: variables_DDoSPlan.id
    }
    subnets: [
      {
        name: VN_Name2Subnet1Name
        properties: {
          addressPrefix: VN_Name2Subnet1Prefix
          networkSecurityGroup: {
            id: NSG_1.id
          }
          routeTable: {
            id: RT_1.id
          }
          serviceEndpoints: Subnet_serviceEndpoints
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: VN_Name2Subnet2Name
        properties: {
          addressPrefix: VN_Name2Subnet2Prefix
          networkSecurityGroup: {
            id: NSG_1.id
          }
          routeTable: {
            id: RT_1.id
          }
          serviceEndpoints: Subnet_serviceEndpoints
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource VN_Name2_microsoft_insights_VN2Diagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'DiagService'
  scope: VN_2
  properties: {
    
    workspaceId: Workspaceid
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

resource VN_3 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: VN_Name3
  location: location
  tags: {
    displayName: VN_Name3
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        VN_Name3Prefix
      ]
    }
    subnets: [
      {
        name: VN_Name3Subnet1Name
        properties: {
          addressPrefix: VN_Name3Subnet1Prefix
          networkSecurityGroup: {
            id: NSG_2.id
          }
          routeTable: {
            id: RT_1.id
          }
          serviceEndpoints: Subnet_serviceEndpoints
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: VN_Name3Subnet2Name
        properties: {
          addressPrefix: VN_Name3Subnet2Prefix
          networkSecurityGroup: {
            id: NSG_2.id
          }
          routeTable: {
            id: RT_1.id
          }
          serviceEndpoints: Subnet_serviceEndpoints
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource VN_Name3_microsoft_insights_VN3Diagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
   name: 'DiagService'
   scope: VN_3
  properties: {
   
    workspaceId: Workspaceid
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

resource VN_Name1_VN_Name1_Peering_To_VN_NAME2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-04-01' = {
  parent: VN_1
  name: '${VN_Name1}-Peering-To-${VN_Name2}'
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: VN_2.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        VN_Name2Prefix
      ]
    }
  }
  dependsOn: [
    VN_3
    VN_Name1_VN_Name1Subnet1
    VN_Name1_VN_Name1Subnet2
  ]
}

resource VN_Name1_VN_Name1_Peering_To_VN_NAME3 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-04-01' = {
  parent: VN_1
  name: '${VN_Name1}-Peering-To-${VN_Name3}'
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: VN_3.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        VN_Name3Prefix
      ]
    }
  }
  dependsOn: [
    VN_2

    VN_Name1_VN_Name1Subnet1
    VN_Name1_VN_Name1Subnet2
  ]
}

resource VN_Name2_VN_Name2_Peering_To_VN_NAME1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-04-01' = {
  parent: VN_2
  name: '${VN_Name2}-Peering-To-${VN_Name1}'
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: VN_1.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        VN_Name1Prefix
      ]
    }
  }
  dependsOn: [
    VN_3
    VN_Name1_VN_Name1Subnet1
    VN_Name1_VN_Name1Subnet2
  ]
}

resource VN_Name3_VN_Name3_Peering_To_VN_NAME1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-04-01' = {
  parent: VN_3
  name: '${VN_Name3}-Peering-To-${VN_Name1}'
  properties: {
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: VN_1.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        VN_Name1Prefix
      ]
    }
  }
  dependsOn: [
    VN_2

    VN_Name1_VN_Name1Subnet1
    VN_Name1_VN_Name1Subnet2
  ]
}

resource publicIpAddress1 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
  name: publicIpAddressName1
  location: location
  tags: {}
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicIpAddressName1_microsoft_insights_PIP1Diagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: publicIpAddress1
  name: 'DiagService'
  properties: {    
    workspaceId: Workspaceid
    logs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: true
      }
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: true
      }
      {
        category: 'DDoSMitigationReports'
        enabled: true
      }
    ]
  }
}

resource publicIpAddress2 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
  name: publicIpAddressName2
  location: location
  tags: {}
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicIpAddressName2_microsoft_insights_PIP2Diagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview'  = {
  name: 'DiagService'
  scope: publicIpAddress2
  properties: {
    workspaceId: Workspaceid
    logs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: true
      }
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: true
      }
      {
        category: 'DDoSMitigationReports'
        enabled: true
      }
    ]
  }
}

resource FW 'Microsoft.Network/azureFirewalls@2019-11-01' = {
  name: FW_Name
  location: location
  tags: {}
  properties: {
    threatIntelMode: 'Deny'
    ipConfigurations: [
      {
        name: publicIpAddressName1
        properties: {
          subnet: {
            id: VN_Name1_VN_Name1Subnet2.id
          }
          publicIPAddress: {
            id: publicIpAddress1.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
  dependsOn: [
    AG
  ]
}

resource FW_Name_microsoft_insights_FirewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'DiagService'
  scope: FW
  properties: {
    
    workspaceId: Workspaceid
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
        retentionPolicy: {
          days: 10
          enabled: false
        }
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
        retentionPolicy: {
          days: 10
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2019-06-01' = {
  name: firewallPolicyName
  location: location
  tags: {}
  properties: {
    threatIntelMode: 'Deny'
  }
  dependsOn: []
}

resource firewallPolicyName_DefaultDnatRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleGroups@2019-06-01' = {
  parent: firewallPolicy
  name: 'DefaultDnatRuleCollectionGroup'
  properties: {
    priority: 100
    rules: [
      {
        name: 'APPGW-WEBAPP'
        priority: 100
        ruleType: 'FirewallPolicyNatRule'
        action: {
          type: 'Dnat'
        }
        ruleCondition: {
          name: 'DNATRule'
          ipProtocols: [
            'TCP'
          ]
          destinationPorts: [
            '443'
          ]
          sourceAddresses: [
            '*'
          ]
          destinationAddresses: [
            publicIpAddress1.properties.ipAddress
          ]
          ruleConditionType: 'NetworkRuleCondition'
        }
        translatedAddress: AppGateway_IPAddress
        translatedPort: '443'
      }
      {
        name: VM_Name1
        priority: 101
        ruleType: 'FirewallPolicyNatRule'
        action: {
          type: 'Dnat'
        }
        ruleCondition: {
          name: 'DNATRule'
          ipProtocols: [
            'TCP'
          ]
          destinationPorts: [
            '33891'
          ]
          sourceAddresses: [
            '*'
          ]
          destinationAddresses: [
            publicIpAddress1.properties.ipAddress
          ]
          ruleConditionType: 'NetworkRuleCondition'
        }
        translatedAddress: NIC_Name1Ipaddress
        translatedPort: '3389'
      }
      {
        name: VM_Name3
        priority: 103
        ruleType: 'FirewallPolicyNatRule'
        action: {
          type: 'Dnat'
        }
        ruleCondition: {
          name: 'DNATRule'
          ipProtocols: [
            'TCP'
          ]
          destinationPorts: [
            '33890'
          ]
          sourceAddresses: [
            '*'
          ]
          destinationAddresses: [
            publicIpAddress1.properties.ipAddress
          ]
          ruleConditionType: 'NetworkRuleCondition'
        }
        translatedAddress: NIC_Name3Ipaddress
        translatedPort: '3389'
      }
    ]
  }
}

resource firewallPolicyName_DefaultNetworkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleGroups@2019-06-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    rules: [
      {
        name: 'IntraVNETAccess'
        priority: 100
        ruleType: 'FirewallPolicyFilterRule'
        action: {
          type: 'Allow'
        }
        ruleConditions: [
          {
            name: 'SMB'
            ipProtocols: [
              'TCP'
            ]
            destinationPorts: [
              '445'
            ]
            sourceAddresses: [
              NIC_Name2Ipaddress
              NIC_Name3Ipaddress
              NIC_Name1Ipaddress
            ]
            destinationAddresses: [
              NIC_Name2Ipaddress
              NIC_Name3Ipaddress
              NIC_Name1Ipaddress
            ]
            ruleConditionType: 'NetworkRuleCondition'
          }
          {
            name: 'RDP'
            ipProtocols: [
              'TCP'
            ]
            destinationPorts: [
              '3389'
            ]
            sourceAddresses: [
              NIC_Name2Ipaddress
              NIC_Name3Ipaddress
              NIC_Name1Ipaddress
            ]
            destinationAddresses: [
              NIC_Name2Ipaddress
              NIC_Name3Ipaddress
              NIC_Name1Ipaddress
            ]
            ruleConditionType: 'NetworkRuleCondition'
          }
          {
            name: 'SSH'
            ipProtocols: [
              'TCP'
            ]
            destinationPorts: [
              '22'
            ]
            sourceAddresses: [
              NIC_Name2Ipaddress
              NIC_Name3Ipaddress
            ]
            destinationAddresses: [
              NIC_Name1Ipaddress
            ]
            ruleConditionType: 'NetworkRuleCondition'
          }
        ]
      }
    ]
  }
  dependsOn: [
    firewallPolicyName_DefaultDnatRuleCollectionGroup
  ]
}

resource firewallPolicyName_DefaultApplicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleGroups@2019-06-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    rules: [
      {
        name: 'Internet-Access'
        priority: 100
        ruleType: 'FirewallPolicyFilterRule'
        action: {
          type: 'Allow'
        }
        ruleConditions: [
          {
            name: 'SearchEngineAccess'
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '*'
            ]
            targetFqdns: [
              'www.google.com'
              'www.bing.com'
              'google.com'
              'bing.com'
            ]
            fqdnTags: []
            ruleConditionType: 'ApplicationRuleCondition'
          }
        ]
      }
    ]
  }
  dependsOn: [
    firewallPolicyName_DefaultNetworkRuleCollectionGroup
  ]
}



resource FrontDoor 'Microsoft.Network/frontdoors@2019-04-01' = {
  name: FrontDoorName
  location: 'global'
  tags: {}
  properties: {
    friendlyName: FrontDoorName
    enabledState: 'Enabled'
    healthProbeSettings: [
      {
        name: 'healthProbeSettings1'
        properties: {
          path: '/'
          protocol: 'Http'
          intervalInSeconds: 30
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: 'loadBalancingSettings1'
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    frontendEndpoints: [
      {
        name: '${FrontDoorName}-azurefd-net'
        properties: {
          hostName: '${FrontDoorName}.azurefd.net'
          sessionAffinityEnabledState: 'Disabled'
          sessionAffinityTtlSeconds: 0
          webApplicationFirewallPolicyLink: {
            id: FrontdoorPolicy.id 
          }
        }
      }
    ]
    backendPools: [
      {
        name: 'OWASP'
        properties: {
          backends: [
            {
              address: publicIpAddress2.properties.ipAddress
              enabledState: 'Enabled'
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 50
              backendHostHeader: publicIpAddress2.properties.ipAddress
            }
          ]
          loadBalancingSettings: {
            id: resourceId(
              'Microsoft.Network/frontDoors/loadBalancingSettings',
              FrontDoorName,
              'loadBalancingSettings1'
            )
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', FrontDoorName, 'healthProbeSettings1')
          }
        }
      }
    ]
    routingRules: [
      {
        name: 'AppGW'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontEndEndpoints', FrontDoorName, '${FrontDoorName}-azurefd-net')
            }
          ]
          acceptedProtocols: [
            'Http'
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          enabledState: 'Enabled'
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', FrontDoorName, 'OWASP')
            }
          }
        }
      }
    ]
  }
}

resource FrontdoorPolicy 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2019-10-01' = {
  name: FrontdoorPolicyName
  location: 'Global'
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      redirectUrl: 'https://www.microsoft.com/en-us/edge'
      customBlockResponseStatusCode: 403
      customBlockResponseBody: 'QmxvY2tlZCBieSBmcm9udCBkb29yIFdBRg=='
    }
    customRules: {
      rules: [
        {
          name: 'BlockGeoLocationChina'
          enabledState: 'Enabled'
          priority: 10
          ruleType: 'MatchRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 100
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'GeoMatch'
              negateCondition: false
              matchValue: [
                'CN'
              ]
              transforms: []
            }
          ]
          action: 'Block'
        }
        {
          name: 'RedirectInternetExplorerUserAgent'
          enabledState: 'Enabled'
          priority: 20
          ruleType: 'MatchRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 100
          matchConditions: [
            {
              matchVariable: 'RequestHeader'
              selector: 'User-Agent'
              operator: 'Contains'
              negateCondition: false
              matchValue: [
                'rv:11.0'
              ]
              transforms: []
            }
          ]
          action: 'Redirect'
        }
        {
          name: 'RateLimitRequest'
          enabledState: 'Enabled'
          priority: 30
          ruleType: 'RateLimitRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 1
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Contains'
              negateCondition: false
              matchValue: [
                'search'
              ]
              transforms: []
            }
          ]
          action: 'Block'
        }
      ]
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '1.1'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
          ruleGroupOverrides: []
          exclusions: []
        }
      ]
    }
  }
}

resource FrontDoorName_microsoft_insights_FrontDoorDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagService'
  scope: FrontDoor
  properties: {
    
    workspaceId: Workspaceid
    logs: [
      {
        category: 'FrontdoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontdoorWebApplicationFirewallLog'
        enabled: true
      }
    ]
  }
}

resource RT_1 'Microsoft.Network/routeTables@2019-02-01' = {
  name: RT_Name1
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'DefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.25.4'
        }
      }
    ]
  }
  dependsOn: []
}

resource NSG_1 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: NSG_Name1
  location: location
  tags: {}
  properties: {
    securityRules: [
      {
        name: 'Allow-Spoke2-VNET'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: VN_Name3Prefix
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow-Spoke2-VNET-outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: VN_Name3Prefix
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource NSG_Name1_microsoft_insights_NSG1Diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagService'
  scope: NSG_1
  properties: {
    
    workspaceId: Workspaceid
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

resource NSG_2 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: NSG_Name2
  location: location
  tags: {}
  properties: {
    securityRules: [
      {
        name: 'Allow-Spoke1-VNET-Inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: VN_Name2Prefix
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow-Spoke1-VNET-Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: VN_Name2Prefix
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource NSG_Name2_microsoft_insights_NSG2Diagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagService'
  scope: NSG_2
  properties: {
    workspaceId: Workspaceid
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

resource Site_1 'Microsoft.Web/sites@2018-11-01' = {
  name: Site_Name1
  location: location
  tags: {}
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      linuxFxVersion: 'DOCKER|bkimminich/juice-shop'
      alwaysOn: true
    }
    serverFarmId: Site_HPN.id
    clientAffinityEnabled: false
  }

}

resource Site_HPN 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: Site_HPN_var
  location: location
  sku: {
    tier: 'Basic'
    name: 'B1'
  }
  kind: 'linux'
  properties: {
    targetWorkerSizeId: 3
    targetWorkerCount: 1
    reserved: true
  }
}

resource NIC_1 'Microsoft.Network/networkInterfaces@2019-07-01' = {
  name: NIC_Name1
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: NIC_Name1Ipaddress
          subnet: {
            id: '${VN_2.id}/subnets/${VN_Name2Subnet1Name}'
          }
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
  }
}

resource NIC_2 'Microsoft.Network/networkInterfaces@2019-07-01' = {
  name: NIC_Name2
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: NIC_Name2Ipaddress
          subnet: {
            id: '${VN_2.id}/subnets/${VN_Name2Subnet2Name}'
          }
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
  }
}

resource NIC_3 'Microsoft.Network/networkInterfaces@2019-07-01' = {
  name: NIC_Name3
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: NIC_Name3Ipaddress
          subnet: {
            id: '${VN_3.id}/subnets/${VN_Name3Subnet1Name}'
          }
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
  }
}

resource VM_1 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: VM_Name1
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        name: '${VM_Name1}-datadisk1'
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-24h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NIC_1.id
        }
      ]
    }
    osProfile: {
      computerName: VM_Name1
      adminUsername: DefaultUserName
      adminPassword: DefaultPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
  }
}

resource VM_3 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: VM_Name3
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        name: '${VM_Name3}-datadisk1'
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NIC_3.id
        }
      ]
    }
    osProfile: {
      computerName: VM_Name3
      adminUsername: DefaultUserName
      adminPassword: DefaultPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    licenseType: 'Windows_Server'
  }
}


output HUBVNET_ID string = VN_1.id
output SPOKE1VNET_ID string = VN_2.id
output SPOKE2VNET_ID string = VN_3.id


