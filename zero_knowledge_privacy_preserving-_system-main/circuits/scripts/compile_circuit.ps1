# ==============================================================================
# Circuit Compilation & Setup Script for Windows PowerShell
# ==============================================================================

$ErrorActionPreference = "Stop"

$CircuitName = "age_verifier"
$BuildDir = Join-Path $PSScriptRoot "..\build"
$MoproAssetsDir = Join-Path $PSScriptRoot "..\..\mopro\assets"
$PtauUrl = "https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_12.ptau"
$PtauFile = Join-Path $BuildDir "powersOfTau28_hez_final_12.ptau"

Write-Host "=== [1/6] Creating build directories ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $MoproAssetsDir | Out-Null

Write-Host "=== [2/6] Compiling Circom Circuit ===" -ForegroundColor Cyan
$CircuitSrc = Join-Path $PSScriptRoot "..\src\$CircuitName.circom"
circom $CircuitSrc --r1cs --wasm --sym -o $BuildDir

Write-Host "=== [3/6] Acquiring BN254 Powers of Tau ceremony file ===" -ForegroundColor Cyan
if (-not (Test-Path $PtauFile)) {
    Write-Host "Downloading Powers of Tau file..."
    Invoke-WebRequest -Uri $PtauUrl -OutFile $PtauFile
} else {
    Write-Host "Using existing PTAU file: $PtauFile"
}

Write-Host "=== [4/6] Generating Initial Groth16 zkey ===" -ForegroundColor Cyan
$R1csFile = Join-Path $BuildDir "$CircuitName.r1cs"
$InitZkey = Join-Path $BuildDir "${CircuitName}_0000.zkey"
npx snarkjs groth16 setup $R1csFile $PtauFile $InitZkey

Write-Host "=== [5/6] Contributing Entropy for Phase 2 ===" -ForegroundColor Cyan
$FinalZkey = Join-Path $BuildDir "${CircuitName}_final.zkey"
"zk-MatchID Phase 2 random beacon" | npx snarkjs zkey contribute $InitZkey $FinalZkey --name="zk-MatchID Contributor" -v

Write-Host "=== [6/6] Exporting Verification Key JSON ===" -ForegroundColor Cyan
$VKey = Join-Path $BuildDir "verification_key.json"
npx snarkjs zkey export verification_key $FinalZkey $VKey

Write-Host "=== Copying assets to Mopro engine assets directory ===" -ForegroundColor Cyan
Copy-Item $R1csFile -Destination $MoproAssetsDir -Force
Copy-Item $FinalZkey -Destination $MoproAssetsDir -Force
Copy-Item $VKey -Destination $MoproAssetsDir -Force

Write-Host ">>> Circuit compilation and Groth16 ceremony setup completed successfully!" -ForegroundColor Green
