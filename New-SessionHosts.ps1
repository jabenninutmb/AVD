Param (        
    [Parameter(Mandatory=$true)]
        [string]$RegistrationToken          
)

$LocalWVDpath            = "c:\temp\wvd\"
$WVDBootURI              = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDAgentURI             = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$WVDAgentInstaller       = 'WVD-Agent.msi'
$WVDBootInstaller        = 'WVD-Bootloader.msi'

####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path c:\temp) -eq $false) {
    New-Item -Path c:\temp -ItemType Directory
}
if((Test-Path $LocalWVDpath) -eq $false) {
    New-Item -Path $LocalWVDpath -ItemType Directory
}
New-Item -Path c:\ -Name New-WVDSessionHost.log -ItemType File
Add-Content `
-LiteralPath C:\New-WVDSessionHost.log `
"
ProfilePath       = $ProfilePath
RegistrationToken = $RegistrationToken
Optimize          = $Optimize
"

#################################
#    Download WVD Componants    #
#################################
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Downloading WVD Boot Loader"
    Invoke-WebRequest -Uri $WVDBootURI -OutFile "$LocalWVDpath$WVDBootInstaller"
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Downloading WVD Agent"
    Invoke-WebRequest -Uri $WVDAgentURI -OutFile "$LocalWVDpath$WVDAgentInstaller"


################################
#    Install WVD Componants    #
################################
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Bootloader"
$bootloader_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDBootInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "/l* $LocalWVDpath\AgentBootLoaderInstall.txt" `
    -Wait `
    -Passthru
$sts = $bootloader_deploy_status.ExitCode
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Bootloader Complete"
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
Wait-Event -Timeout 5
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Agent"
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"
$agent_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDAgentInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "REGISTRATIONTOKEN=$RegistrationToken", "/l* $LocalWVDpath\AgentInstall.txt" `
    -Wait `
    -Passthru
Add-Content -LiteralPath C:\New-WVDSessionHost.log "WVD Agent Install Complete"
Wait-Event -Timeout 5

##########################
#    Restart Computer    #
##########################
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Process Complete - REBOOT"
Restart-Computer -Force 
