param(
  [Parameter(Mandatory = $true)]
  [string]$Test
)

flutter test $Test --dart-define=API_BASE_URL=http://192.168.100.181:5002/api/ -d windows
