configuration HCIHyperVHost

{

     param (

           [string]$NodeName = 'localhost'

     )

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
}

}