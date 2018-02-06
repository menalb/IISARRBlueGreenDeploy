$enableRemoteNode = { 
    Param([parameter(Mandatory=$true)] [string] $machineToRestore,[parameter(Mandatory=$true)] [string]  $farmName)

    function SetHealty
    {
        Param
        (
            [parameter(Mandatory=$true)]
            $applicationRequestRouting
        )

        $counters = $applicationRequestRouting.GetChildElement("counters")
        $counters.GetAttributeValue("isHealthy")
        $counters.GetAttributeValue("state")
        $method = $arr.Methods["SetUnhealthy"]
        
        $methodInstance = $method.CreateInstance()
        $methodInstance.Execute()
    }

    function SetAvailable
    {
        Param
        (
            [parameter(Mandatory=$true)]
            $applicationRequestRouting
        )
        
        # available
        $method = $applicationRequestRouting.Methods["SetState"]
        $methodInstance = $method.CreateInstance()
        $methodInstance.Input.Attributes[0].Value = 0
        $methodInstance.Execute()
    }

    function StartNode
    {
        Param
        (
            [parameter(Mandatory=$true)]
            [string]
            $machineToRestore,            
            [parameter(Mandatory=$true)]
            [string]
            $farmName
        )        
        
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
        $mgr = new-object Microsoft.Web.Administration.ServerManager
        $conf = $mgr.GetApplicationHostConfiguration()
        $section = $conf.GetSection("webFarms")
        $webFarms = $section.GetCollection()
        
        $webFarm = $webFarms | Where-Object {$_.GetAttributeValue("name") -eq $farmName} | Select-Object -First 1

        $servers = $webFarm.GetCollection()
        
        $localMachine = $machineToRestore
        
        $server = $servers | Where-Object { $_["address"] -eq $localMachine}
        
        Write-Host 'restoring machine' $server["address"]
        
        $arr = $server.GetChildElement("applicationRequestRouting")

        SetHealty $arr

        SetAvailable $arr
    }

    Write-Host 'Restoring server farm: ' $machineToRestore 
    StartNode $machineToRestore $farmName
	
} 

$machineToRestore = $env:COMPUTERNAME

$Session = New-PSSession -ComputerName $balancerMachine

Invoke-Command -Session $Session -ScriptBlock $enableRemoteNode -ArgumentList $machineToRestore, $farmName

# Attribute values SetState
# 0 -> Available
# 1 -> Drain
# 2 -> Unavailable
# 3 -> Unavailable