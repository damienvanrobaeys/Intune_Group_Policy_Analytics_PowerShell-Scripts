<#PSScriptInfo
.VERSION 1.0.0
.AUTHOR Damien VAN ROBAEYS
.DESCRIPTION Import GPO report (from XML) to Intune Group Policy Analytics
.PROJECTURI https://github.com/damienvanrobaeys/Intune_Group_Policy_Analytics_PowerShell-Scripts
#>

<#
.SYNOPSIS
    Gather device hash from local machine and automatically upload it to Autopilot.
.DESCRIPTION
    This script automatically gathers the device hash, serial number, manufacturer and model and uploads that data into Autopilot.
    Authentication is required within this script and required permissions for creating Autopilot device identities are needed.
.PARAMETER Export_GPO
	Specify if yoy want to export GPO report directely from the AD server, or device that have access to the Group Policy Management
	This parameter is a switch
.PARAMETER All_GPO
    Specify to export all GPOs in one XML report
	This parameter is a switch	
.PARAMETER Domain
    Specify the domain FQDN. This parameter works with the All_GPO switch
	This parameter is a string		
.PARAMETER AD_SRV
    Specify the server AD name. This parameter works with the All_GPO switch
	This parameter is a string	
.PARAMETER GPO_Name
    Specify the namre of the GPO to export to XML format
	Do not select this parameter if you have selected All_GPO
.PARAMETER XML_Path
    Specify the path of the GPO XML report
.PARAMETER Check_Modules
	Specify if you want the script to check presence of modules: PowerShellGet, Nuget and Microsoft.Graph.Intune
	If you don't select this switch, the script will go faster
	This parameter is a switch	
.EXAMPLE
	# Export all GPOs from domain systanddeploy.lab.local, server ADSRV. 
	# The GPO report will be saved in c:\AllGPOs.xml 
	# Then import the GPO report to Intune
	New-IntuneGroupPolicyReport.ps1 -Export_GPO -All_GPO -Domain "systanddeploy.lab.local" -Server "ADSRV" -XML_Path  "c:\AllGPOs.xml"

	# Export the GPO GPO_Network. 
	# The GPO report will be saved in c:\GPO_Network.xml 
	# Then import the GPO report to Intune.	
	New-IntuneGroupPolicyReport.ps1 -Export_GPO -GPO_Name "GPO_Network" -XML_Path  "c:\GPO_Network.xml"

	# Do not export GPO, we will work from an existing XML 
	# The GPO report to import to Intune is located in c:\GPO_Network.xml 
	New-IntuneGroupPolicyReport.ps1 -XML_Path  "c:\GPO_Network.xml"
#>


[CmdletBinding()]
Param(
		[Parameter(Mandatory=$false)]
		[switch]$Export_GPO,
		[switch]$All_GPO,
		[string]$Domain,	
		[string]$AD_SRV,			
		[string]$GPO_Name,		
		[string]$XML_Path,	
		[switch]$Check_Modules		
		# [switch]$Secure_Creds,		
		# [string]$PWD_File,
		# [string]$PWD,		
		# [string]$User											
	 )
			
Function Write_Log
	{
		param(
		$Message_Type,	
		$Message
		)
		
		$MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)		
		write-host "$MyDate - $Message_Type : $Message"
	}			
			 
If($XML_Path -eq "")
	{
		Write_Log -Message_Type "INFO" -Message "GPO report XML path is empty "														
		$XML_Path = Read-Host "GPO XML Path - Please type the path of your GPO XML report"
	}
	
Write_Log -Message_Type "INFO" -Message "GPO report XML path is: $XML_Path"	
write-host ""
		
If($Export_GPO)
	{
		Write_Log -Message_Type "INFO" -Message "User has selected export GPO report mode"				
		If($All_GPO)
			{
				Write_Log -Message_Type "INFO" -Message "User has selected export all GPOs report"									
				If($Domain -eq "")
					{
						$Domain = Read-Host "Active Directory domain - Please type the FQDN of your domain"		
					}
					
				If($AD_SRV -eq "")
					{
						$AD_SRV = Read-Host "Doamin server - Please type name of the AD server"									
					}
					
				Write_Log -Message_Type "INFO" -Message "AD Server is: $AD_SRV"																
				Write_Log -Message_Type "INFO" -Message "Domain FQDN is: $Domain"																
					
				Try
					{						
						Get-GPOReport -All -Domain $Domain -Server $AD_SRV -ReportType XML -Path $XML_Path	
						Write_Log -Message_Type "SUCCESS" -Message "The GPO report has been successfully created in: $XML_Path"																	
					}
				Catch
					{
						Write_Log -Message_Type "ERROR" -Message "An issue occured while creating the GPO report"																								
					}
			}
		Else
			{
				If($GPO_Name -eq "")
					{
						$GPO_Name = Read-Host "GPO name - Please type name of the GPO to backup"														
					}		
				Write_Log -Message_Type "INFO" -Message "User has selected export GPO: $GPO_Name"																
				Try
					{						
						Get-GPOReport -Name $GPO_Name -ReportType XML -Path $XML_Path		
						Write_Log -Message_Type "SUCCESS" -Message "The GPO report for $GPO_Name has been successfully created in: $XML_Path"																	
					}
				Catch
					{
						Write_Log -Message_Type "ERROR" -Message "An issue occured while creating the GPO report"																								
					}
				
			}		
	}
	
If($Check_Modules)
	{
		write-host ""	
		$Is_Module_PoshGet_Installed = $False
		$Module_Name = "PowershellGet"
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		If (!(Get-Module -listavailable | where {$_.name -like "*$Module_Name*"})) 
			{ 
				Write_Log -Message_Type "INFO" -Message "The module $Module_Name is not installed"																
				Write_Log -Message_Type "INFO" -Message "Installing module $Module_Name"	

				Try
					{
						Install-Module $Module_Name -Force -confirm:$false 
						Write_Log -Message_Type "SUCCESS" -Message "The package $Module_Name has been successfully installed"	
						$Is_Module_PoshGet_Installed = $True						
					}
				Catch
					{
						Write_Log -Message_Type "ERROR" -Message "An issue occured while installing module $Module_Name"																								
					}				
			} 
		Else 
			{ 				
				Write_Log -Message_Type "INFO" -Message "Importing module $Module_Name"																
				Try
					{
						Import-Module $Module_Name -ErrorAction SilentlyContinue 					
						Write_Log -Message_Type "SUCCESS" -Message "The module $Module_Name has been successfully imported"
						$Is_Module_PoshGet_Installed = $True												
					}
				Catch
					{
						Write_Log -Message_Type "ERROR" -Message "An issue occured while importing module $Module_Name"																								
					}				
			} 
			

		If($Is_Module_PoshGet_Installed -eq $True)
			{	
				# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
				write-host ""		
				$Is_Nuget_Installed = $False
				$Module_Name = "Nuget"	
				If (!(Get-PackageProvider -listavailable | where {(($_.name -like "*$Module_Name*") -and ($_.version -ge "2.8.5.201"))})) 
					{ 
						Write_Log -Message_Type "INFO" -Message "The package $Module_Name is not installed"																
						Write_Log -Message_Type "INFO" -Message "Installing package $Module_Name"	
							
						Try
							{
								[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
								Install-PackageProvider -Name Nuget -RequiredVersion 2.8.5.201 -Force | out-null													
								Write_Log -Message_Type "SUCCESS" -Message "The package $Module_Name has been successfully installed"	
								$Is_Nuget_Installed = $True						
							}
						Catch
							{
								Write_Log -Message_Type "ERROR" -Message "An issue occured while installing package $Module_Name"																								
							}				
					} 
				Else
					{
						Write_Log -Message_Type "INFO" -Message "The package $Module_Name is already installed"	
						$Is_Nuget_Installed = $True				
					}
					
					
				If($Is_Nuget_Installed -eq $True)
					{
						# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
						write-host ""		
						$Module_Name = "Microsoft.Graph.Intune"		
						If (!(Get-Module -listavailable | where {$_.name -like "*$Module_Name*"})) 
							{ 
								Write_Log -Message_Type "INFO" -Message "The module $Module_Name is not installed"																
								Write_Log -Message_Type "INFO" -Message "Installing module $Module_Name"	

								Try
									{
										[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
										Install-Module Microsoft.Graph.Intune -Force -confirm:$false 
										Write_Log -Message_Type "SUCCESS" -Message "The package $Module_Name has been successfully installed"	
										$Is_Module_Installed = $True						
									}
								Catch
									{
										Write_Log -Message_Type "ERROR" -Message "An issue occured while installing module $Module_Name"																								
									}			
							} 
						Else 
							{ 				
								Write_Log -Message_Type "INFO" -Message "Importing module $Module_Name"																
								Try
									{
										Import-Module $Module_Name -ErrorAction SilentlyContinue 					
										Write_Log -Message_Type "SUCCESS" -Message "The module $Module_Name has been successfully imported"
										$Is_Module_Installed = $True												
									}
								Catch
									{
										Write_Log -Message_Type "ERROR" -Message "An issue occured while importing module $Module_Name"																								
									}				
							}			
					}		
			}
	}
Else
	{
		$Is_Module_Installed = $True
	}

If($Is_Module_Installed -eq $True)
	{
		$Is_Intune_Connected = $False
		write-host ""											
		Write_Log -Message_Type "INFO" -Message "Connecting to Intune"	
		Try
			{
				Connect-MSGraph | out-null	
				Write_Log -Message_Type "SUCCESS" -Message "Successfully connected to Intune"		
				$Is_Intune_Connected = $True							
			}
		Catch
			{
				Write_Log -Message_Type "ERROR" -Message "An issue occured while connecting to Intune"																								
			}					
			
		If($Is_Intune_Connected -eq $True)
			{
				$Get_GPO_XML_Content = [xml](get-content $XML_Path)
				$Get_GPO_Name = $Get_GPO_XML_Content.GPO.name
				write-host ""
				Write_Log -Message_Type "INFO" -Message "Converting GPO report to Base64"	
				$Is_Base64_Convertion_OK = $False
				Try
					{			
						$GPO_XML_Content = [convert]::ToBase64String((Get-Content $XML_Path -Encoding byte))			
						Write_Log -Message_Type "SUCCESS" -Message "The GPO report has been successfully converted to Base64"	
						$Is_Base64_Convertion_OK = $True								
					}
				Catch
					{
						Write_Log -Message_Type "ERROR" -Message "An issue occured while converting the GPO to Base64"																								
					}	
				If($Is_Base64_Convertion_OK -eq $True)
					{

$MyProfile = @"
{
  "groupPolicyObjectFile": {
	"ouDistinguishedName": "$Get_GPO_Name",
	"content": "$GPO_XML_Content"
  }
}
"@
						write-host ""
						Write_Log -Message_Type "INFO" -Message "Uploading the GPO report to Intune"																							
						Try
							{			
								Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceManagement/groupPolicyMigrationReports/createMigrationReport" -HttpMethod POST -Content $MyProfile -ErrorAction Stop	| out-null									
								Write_Log -Message_Type "SUCCESS" -Message "The GPO report has been successfully uploaded to Intune"																											
							}
						Catch
							{
								Write_Log -Message_Type "ERROR" -Message "An issue occured while importing the GPO report to Intune"																								
							}
					}
			}
	}
	# }	 