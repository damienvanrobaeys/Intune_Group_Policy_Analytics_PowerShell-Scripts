<#PSScriptInfo
.VERSION 1.0.0
.AUTHOR Damien VAN ROBAEYS
.DESCRIPTION Removes a specific GPO report from Intune Group POlicy Analytics
.PROJECTURI https://github.com/damienvanrobaeys/Intune_Group_Policy_Analytics_PowerShell-Scripts
#>

<#
.SYNOPSIS
	Removes a specific GPO report from Intune Group POlicy Analytic
.DESCRIPTION
	This script allows you to connect on Intune, then specify the name of a GPO result to remove from the Group Policy Analytics page in Intune
.PARAMETER GPO_Name
    Specify the GPO name report to remove
.PARAMETER Check_Modules
	Specify if you want the script to check presence of modules: PowerShellGet, Nuget and Microsoft.Graph.Intune
	If you don't select this switch, the script will go faster
	This parameter is a switch		
.EXAMPLE
    # Remove the GPO report called GPO_Network
    .\Remove-IntuneGroupPolicyReport -GPO_Name "GPO_Network"
#>


[CmdletBinding()]
Param(
		[Parameter(Mandatory=$false)]
		[string]$GPO_Name,
		[switch]$Check_Modules				
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

If($GPO_Name -eq "")
	{
		$GPO_Name = Read-Host "GPO report - Please type the name of the GPO report to remove"									
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
				[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
						[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
						write-host ""		
						$Module_Name = "Microsoft.Graph.Intune"		
						If (!(Get-Module -listavailable | where {$_.name -like "*$Module_Name*"})) 
							{ 
								Write_Log -Message_Type "INFO" -Message "The module $Module_Name is not installed"																
								Write_Log -Message_Type "INFO" -Message "Installing module $Module_Name"	

								Try
									{
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
				$Get_GPO_Report_Status = $False
				write-host ""
				Write_Log -Message_Type "INFO" -Message "Getting informations about the GPO report"																							
				Try
					{			
						$Get_GPO_Reports = (Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceManagement/groupPolicyMigrationReports" -HttpMethod Get).Value
						Write_Log -Message_Type "SUCCESS" -Message "Successfully getting infos about the GPOs"	
						$Get_GPO_Report_Status = $True
					}
				Catch
					{
						Write_Log -Message_Type "ERROR" -Message "An issue occured while getting infos about GPO reports"																								
					}

				If($Get_GPO_Report_Status -eq $True)
					{
						write-host ""
						Write_Log -Message_Type "INFO" -Message "Removing the GPO report"																													
						$Get_Current_GPO = $Get_GPO_Reports | where {$_.ouDistinguishedName -like "*$GPO_Name*"}
						$Get_GPO_ID = $Get_Current_GPO.ID

						Try
							{			
								Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceManagement/groupPolicyObjectFiles/$Get_GPO_ID" -HttpMethod DELETE -ErrorAction Stop | out-null
								Write_Log -Message_Type "SUCCESS" -Message "The GPO report has been successfully removed from Intune"																											
							}
						Catch
							{
								Write_Log -Message_Type "ERROR" -Message "An issue occured while removing the GPO report from Intune"																								
							}					
					}
			}
	}
