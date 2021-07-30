configuration HCIHyperVHost

{

     param (

           [string]$NodeName = 'localhost',
           [System.Management.Automation.PSCredential]$parameterOfTypePSCredential1

     )

     node $NodeName {

           WindowsFeature 'Hyper-V' {

                Ensure='Present'

                Name='Hyper-V'

                IncludeAllSubFeature = $true

           }

           WindowsFeature 'Hyper-V-Powershell' {

                Ensure='Present'

                Name='Hyper-V-Powershell'

                IncludeAllSubFeature = $true

           }

           File VMsDirectory

           {

                Ensure = 'Present'

                Type = 'Directory'

                DestinationPath = "$($env:SystemDrive)\VMs"

           }
}

}