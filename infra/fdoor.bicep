param FrontdoorPolicyName string = 'FrontDoorWafPolicy'
param publicIpAddress string = ''

var FrontDoorName  = 'Demowasp-${uniqueString(resourceGroup().id)}'


resource FrontDoorWafPolicy 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2024-02-01' = {
  name: FrontdoorPolicyName
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      redirectUrl: 'https://www.microsoft.com/en-us/edge'
      customBlockResponseStatusCode: 403
      customBlockResponseBody: 'UW14dlkydGxaQ0JpZVNCbWNtOXVkQ0JrYjI5eUlGZEJSZz09'
      requestBodyCheck: 'Enabled'
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
          groupBy: []
        }
        {
          name: 'RedirectInternetExplorerUserAgent'
          enabledState: 'Enabled'
          priority: 20
          ruleType: 'RateLimitRule'
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
          groupBy: [
            {
              variableName: 'SocketAddr'
            }
          ]
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
          groupBy: [
            {
              variableName: 'SocketAddr'
            }
          ]
        }
      ]
    }
    managedRules: {
      managedRuleSets: []
    }
  }
}

resource FrontDoor 'Microsoft.Cdn/profiles@2025-04-15' = {
  name: FrontDoorName
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  kind: 'frontdoor'
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

resource FrontDoorEndpointfd 'Microsoft.Cdn/profiles/afdendpoints@2025-04-15' = {
  parent: FrontDoor
  name: '${FrontDoorName}-azurefd-net'
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource FrontDoorName_default_origin_group 'Microsoft.Cdn/profiles/origingroups@2025-04-15' = {
  parent: FrontDoor
  name: 'default-origin-group'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 2
      additionalLatencyInMilliseconds: 30
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 30
    }
    sessionAffinityState: 'Disabled'
  }
}

resource FrontDoorName_default_origin_group_OWASP 'Microsoft.Cdn/profiles/origingroups/origins@2025-04-15' = {
  parent: FrontDoorName_default_origin_group
  name: 'OWASP'
  properties: {
    hostName: publicIpAddress
    httpPort: 80
    httpsPort: 443
    originHostHeader: publicIpAddress
    priority: 1
    weight: 50
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

resource FrontDoorWafPolicyOwasp 'Microsoft.Cdn/profiles/securitypolicies@2025-04-15' = {
  parent: FrontDoor
  name: 'OWASP'
  properties: {
    parameters: {
      wafPolicy: {
        id: FrontDoorWafPolicy.id
      }
      type: 'WebApplicationFirewall'
      associations: [
        {
          domains: [
            {
              id: FrontDoorEndpointfd.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

resource FrontDoorEndpointfd_default_route 'Microsoft.Cdn/profiles/afdendpoints/routes@2025-04-15' = {
  parent: FrontDoorEndpointfd
  name: 'default-route'
  properties: {
    customDomains: []
    originGroup: {
      id: FrontDoorName_default_origin_group.id
    }
    ruleSets: []
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}
