@{

    AllNodes = 
    @(
        @{
            NodeName = "*"
            Lability_SwitchName         = 'RLLAB-NET-SWITCH';
        },
        @{
            
            NodeName = "DC1"

            Lability_ProcessorCount = 2;

            ServerType = 'DC'
            PSDscAllowDomainUser = $true
            PsDscAllowPlainTextPassword = $true
            IPAddress = "192.168.0.1/24"

            ActiveDirectoryConfiguration = @{
                #DSRMCredentials = (Get-Credential -UserName '(DSRM Password)' -Message "DSRM Password")     
                OrganizationalUnits = @(
                    #objets à la racine du domaine
                    @{
                        Name = 'CORP'
                        Path = "DC=RLLAB,DC=NET"
                        
                    },
                    @{
                        Name = 'Admin'
                        Path = "DC=RLLAB,DC=NET"
                        
                    },
                    #OUs dans la section "CORP"
                    @{
                        Name="Users"
                        Path="OU=CORP,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Servers"
                        Path="OU=CORP,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Computers"
                        Path= "OU=CORP,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Groups"
                        Path= "OU=CORP,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Rights"
                        Path= "OU=CORP,DC=RLLAB,DC=NET"
                    },
                    #OUs dans la section "Admin"
                    @{
                        Name="Services"
                        Path="OU=Admin,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Users"
                        Path="OU=Admin,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Groups"
                        Path="OU=Admin,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Rights"
                        Path="OU=Admin,DC=RLLAB,DC=NET"
                    },
                    @{
                        Name="Servers"
                        Path="OU=Admin,DC=RLLAB,DC=NET"
                    }
            
                )

                Computers = @(
                    @{
                        Type = 'Server'
                        ComputerName = 'RLLAB-CORP-SRV1'
                    },
                    @{
                        Type = 'Workstation'
                        ComputerName = 'RLLAB-CORP-WKS1'
                    }
                )
                
                Users = @(
                    @{
                        Type = 'Standard'
                        UserName = 'user1'
                                        
                    },
                    @{
                        UserName = 'sys-wks-domainjoin'
                        Type = 'Service'
                    },
                    @{
                        UserName = 'romain-adm'
                        Type = 'Admin'
                    }
                )

                Groups =  @(
                    @{
                        GroupType = 'Standard'
                        GroupName = 'GG-DSC-Readers'
                        GroupScope = 'Global'
                        Description = 'Acces en lecture sur le partage DSC'

                    },
                    @{
                        GroupType = 'StandardRights'
                        GroupName = 'LG-DSC-Readers'
                        GroupScope = 'DomainLocal'
                        Members = 'GG-DSC-Readers'
                        Description = 'Utilisateurs en lecture sur le partage DSC'
                    },
                    @{
                        GroupType = 'Secure'
                        GroupName = 'GG-WKS-Domain-Join'
                        GroupScope = 'Global'
                        Members = 'sys-wks-domainjoin'
                        Description = 'Groupe de comptes qui peuvent joindre des poste de travail au domaine'
                    },
                    @{
                        GroupType = 'SecureRights'
                        GroupName = 'LG-WKS-Domain-Join'
                        GroupScope = 'DomainLocal'
                        Members = 'GG-WKS-Domain-Join'
                        Description = 'Droit de jonction de poste de travail au domaine'

                    }
                )
                ComputerLocation = @{
                    Server = 'OU=Servers,OU=CORP,DC=RLLAB,DC=NET'
                    Workstation = 'OU=Computers,OU=CORP,DC=RLLAB,DC=NET'
                }
                GroupLocation = @{
                    Standard = 'OU=Groups,OU=CORP,DC=RLLAB,DC=NET'
                    StandardRights = 'OU=Rights,OU=CORP,DC=RLLAB,DC=NET'
                    Secure = 'OU=Groups,OU=Admin,DC=RLLAB,DC=NET'
                    SecureRights ='OU=Rights,OU=Admin,DC=RLLAB,DC=NET'
                }
                UserLocation = 
                @{
                    Service = 'OU=Services,OU=Admin,DC=RLLAB,DC=NET'
                    Admin = 'OU=Users,OU=Admin,DC=RLLAB,DC=NET'
                    Standard = 'OU=Users,OU=CORP,DC=RLLAB,DC=NET'
                }
            }
            

        },
        
        @{
            NodeName = "SRV1"

            ServerType = 'Member'
            PSDscAllowDomainUser = $true
            PsDscAllowPlainTextPassword = $true
            IPAddress = "192.168.0.2/24"  
            DNSServer = "192.168.0.1"   
            Gateway = "192.168.0.254"  
            DHCPConfiguration = @{
                DHCPScope = "192.168.0.0"
                DHCPScopeName = "DHCPLABScope"
                DHCPScopeStart = "192.168.0.32"
                DHCPScopeEnd = "192.168.0.64"
            }
        }
    );
    NonNodeData =  @{
        #DefaultUserCredentials =  (Get-Credential -UserName "(Password Only)" -Message "Default User Credentials") 
        #Credentials =  (Get-Credential -UserName "RLLAB\Administrator" -Message "Build and join Password") 
        DomainNameFQDN = "RLLAB.NET"
        DomainName = "RLLAB"

        Lability = @{

            EnvironmentPrefix = 'RLLABILITY-CORP-';

            Media = @();

            Network = @(

                @{ Name = 'RLLAB-NET-SWITCH'; Type = 'Private'; }

            );


            DSCResource = @(
                @{ Name = 'xComputerManagement'; RequiredVersion = '4.1.0.0' ; Provider = 'PSGallery'; }
                @{ Name = 'xSmbShare';RequiredVersion = '2.1.0.0' ; Provider = 'PSGallery';}
                @{ Name = 'xNetworking';RequiredVersion = '5.7.0.0' ; Provider = 'PSGallery';}
                @{ Name = 'xActiveDirectory';RequiredVersion = '2.24.0.0' ; Provider = 'PSGallery';}
                @{ Name = 'xDhcpServer';RequiredVersion = '2.0.0.0' ; Provider = 'PSGallery';}

            );

        };

    }
}