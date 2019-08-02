Write-Host "Listing attached volumes."
$id = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing
$volumes = Get-EC2Instance -InstanceId $id | 
    Select-Object -ExpandProperty Instances |
    Select-Object -ExpandProperty BlockDeviceMappings |
    Where-Object DeviceName -Like xvd*

foreach ($volume in $volumes){
    $volId = $volume | Select-Object -ExpandProperty Ebs |
    Select-Object -ExpandProperty VolumeId

    Write-Host "Initializing Volume '$volId' on mount point '$($volume.DeviceName)'."

    $diskSelector = "$($volId.Replace('vol-', 'vol'))*"
    $disk = Get-Disk |
       Where {($_.SerialNumber -like $diskSelector)}

    if (!$disk) { 
        Write-Host "Could not find disk."
        Continue
    }
    if ($disk.PartitionStyle -ne "raw") { 
        Write-Host "Disk found but already initialized."
        Continue
    }

    Write-Host "Initializing disk"

    $disk | Initialize-Disk -PartitionStyle MBR -PassThru |
        New-Partition -AssignDriveLetter -UseMaximumSize |
        Format-Volume -FileSystem NTFS -Confirm:$false

    Write-Host "Disk initialized"
}