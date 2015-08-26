<#
.Synopsis
   Module for Multi Treading using jobs
.DESCRIPTION
   Module for multi threading using jobs 
.EXAMPLE
PS C:\> Start-MultiThred -Script { param($ComputerName) Test-Connection $ComputerName -Count 1} -Computers ::1,localhost,::1

Source        Destination     IPV4Address      IPV6Address                              Bytes    Time(ms) 
------        -----------     -----------      -----------                              -----    -------- 
HVID-X230     ::1             10.165.169.86    fe80::8050:8aa2:3b6d:44af%16             32       0        
HVID-X230     localhost       127.0.0.1        ::1                                      32       0        
HVID-X230     ::1             10.165.169.86    fe80::8050:8aa2:3b6d:44af%16             32       0        

.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   This module was created with a powershell.org blogpost in mind
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Start-Multithread
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'https://github.com/mrhvid/Start-MultiThread/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Command or script to run. Must take ComputerName as argument to make sense. 
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)]
        $Script,

        # List of computers to run script against
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=1)]
        [String[]]
        $ComputerName,

        # Maximum concurrent threads to start
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=2)]
        [int]
        $MaxThreads = 20 ,

        # Number of sec to wait after last thred is started. 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)]
        [int]
        $MaxWaitTime = 600,

        # Number of Milliseconds to wait if MaxThreads is reached
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=4)]
        $SleepTime = 500

    )

    Begin
    {
    }
    Process
    {
        if ($pscmdlet.ShouldProcess('Target', 'Operation'))
        {
            
            $i = 0
            $Jobs = @()
            Foreach($Computer in $ComputerName) {
                Write-Verbose "Processing $Computer"
                # Wait for running jobs to finnish if MaxThreads is reached
                While((Get-Job -State Running).count -ge $MaxThreads) {
                    Write-Progress -Id 1 -Activity 'Waiting for existing jobs to complete' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $ComputerName.Count * 100)
                    Write-Verbose 'Waiting for jobs to finish before starting new ones'
                    Start-Sleep -Milliseconds $SleepTime 
                }

                # Start new jobs 
                $i++
                $Jobs += Start-Job -ScriptBlock $Script -ArgumentList $Computer -Name $Computer -OutVariable LastJob
                Write-Progress -Id 1 -Activity 'Starting jobs' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $ComputerName.Count * 100)
                Write-Verbose "Job with id: $($LastJob.Id) just started."
            }

            # All jobs have now been started
            Write-Verbose "All jobs have been started $(Get-Date)"
            
            # Wait for jobs to finish
            While((Get-Job -State Running).count -gt 0) {
            
                $JobsStillRunning = ''
                foreach($RunningJob in (Get-Job -State Running)) {
                    $JobsStillRunning += "$($RunningJob.Name) "
                }

                Write-Progress -Id 1 -Activity 'Waiting for jobs to finish' -Status "$JobsStillRunning"  -PercentComplete (($ComputerName.Count - (Get-Job -State Running).Count) / $ComputerName.Count * 100)
                Write-Verbose "Waiting for following $((Get-Job -State Running).count) jobs to stop $JobsStillRunning"
                Start-Sleep -Milliseconds $SleepTime
            }

            # Output
            Write-Verbose 'Recieving jobs'
            Get-job | Receive-Job 

            # Cleanup 
            Get-job | Remove-Job
        }
    }
    End
    {
    }
}
