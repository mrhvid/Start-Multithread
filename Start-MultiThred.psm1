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

        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=3)]
        # Number of sec to wait after last thred is started. 
        [int]
        $MaxWaitTime = 600,

        # Number of Milliseconds to wait if MaxThreads is reached
        $SleepTime = 500


    )

    Begin
    {
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("Target", "Operation"))
        {
            
            $i = 0
            $jobs = @()

            Foreach($Computer in $Computers) {
                # Wait for running jobs to finnish if MaxThreads is reached
                While((Get-Job -State Running).count -gt $MaxThreads) {
                    Write-Progress -Activity "Computers" -Status "Waiting for existing threads to complete"
                    Start-Sleep -Milliseconds $SleepTime 
                }

                # Start new jobs 
                $i++
                $jobs + = Start-Job -ScriptBlock $Script -Name $Computer -OutVariable LastJob
                Write-Progress -Activity "Computers" -Status "Starting Threads"

            }


         





        }
    }
    End
    {
    }
}