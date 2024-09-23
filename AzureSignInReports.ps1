Install-module -Name AzureADpreview
Connect-AzureAD

# Fetches the last month's Azure Active Directory sign-in data
CLS; $StartDate = (Get-Date).AddDays(-30); $StartDate = Get-Date($StartDate) -format yyyy-MM-dd  
Write-Host "Fetching data from Azure Active Directory..."
$Records = Get-AzureADAuditSignInLogs -Filter "createdDateTime gt $StartDate" -all:$True  
$Report = [System.Collections.Generic.List[Object]]::new() 
ForEach ($Rec in $Records) {
    Switch ($Rec.Status.ErrorCode) {
      "0" {$Status = "Success"}
      default {$Status = $Rec.Status.FailureReason}
    }
    $ReportLine = [PSCustomObject] @{
           TimeStamp   = Get-Date($Rec.CreatedDateTime) -format g
           User        = $Rec.UserPrincipalName
           Name        = $Rec.UserDisplayName
           IPAddress   = $Rec.IpAddress
           ClientApp   = $Rec.ClientAppUsed
           Device      = $Rec.DeviceDetail.OperatingSystem
           Location    = $Rec.Location.City + ", " + $Rec.Location.State + ", " + $Rec.Location.CountryOrRegion
           Appname     = $Rec.AppDisplayName
           Resource    = $Rec.ResourceDisplayName
           Status      = $Status
           Correlation = $Rec.CorrelationId
           Interactive = $Rec.IsInteractive }
      $Report.Add($ReportLine) } 
Write-Host $Report.Count "sign-in audit records processed."

#Report of the applications logged in from
$Report | Group AppName | Sort Count -Descending | Format-Table Count, Name

#Report of the locations logged in from
$Report | Group Location | Sort Count -Descending | Format-Table Count, Name 

#Report to find the User that logged in from outside the US
$Report | ?{$_.Location -NotLike "*US*"} | Group User | Sort Count -Descending | Ft Count, Name
