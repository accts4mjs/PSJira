. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $testGroupName = 'testGroup'

    $testJson = @"
{
  "name": "$testGroupName",
  "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
  "users": {
    "size": 0,
    "items": [],
    "max-results": 50,
    "start-index": 0,
    "end-index": 0
  },
  "expand": "users"
}
"@

    Describe "New-JiraGroup" {

        if ($ShowDebugText) {
            Mock Write-Debug {
                Write-Host "DEBUG: $Message" -ForegroundColor Yellow
            }
        }

        Mock Invoke-JiraMethod -ParameterFilter {$Method -eq 'POST' -and $URI -eq "/rest/api/latest/group"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            ConvertFrom-Json2 $testJson
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'URI', 'ServerName'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock ConvertTo-JiraGroup { $InputObject }

        #############
        # Tests
        #############

        It "Creates a group in JIRA and returns a result" {
            $newResult = New-JiraGroup -GroupName $testGroupName
            $newResult | Should Not BeNullOrEmpty
        }

        It "Uses ConvertTo-JiraGroup to beautify output" {
            Assert-MockCalled 'ConvertTo-JiraGroup'
        }

        It "Passes the -ServerName parameter to Invoke-JiraMethod if specified" {
            New-JiraGroup -GroupName $testGroupName -ServerName 'testServer' | Out-Null
            Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
        }
    }
}


