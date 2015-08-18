<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Start-MultiThred
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'https://github.com/mrhvid/Start-MultiThred/',
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
        $Computers,

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
            Foreach($Computer in $Computers) {
                # Wait for running jobs to finnish if MaxThreads is reached
                While((Get-Job -State Running).count -gt $MaxThreads) {
                    Write-Progress -Id 1 -Activity 'Waiting for existing jobs to complete' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $Computers.Count * 100)
                    Start-Sleep -Milliseconds $SleepTime 
                }

                # Start new jobs 
                $i++
                $Jobs += Start-Job -ScriptBlock $Script -ArgumentList $Computer -Name $Computer -OutVariable LastJob
                Write-Progress -Id 1 -Activity 'Starting jobs' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $Computers.Count * 100)

            }

            # All jobs have now been started


            # Wait for jobs to finish
            While((Get-Job -State Running).count -gt 0) {
            
                $JobsStillRunning = ''
                foreach($RunningJob in (Get-Job -State Running)) {
                    $JobsStillRunning += $RunningJob.Name
                }

                Write-Progress -Id 1 -Activity 'Waiting for jobs to finish' -Status "$JobsStillRunning"  -PercentComplete (($Computers.Count - (Get-Job -State Running).Count) / $Computers.Count * 100)
                Start-Sleep -Milliseconds $SleepTime
            }

            # Output
            Get-job | Receive-Job 

            # Cleanup 
            Get-job | Remove-Job
        }
    }
    End
    {
    }
}