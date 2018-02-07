# IIS ARR Blue Green Deploy
How to implement Blue Green Deploy using the IIS ARR module and a bunch of PowerShell scripts for Octopus Deploy.

This repository contains some PowerShell scripts that can help in dealing with an IIS server farm.

[IIS Server Farm](https://docs.microsoft.com/en-us/iis/extensions/configuring-application-request-routing-arr/define-and-configure-an-application-request-routing-server-farm)

[Rolling Deployment With Octopus](https://octopus.com/docs/deployment-patterns/rolling-deployments)

## General Info

To connect to the IIS it uses the **Microsoft.Web.Administration** objects.
This allows to browse through all the IIS features installed into the target instance.

Because these scripts runs by the **Octopus Tentacle** installed in the deployment environment, they are running remote instructions.
The Tentacle runs the script targetting the IIS Server Farm that in installed in a remote machine.

This is the reason for the Invoke-Command

```
$Session = New-PSSession -ComputerName $remoteMachine
Invoke-Command -Session $Session -ScriptBlock $scriptToExecute -ArgumentList $param1,$param2
```

## Disable Farm Node (disableFarmNode.ps1)

Remove a single instance from the web farm. 
In the load balancer, sets the node as not available for new connections and drain all the existing connections.

## Warm-up instance (warmup.ps1)

Example of a request to an hypothetical URL that is the endpoint of the newly deployed instance.

## Enalbe Farm Node (enableFarmNode.ps1)

Put back online the Server Farm the previously removed node.