# TODO: Unsafe, look for a better way of passing credentials
$connectionString = "Server=${var.db_server};Database=Octopus;User Name=${var.db_user};Password=${var.db_password};"

# TODO: Pass the password encrypted and secure. Also find a better way to inject the credentials
$octopusPassword = ConvertTo-SecureString "ImAPassword" -AsPlainText -Force
$octopusCreds = New-Object System.Management.Automation.PSCredential ("octopus", $octopusPassword)

$installerUrl = "https://octopus.com/downloads/slowlane/WindowsX64/OctopusServer"
$outputFile = "octopus.msi"
$outputPath = "$workingDir\$outputFile"

$webClient = New-Object System.Net.WebClient

Write-Host "Downloading Octopus installer."
$webClient.DownloadFile($installerUrl, "$outputPath")

Write-Host "Running Octopus installer."
Start-Process msiexec.exe -Wait -ArgumentList "/i $outputPath /l* octopus-setup.log /quiet RUNMANAGERONEXIT=no"

Write-Host "Configuring Octopus Server"
$installationPath = "C:\Program Files\Octopus Deploy\Octopus"
$octopusServerExe = "$($installationPath.replace(' ', '` '))\Octopus.Server.exe"

$octopusInstanceName = "OctopusServer"

$connectionString2 = "Server=octopus-test.cj9eiqytw0nx.us-east-1.rds.amazonaws.com;Database=Octopus;uid=rladmin;pwd=Radicalogic1;"

Invoke-Expression "$octopusServerExe create-instance --instance $octopusInstanceName --config D:\Octopus\octopus.config"
Invoke-Expression "$octopusServerExe database --instance $octopusInstanceName --connectionString '$connectionString2' --create"
Invoke-Expression "$octopusServerExe configure --instance $octopusInstanceName --upgradeCheck True --upgradeCheckWithStatistics True --usernamePasswordIsEnabled True --webForceSSL False --commsListenPort 10943 --serverNodeName localhost"
Invoke-Expression "$octopusServerExe service --instance $octopusInstanceName --stop"
Invoke-Expression "$octopusServerExe admin --instance $octopusInstanceName --username octopus --email pcorrea@rlsolutions.com --password R@dicalogic1"
# Invoke-Expression "$octopusServerExe license --instance $octopusInstanceName --licenseBase64 <a very long license string>"
Invoke-Expression "$octopusServerExe service --instance $octopusInstanceName --install --reconfigure --start"
