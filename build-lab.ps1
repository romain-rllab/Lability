Configuration DeployMyLab
{
    [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Credential 'Administrator')
    Import-DscResource -Module PSDesiredStateConfiguration,xActiveDirectory,xNetworking,xSmbShare,xDhcpServer,xComputerManagement

    Node $AllNodes.Where({$true}).NodeName {
        LocalConfigurationManager               
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true         
            AllowModuleOverwrite = $true   
        } 
    }

    Node $AllNodes.Where{$_.ServerType -eq "DC"}.NodeName
    {

        xComputer 'Hostname' {
            Name = $node.NodeName;
        }

        xIPAddress IPAddress {
            InterfaceAlias = 'Ethernet'
            IPAddress = $Node.IPAddress
            AddressFamily = 'IPV4'
        }         
            
        File NTDSFolder            
        {            
            DestinationPath = 'C:\NTDS'  
            Type = 'Directory'            
            Ensure = 'Present'            
        }            
                    
        WindowsFeature InstallADDS
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"             
        }        
              
        xADDomain ADDomain             
        {             
            DomainName = $ConfigurationData.NonNodeData.DomainNameFQDN       
            DomainNetbiosName = $ConfigurationData.NonNodeData.DomainName    
            DomainAdministratorCredential = $Credential         
            SafemodeAdministratorPassword = $Credential       
            DatabasePath = 'C:\NTDS'            
            LogPath = 'C:\NTDS'            
            DependsOn = "[WindowsFeature]InstallADDS","[File]NTDSFolder"            
        }

        $Node.ActiveDirectoryConfiguration.OrganizationalUnits.foreach( {
            xADOrganizationalUnit "OU=$($_.Name),$($_.Path))"
            {
                Ensure = 'Present'
                Name = $_.Name
                Path = $_.Path
                PsDscRunAsCredential = $Credential
                ProtectedFromAccidentalDeletion = $true
            }
        })

        $Node.ActiveDirectoryConfiguration.Users.foreach( {
            xADUser $_.UserName
            {
                DomainName = $ConfigurationData.NonNodeData.DomainName
                Ensure = 'Present'
                Username = $_.UserName
                Path = $Node.ActiveDirectoryConfiguration.UserLocation."$($_.Type)"
                PsDscRunAsCredential = $Credential
                Enabled = $true
                Password = $Credential
                UserPrincipalName = "$($_.Username)@$($ConfigurationData.NonNodeData.DomainNameFQDN)"
            }
        })

        $Node.ActiveDirectoryConfiguration.Computers.foreach( {
            xADComputer $_.ComputerName
            {
                
                Ensure = 'Present'
                ComputerName = $_.ComputerName
                Path = $Node.ActiveDirectoryConfiguration.ComputerLocation."$($_.Type)"
                PsDscRunAsCredential = $Credential
                Enabled = $true
            }
        })

        $Node.ActiveDirectoryConfiguration.Groups.foreach( {
            xADGroup $_.GroupName
            {
                Ensure = 'Present'
                GroupName = $_.GroupName
                Category = 'Security'
                PsDscRunAsCredential = $Credential
                GroupScope = $_.GroupScope
                Path = $Node.ActiveDirectoryConfiguration.GroupLocation."$($_.GroupType)"
                Description = $_.Description
                MembershipAttribute = 'SamAccountName'
                Members = $_.Members
            }
        })
        
        
    }
    Node $AllNodes.Where{$_.ServerType -eq "Member"}.NodeName
    {
        $domainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("$($Credential.UserName)@$($ConfigurationData.NonNodeData.DomainName)", $Credential.Password);

        xIPAddress IPAddress {
            InterfaceAlias = 'Ethernet'
            IPAddress = $Node.IPAddress
            AddressFamily = 'IPV4'
        }         
            
        xDefaultGatewayAddress GW
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPV4'
            Address = $Node.Gateway
            DependsOn = '[xIPAddress]IPAddress'
        }

        xDnsServerAddress DNS

        {
            InterfaceAlias = 'Ethernet'
            Address        = $Node.DNSServer
            AddressFamily  = 'IPV4'
            Validate       = $false
            DependsOn = '[xIPAddress]IPAddress'

        } 
        
        File FolderShares            
        {            
            DestinationPath = 'C:\Shares'            
            Type = 'Directory'            
            Ensure = 'Present'            
        }            

        File DSCFolder         
        {            
            DestinationPath = 'C:\Shares\DSCFolder'            
            Type = 'Directory'            
            Ensure = 'Present'        
            DependsOn = '[File]FolderShares'    
        }  

        xSmbShare DSCShare
        {
          Ensure = 'Present'
          Name   = 'Share1'
          Path = 'C:\Shares\DSCFolder'
          Description = "This is a shared folder for my lab"  
          DependsOn = '[File]DSCFolder'
        }

        xComputer NewNameAndJoinDomain
        { 
            Name          = $Node.NodeName
            DomainName = $ConfigurationData.NonNodeData.DomainNameFQDN
            Credential = $domainCredential
            DependsOn = '[xIPAddress]IPAddress','[xDnsServerAddress]DNS'
        }

        WindowsFeature DHCP {
            Ensure = 'Present'
            Name = 'DHCP'
            IncludeAllSubFeature = $true  
        }

        
        xDhcpServerScope DHCPLabScope {
            
            Ensure = 'Present'
            ScopeID = $Node.DHCPConfiguration.DHCPScope
            IPStartRange = $Node.DHCPConfiguration.DHCPScopeStart
            IPEndRange = $Node.DHCPConfiguration.DHCPScopeEnd
            Name = $Node.DHCPConfiguration.DHCPScopeName
            SubnetMask = '255.255.255.0'
            LeaseDuration = '00:08:00'
            State = 'Active'
            AddressFamily = 'IPv4'
        }

        xDhcpServerOption DHCPLabServerOption {
            Ensure = 'Present'
            ScopeID =  $Node.DHCPConfiguration.DHCPScope
            DnsDomain = $ConfigurationData.NonNodeData.DomainNameFQDN
            DnsServerIPAddress = $Node.DNSServer
            Router = $Node.Gateway
            AddressFamily = 'IPV4'
            DependsOn = '[xDhcpServerScope]DHCPLabScope'
        }
        
        xDhcpServerAuthorization AuthorizeDHCP
        {
            Ensure = 'Present'
            PSDscRunAsCredential = $domainCredential
            DnsName = $ConfigurationData.NonNodeData.DomainNameFQDN
            DependsOn = '[WindowsFeature]DHCP'
        }

    }
}

DeployMyLab -ConfigurationData '.\build-lab.psd1' -OutputPath ".\Configurations\"