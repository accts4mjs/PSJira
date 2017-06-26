. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    Describe 'Get-JiraIssueLinkType' {

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraIssueLinkType

            defParam $command 'LinkType'
            defParam $command 'Credential'
        }

        $filterAll = {$Method -eq 'Get' -and $Uri -ceq "/rest/api/latest/issueLinkType"}
        $filterOne = {$Method -eq 'Get' -and $Uri -ceq "/rest/api/latest/issueLinkType/10000"}

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ParameterFilter $filterAll {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            [PSCustomObject] @{
                issueLinkTypes = @(
                    # We don't care what data actually comes back here
                    'foo'
                )
            }
        }

        Mock Invoke-JiraMethod -ParameterFilter $filterOne {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            [PSCustomObject] @{
                issueLinkTypes = @(
                    'bar'
                )
            }
        }

        Context "Behavior testing - returning all link types" {

            Mock ConvertTo-JiraIssueLinkType {
                ShowMockInfo 'ConvertTo-JiraIssueLinkType'

                # We also don't care what comes out of here - this function has its own tests
                [PSCustomObject] @{
                    PSTypeName = 'JiraPS.IssueLinkType'
                    foo        = 'bar'
                }
            }

            $output = Get-JiraIssueLinkType

            It 'Uses Invoke-JiraMethod to communicate with JIRA' {
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter $filterAll -Exactly -Times 1 -Scope Context
            }


            It 'Returns all link types if no value is passed to the -LinkType parameter' {
                $output | Should Not BeNullOrEmpty
            }

            It 'Uses the helper method ConvertTo-JiraIssueLinkType to process output' {
                # Watch the order of this test - the test below with the -ServerName
                # param will call the mock a second time
                Assert-MockCalled -CommandName ConvertTo-JiraIssueLinkType -ParameterFilter {$InputObject -contains 'foo'} -Exactly -Times 1 -Scope Context
            }

            It "Passes the -ServerName parameter to Invoke-JiraMethod if specified" {
                Get-JiraIssueLinkType -ServerName 'testServer' | Out-Null
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter {$ServerName -eq 'testServer'}
            }
        }

        Context "Behavior testing - returning one link type" {
            Mock ConvertTo-JiraIssueLinkType {
                ShowMockInfo 'ConvertTo-JiraIssueLinkType'

                # We also don't care what comes out of here - this function has its own tests
                [PSCustomObject] @{
                    PSTypeName = 'JiraPS.IssueLinkType'
                    Name       = 'myLink'
                    ID         = 5
                }
            }

            It 'Returns a single link type if an ID number is passed to the -LinkType parameter' {
                $output = Get-JiraIssueLinkType -LinkType 10000
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter $filterOne -Exactly -Times 1 -Scope It
                $output | Should Not BeNullOrEmpty
                @($output).Count | Should Be 1
            }

            It 'Returns the correct link type it a type name is passed to the -LinkType parameter' {
                $output = Get-JiraIssueLinkType -LinkType 'myLink'
                Assert-MockCalled -CommandName Invoke-JiraMethod -ParameterFilter $filterAll -Exactly -Times 1 -Scope It
                $output | Should Not BeNullOrEmpty
                @($output).Count | Should Be 1
                $output.ID | Should Be 5
            }
        }
    }
}
