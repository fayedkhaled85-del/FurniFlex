param([string]$Database='furniflex_db')
$ErrorActionPreference='Stop'
if(Test-Path .env){throw 'Existing .env preserved.'}
if($Database -notmatch '^[a-zA-Z0-9_]+$'){throw 'Invalid database name'}
function New-Secret { $bytes=New-Object byte[] 32; $rng=[Security.Cryptography.RandomNumberGenerator]::Create(); try {$rng.GetBytes($bytes)} finally {$rng.Dispose()}; return [BitConverter]::ToString($bytes).Replace('-','') }
$example=Get-Content -LiteralPath .env.example -Raw
$text=$example.Replace('DB_NAME=furniflex_db',"DB_NAME=$Database").Replace('DB_PASSWORD=',('DB_PASSWORD='+(New-Secret))).Replace('DB_ROOT_PASSWORD=',('DB_ROOT_PASSWORD='+(New-Secret)))
[IO.File]::WriteAllText((Join-Path (Get-Location) '.env'),$text)
