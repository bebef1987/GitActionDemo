<#
.SYNOPSIS
This is a script to interact with UiPath's Orchestrator API

.DESCRIPTION
The script retrieves an access token using client credentials, makes a GET request to the TestSets API with a provided filter, and for each test set, retrieves the corresponding folder details.

.PARAMETER client_id
The client ID. This is necessary for the initial POST request to retrieve the access token.

.PARAMETER client_secret
The client secret. This is necessary for the initial POST request to retrieve the access token.

.PARAMETER scope
The scope. This is necessary for the initial POST request to retrieve the access token.

.PARAMETER org
The organization identifier. This is used in the URIs of the GET requests.

.PARAMETER tenant
The tenant identifier. This is used in the URIs of the GET requests.

.PARAMETER filter
The filter to be applied on TestSet Names during the GET request to the TestSets API.
#>

# Declare parameters
param(
    [string]$client_id = $env:CLIENT_ID,
    [string]$client_secret = $env:CLIENT_SECRET,
    [string]$scope = $env:SCOPE,
    [string]$org = $env:ACCOUNTFORAPP,
    [string]$tenant = $env:OR_TENANT,
    [string]$filter = "RegTest"
)


$results = @()

echo $org
echo $tenant
echo $filter
echo $client_id
echo $client_secret
echo $scope


# Headers for the POST request to get the token
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

$body = @{
    "grant_type" = "client_credentials";
    "client_id" = $client_id;
    "client_secret" = $client_secret;
    "scope" = $scope
}

$token = Invoke-RestMethod -Method Post -Uri "https://cloud.uipath.com/identity_/connect/token" -Headers $headers -Body $body 
echo $token.access_token

$headers.Clear()
$headers.Add("accept", "application/json")
$headers.Add("authorization", "Bearer "+$token.access_token)

$response = Invoke-RestMethod -Method Get -Uri "https://cloud.uipath.com/$org/$tenant/orchestrator_/odata/TestSets?%24filter=startswith(Name%2C%20%27$filter%27)" -Headers $headers
	
foreach($item in $response.value) {
	$response = Invoke-RestMethod -Method Get -Uri "https://cloud.uipath.com/$org/$tenant/orchestrator_/odata/Folders($($item.OrganizationUnitId))" -Headers $headers
	
    echo "Name: $($item.Name)"
    echo "OrganizationUnitId: $($item.OrganizationUnitId)"
    echo "OrganizationUnitId Name: $($response.FullyQualifiedName)"
	
	$result = New-Object PSObject
    $result | Add-Member -Type NoteProperty -Name "Name" -Value $item.Name
    $result | Add-Member -Type NoteProperty -Name "OrganizationUnitId" -Value $item.OrganizationUnitId
    $result | Add-Member -Type NoteProperty -Name "OrganizationUnitName" -Value $response.FullyQualifiedName

    $results += $result
}

return $results | ConvertTo-Json