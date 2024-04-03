# Copyright (c) 2010 - 2023 Nutanix Inc. All rights reserved.
# Author: era-dev@nutanix.com

#title           : era_sql_config.ps1
#description     : This powershell script when run on a customer's machine will give basic configuration of that machine need by ERA
#date            : 19/04/2018
#version         : 1.0
#usage		     : powershell.exe era_sql_config.ps1
#==============================================================================

# One Parameter is needed Instance Name

#Output of this file will be directed to C:\questionaire_output.txt
param(
    [string]$instance_name
)

Try {

    if (-Not $instance_name)
    {
        $(throw "Please specify Instance Name. In case of default instance, specify instance_name as MSSQLSERVER.")
    }
    $current_dir = pwd
    $Output_File =  "C:\questionaire_output.txt"
    if(Test-Path -path $Output_File){
        Remove-Item "$Output_File" -Force -Confirm:$false
    }
    $DEFAULT_INSTANCE = 'MSSQLSERVER'
    $hostname=HOSTNAME
    if($instance_name -eq $DEFAULT_INSTANCE){
        $connectionInstanceString = $hostname
    }
    else{
        $connectionInstanceString = $hostname + '\' + $instance_name
    }

    Write-Output "Capturing information to check configuration for instance $instance_name"
    Write-Output "Capturing information to check configuration on $(Get-Date) for instance $instance_name" > $Output_File

    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "WINDOWS VERSION" >> $Output_FilePlease check the Instance name.
    (gwmi win32_operatingsystem).caption >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "Getting the nic info " >> $Output_File
    Get-NetAdapter >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "HOSTNAME OF THE MACHINE This will tell us if any domain user is been used or not" >> $Output_File
    whoami >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "LIST OF ALL VOLUMES AND CORRESPONDING MOUNT POINTS or DRIVE LETTERS" >> $Output_File
    mountvol >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "List all Drive info along with the file system type" >> $Output_File
    [System.IO.DriveInfo]::GetDrives() | Format-Table >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "DATABASE COUNT FOR GIVEN INSTANCE $instance_name" >> $Output_File
    $queryForDatabasePerInstance = "SELECT COUNT(*) FROM sys.databases"
    Invoke-Sqlcmd -Query "$queryForDatabasePerInstance" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "List all databases which have log shipping configured $instance_name" >> $Output_File
    $queryForLogShippingDbInfo = "select primary_database from msdb.dbo.log_shipping_primary_databases"
    Invoke-Sqlcmd -Query "$queryForLogShippingDbInfo" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "SQL SOFTWARE IN" >> $Output_File
    $queryForSqlSoftwareLocation = "
declare @rc int, @dir nvarchar(4000)

exec @rc = master.dbo.xp_instance_regread
N'HKEY_LOCAL_MACHINE',
N'Software\Microsoft\MSSQLServer\Setup',
N'SQLPath',
@dir output, 'no_output'
select @dir AS InstallationDirectory
"

    Invoke-Sqlcmd -Query "$queryForSqlSoftwareLocation" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "DATABASE LAYOUT" >> $Output_File
    $queryForDatabaseLayout = "
DECLARE @sql VARCHAR (max)
DECLARE @DBname VARCHAR (50)
DECLARE DBS CURSOR FOR
SELECT name
FROM   sys.databases
OPEN DBS
FETCH next FROM DBS INTO @DBname
WHILE @@FETCH_STATUS = 0
BEGIN
SET @sql = 'select type_desc as category,volume_mount_point as device_name, CAST((size*8)/1024 AS VARCHAR(26)) AS FileSizeInMB, physical_name as file_name from sys.master_files AS f CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) WHERE f.database_id = (SELECT database_id FROM sys.databases WHERE name = ''' + @DBname + ''')'
PRINT @sql
exec (@sql)
FETCH next FROM DBS INTO @DBname
END
CLOSE DBS
DEALLOCATE DBS"

    Invoke-Sqlcmd -Query "$queryForDatabaseLayout" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "SQL VERSION" >> $Output_File
    $queryForSqlVersion = "SELECT @@VERSION"
    Invoke-Sqlcmd -Query "$queryForSqlVersion" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "Listing all SQL instances running on this host" >> $Output_File
    Write-Output "" >> $Output_File
    OSQL -L >> $Output_File
    Write-Output "If Servers: None came that means Default instance is been used" >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "RECOVERY MODE USED FOR DIFFERENT DATABASES IN $instance_name" >> $Output_File
    $queryForRecoveryMode = "SELECT name , recovery_model_desc FROM sys.databases"
    Invoke-Sqlcmd -Query "$queryForRecoveryMode" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "AUTHENTICATION MODE" >> $Output_File
    $queryForAuthenticationMode = "SELECT CASE SERVERPROPERTY('IsIntegratedSecurityOnly') WHEN 1 THEN 'Windows Authentication' WHEN 0 THEN 'Windows and SQL Server Authentication' END as [Authentication Mode]"
    Invoke-Sqlcmd -Query "$queryForAuthenticationMode" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "ISCSI INFORMATION" >> $Output_File
    iscsicli.exe sessionlist >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "WINRM STATUS" >> $Output_File
    Write-Output "" >> $Output_File
    Winrm get winrm/config >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "FIREWALL STATUS" >> $Output_File
    netsh advfirewall show allprofile >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "AAG Enabled or Not" >> $Output_File
    $queryAagEnabledOrNot = "SELECT CAST( SERVERPROPERTY ('IsHadrEnabled') AS VARCHAR(5));"
    Invoke-Sqlcmd -Query "$queryAagEnabledOrNot" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "1 Means AAG Enabled " >> $Output_File
    Write-Output "0 Means AAG Disabled " >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File


    Write-Output "Name of the availability_group" >> $Output_File
    Write-Output "Note For sql version less than 2012 master.sys.availability_groups won't work" >> $Output_File
    $queryAagName = "
If (@@VERSION like 'Microsoft SQL Server 2012%') OR (@@VERSION like 'Microsoft SQL Server 2008%')
	Select @@version
Else
    BEGIN
    select name FROM master.sys.availability_groups;
    END
"
    Invoke-Sqlcmd -Query "$queryAagName" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File
    Write-Output "Replica is primary or not showing for all databases in $instance_name" >> $Output_File
    Write-Output "Note For Sql Version less then 2014 sys.fn_hadr_is_primary_replica won't work" >> $Output_File
    $queryPrimaryReplicaOrNot = "
If (@@VERSION like 'Microsoft SQL Server 2012%') OR (@@VERSION like 'Microsoft SQL Server 2008%')
	Select @@version
Else
    BEGIN
    DECLARE @sql VARCHAR (max)
    DECLARE @DBname VARCHAR (50)
    DECLARE DBS CURSOR FOR
    SELECT name
    FROM   sys.databases
    WHERE  name NOT IN ( 'model', 'tempdb', 'master',
    'reportserver', 'ReportServerDB', 'msdb', 'ReportServerTempDB')
    OPEN DBS
    FETCH next FROM DBS INTO @DBname
    WHILE @@FETCH_STATUS = 0
    BEGIN
    select @DBname
    SET @sql = 'SELECT sys.fn_hadr_is_primary_replica (''' + @DBname + ''' );'
    PRINT @sql
    exec (@sql)
    FETCH next FROM DBS INTO @DBname
    END
    CLOSE DBS
    DEALLOCATE DBS
    END
"
    Invoke-Sqlcmd -Query "$queryPrimaryReplicaOrNot" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "BACKUP DETAILS FOR THE DATABASES for instance with name $instance_name is following" >> $Output_File
    $queryForDatabaseBackupDetails = "
DECLARE @sql VARCHAR (max)
DECLARE @DBname VARCHAR (50)
DECLARE DBS CURSOR FOR
SELECT name
FROM   sys.databases
OPEN DBS
FETCH next FROM DBS INTO @DBname
WHILE @@FETCH_STATUS = 0
BEGIN
SET @sql = 'use msdb select TOP 10 database_name, backup_start_date,backup_finish_date,type,is_snapshot,is_copy_only,first_lsn,last_lsn,checkpoint_lsn,database_backup_lsn from backupset where database_name = ''' + @DBname + ''' ORDER BY backup_finish_date DESC'

PRINT @sql
exec (@sql)
FETCH next FROM DBS INTO @DBname
END
CLOSE DBS
DEALLOCATE DBS"

    Invoke-Sqlcmd -Query "$queryForDatabaseBackupDetails" -ServerInstance $connectionInstanceString >> $Output_File
    Write-Output "*******************************" >> $Output_File
    Write-Output "" >> $Output_File

    Write-Output "Completed capturing information on $(Get-Date) for instance $instance_name" >> $Output_File

    Write-Output "Done."
    Write-Output "" >> $Output_File
    Write-Output "See $Output_File for details captured"
    cd $current_dir
}
Catch {
    Write-Output ""
    Write-Output $_.Exception.Message
    Write-Output ""
    Write-Output "Usage:"
    Write-Output "powershell.exe questionaire_sql_server.ps1 instance_name"
    Write-Output ""
}

