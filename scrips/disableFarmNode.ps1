$disableRemoteNode = {
    Param([parameter(Mandatory=$true)] [string] $machineToRemove,[parameter(Mandatory=$true)] [string]  $farmName)

    function SetUnhealty
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

    
    function Drain
    {
        Param
        (
            [parameter(Mandatory=$true)]
            $applicationRequestRouting
        )
		
		$counters = $applicationRequestRouting.GetChildElement("counters")
        $method = $applicationRequestRouting.Methods["SetState"]
        $methodInstance = $method.CreateInstance()
        $methodInstance.Input.Attributes[0].Value = 1
        $methodInstance.Execute()
        
        $i = 0
        
        while (($counters.GetAttributeValue("currentRequests") -ne 0) -and ($i -ne 10)) {
            Start-Sleep -s 1
            $i = $i + 1
        }
    }    
    
    
    function SetUnavailable
    {
        Param
        (
            [parameter(Mandatory=$true)]
            $applicationRequestRouting
        )
        
        # gracefully unavailable
        $method = $applicationRequestRouting.Methods["SetState"]
        $methodInstance = $method.CreateInstance()
        $methodInstance.Input.Attributes[0].Value = 3
        $methodInstance.Execute()
    }

    function StopNode
    {
        Param
        (
            [parameter(Mandatory=$true)]
            $machineToRemove,
            [string]
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
        
        $localMachine = $machineToRemove
        
        $server = $servers | Where-Object { $_["address"] -eq $localMachine}
        
        Write-Host 'removing machine' $server["address"]
        
        $arr = $server.GetChildElement("applicationRequestRouting")

        SetUnhealty $arr

        Drain $arr

        SetUnavailable $arr
    }

    
    Write-Host 'Removing server from farm: ' $machineToRemove
    StopNode -machineToRemove $machineToRemove -farmName $farmName
} 

$machineToRemove = $env:COMPUTERNAME

$Session = New-PSSession -ComputerName $balancerMachine

Invoke-Command -Session $Session -ScriptBlock $disableRemoteNode -ArgumentList $machineToRemove,$farmName

# Attribute values SetState
# 0 -> Available
# 1 -> Drain
# 2 -> Unavailable
# 3 -> Unavailable (Gracefully)