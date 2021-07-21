configuration HCIHyperVHost

{

     param (

           [string]$NodeName = 'localhost'

     )

     Import-DscResource -ModuleName xHyper-V

     node $NodeName {

           WindowsFeature 'Hyper-V' {

                Ensure='Present'

                Name='Hyper-V'

           }

           WindowsFeature 'Hyper-V-Powershell' {

                Ensure='Present'

                Name='Hyper-V-Powershell'

           }

           File VMsDirectory

           {

                Ensure = 'Present'

                Type = 'Directory'

                DestinationPath = "$($env:SystemDrive)\VMs"

           }

           xVMSwitch LabSwitch {

                DependsOn = '[WindowsFeature]Hyper-V'

                Name = 'HCISwitch'

                Ensure = 'Present'

                Type = 'Internal'

}

}

}