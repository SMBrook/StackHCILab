 
  param virtualMachineName string = 'HCIHNV001'
  param adminusername string = 'hciadmin'
  param vnetname string = 'HCILab-VNET'
  param vnetaddressspace string = '10.88.0.0/16'
  param subnetaddressspace string = '10.88.0.0/24'
  
  @secure()
  param adminpassword string

  resource VNET 'Microsoft.Network/virtualNetworks@2021-02-01' = {
    name: vnetname
    location: resourceGroup().location
    properties: {
      addressSpace: {
        addressPrefixes: [
            vnetaddressspace
        ]
      }
      subnets:[
        {
              name: 'HciSubnet'
              properties: {
                  addressPrefix: subnetaddressspace
              }
        }
      ]
    }
  }

  resource NSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
    name: '${virtualMachineName}-nsg'
    location: resourceGroup().location
    properties: {
      securityRules: [
        {
            name: 'RDP'
            properties: {
                priority: 300
                protocol: 'Tcp'
                access:'Allow'
                direction: 'Inbound'
                sourceAddressPrefix: '*'
                sourcePortRange: '*'
                destinationAddressPrefix: '*'
                destinationPortRange: '3389'
            }
        }
    ]
    }
  }

  resource PIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
    name: '${virtualMachineName}-Publicip'
    location: resourceGroup().location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
    sku: {
      name: 'Basic'
    }
  }

  resource networkInterfaceName_resource 'Microsoft.Network/networkInterfaces@2021-02-01' = {
    name: '${virtualMachineName}-Nic1'
    location: resourceGroup().location
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            subnet: {
              id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', VNET.name, 'HciSubnet')
            }
            privateIPAllocationMethod: 'Dynamic'
            publicIPAddress: {
              id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', PIP.name)
            }
          }
        }
      ]
      networkSecurityGroup: {
        id: NSG.id
      }
    }
  }

  resource dataDiskResources_name 'Microsoft.Compute/disks@2020-12-01' = [for i in range(0,7): {
    name: '${virtualMachineName}_DataDisk_${i}'
    location: resourceGroup().location
    sku: {
      name:'StandardSSD_LRS'
    }
    properties: {
      diskSizeGB: 256
      creationData: {
        createOption: 'Empty'
    }
   }
  }]

  resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2020-12-01' = {
    name: virtualMachineName
    location: resourceGroup().location
    properties: {
      hardwareProfile: {
        vmSize: 'Standard_D32s_v3'
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2019-Datacenter'
          version: 'latest'
        }
        dataDisks: [for i in range(0,7): {
          name: '${virtualMachineName}_DataDisk_${i}'
          lun: '${i}'
          createOption: 'Attach'
          caching: 'ReadOnly'
          writeAcceleratorEnabled: false
          managedDisk:{
            id: resourceId('Microsoft.Compute/disks', 'ASHCIHost001_DataDisk_${i}')
         }
        }]
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: networkInterfaceName_resource.id
          }
        ]
      }
      osProfile: {
        computerName: virtualMachineName
        adminUsername: adminusername
        adminPassword: adminpassword
        windowsConfiguration: {
          enableAutomaticUpdates: true
          provisionVMAgent: true
          patchSettings: {
            patchMode: 'AutomaticByOS'
          }
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }

  resource virtualMachineName_ConfigureAsHciHost 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
    parent: virtualMachineName_resource
    name: 'ConfigureAsHciHost'
    location: resourceGroup().location
    properties: {
      publisher: 'Microsoft.Powershell'
      type: 'DSC'
      typeHandlerVersion: '2.77'
      autoUpgradeMinorVersion: true
      settings: {
        wmfVersion: 'latest'
        configuration: {
          url: dscUri
          script: 'configurehost.ps1'
          function: 'HCIHyperVHost'
        }
        configurationArguments: {
          customRdpPort: 3389
        }
      }
      protectedSettings: {
        configurationArguments: {
          adminCreds: {
            UserName: adminusername
            Password: adminpassword
          }
        }
      }
    }
    dependsOn: [
      virtualMachineName_resource
    ]
  }
  
  resource shutdown_computevm_virtualMachineName 'Microsoft.DevTestLab/schedules@2018-09-15' = {
    name: 'shutdown-computevm-${virtualMachineName}'
    location: resourceGroup().location
    properties: {
      status: 'Enabled'
      taskType: 'ComputeVmShutdownTask'
      dailyRecurrence: {
        time: '20:00'
      }
      timeZoneId: 'UTC'
      targetResourceId: virtualMachineName_resource.id
    }
  }
