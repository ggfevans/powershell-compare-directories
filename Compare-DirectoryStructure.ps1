<#
.SYNOPSIS
    Compares two directory structures to identify file differences.
.DESCRIPTION
    This script compares files between two directories and identifies missing files,
    size differences, timestamp differences, and optionally content differences.
.PARAMETER folderA
    Source directory path to compare.
.PARAMETER folderB
    Target directory path to compare against folderA.
.PARAMETER outputFile
    Path to save CSV results.
.PARAMETER showProgress
    Display a progress bar during comparison.
.PARAMETER checkContent
    Compare file contents using MD5 hashes.
.PARAMETER includeMissingFromA
    Find files in folderB that are missing from folderA.
.PARAMETER Version
    Display script version and exit.
.EXAMPLE
    .\Compare-DirectoryStructure.ps1 -folderA "C:\SourceFiles" -folderB "D:\BackupFiles"
.EXAMPLE
    .\Compare-DirectoryStructure.ps1 -folderA "C:\SourceFiles" -folderB "D:\BackupFiles" -checkContent -outputFile "results.csv"
.NOTES
    Author: Gareth Evans
    Version: 1.0.0
    Last Updated: 2025-04-11
#>

[string]$ScriptVersion = "1.0.0"

param (
    [Parameter(Mandatory = $true)]
    [string]$folderA = "X:\Path\To\Root\A",
    
    [Parameter(Mandatory = $true)]
    [string]$folderB = "X:\Path\To\Root\B",
    
    [Parameter(Mandatory = $false)]
    [string]$outputFile,
    
    [Parameter(Mandatory = $false)]
    [switch]$showProgress,
    
    [Parameter(Mandatory = $false)]
    [switch]$checkContent,
    
    [Parameter(Mandatory = $false)]
    [switch]$includeMissingFromA,
    
    [Parameter(Mandatory = $false)]
    [switch]$Version
)

if ($Version) {
    Write-Host "Compare-DirectoryStructure.ps1 v$ScriptVersion"
    exit 0
}

# Verify paths exist
if (-not (Test-Path -Path $folderA)) {
    Write-Error "Source folder '$folderA' does not exist!"
    exit 1
}

if (-not (Test-Path -Path $folderB)) {
    Write-Error "Target folder '$folderB' does not exist!"
    exit 1
}

# Normalize paths with trailing backslash
$folderA = $folderA.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$folderB = $folderB.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar

Write-Host "Collecting files from $folderA..." -ForegroundColor Cyan
$filesA = Get-ChildItem -Path $folderA -Recurse -File

Write-Host "Collecting files from $folderB..." -ForegroundColor Cyan
$filesB = Get-ChildItem -Path $folderB -Recurse -File

# Create a hashtable for faster lookups of B files
$filesB_Hash = @{}
foreach ($file in $filesB) {
    $relativePath = $file.FullName.Substring($folderB.Length)
    $filesB_Hash[$relativePath] = $file
}

$totalFiles = $filesA.Count
$processedFiles = 0
$differences = [System.Collections.ArrayList]::new()

Write-Host "Comparing files..." -ForegroundColor Cyan

foreach ($fileA in $filesA) {
    if ($showProgress) {
        $processedFiles++
        $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100, 1)
        Write-Progress -Activity "Comparing Files" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
    }

    $relativePath = $fileA.FullName.Substring($folderA.Length)
    
    if ($filesB_Hash.ContainsKey($relativePath)) {
        $fileB = $filesB_Hash[$relativePath]
        $isDifferent = $false
        $difference = "None"
        
        # Check file size
        if ($fileA.Length -ne $fileB.Length) {
            $isDifferent = $true
            $difference = "Size"
        }
        # Check last write time
        elseif ($fileA.LastWriteTime -ne $fileB.LastWriteTime) {
            $isDifferent = $true
            $difference = "Date"
        }
        # Optional content comparison
        elseif ($checkContent) {
            try {
                $hashA = Get-FileHash -Path $fileA.FullName -Algorithm MD5
                $hashB = Get-FileHash -Path $fileB.FullName -Algorithm MD5
                
                if ($hashA.Hash -ne $hashB.Hash) {
                    $isDifferent = $true
                    $difference = "Content"
                }
            }
            catch {
                Write-Warning "Failed to compute hash for '$($relativePath)': $_"
                $isDifferent = $true
                $difference = "Hash Error"
            }
        }
        
        if ($isDifferent) {
            $null = $differences.Add([PSCustomObject]@{
                File = $relativePath
                FolderA_Size = $fileA.Length
                FolderB_Size = $fileB.Length
                FolderA_LastWrite = $fileA.LastWriteTime
                FolderB_LastWrite = $fileB.LastWriteTime
                Difference = $difference
                Status = "Different"
            })
        }
    }
    else {
        $null = $differences.Add([PSCustomObject]@{
            File = $relativePath
            FolderA_Size = $fileA.Length
            FolderB_Size = "Missing"
            FolderA_LastWrite = $fileA.LastWriteTime
            FolderB_LastWrite = $null
            Difference = "Missing"
            Status = "Missing in Folder B"
        })
    }
}

# Find files that exist in B but not in A
if ($includeMissingFromA) {
    Write-Host "Finding files missing from $folderA..." -ForegroundColor Cyan
    
    $filesA_Hash = @{}
    foreach ($file in $filesA) {
        $relativePath = $file.FullName.Substring($folderA.Length)
        $filesA_Hash[$relativePath] = $file
    }
    
    foreach ($relativePath in $filesB_Hash.Keys) {
        if (-not $filesA_Hash.ContainsKey($relativePath)) {
            $fileB = $filesB_Hash[$relativePath]
            $null = $differences.Add([PSCustomObject]@{
                File = $relativePath
                FolderA_Size = "Missing"
                FolderB_Size = $fileB.Length
                FolderA_LastWrite = $null
                FolderB_LastWrite = $fileB.LastWriteTime
                Difference = "Missing"
                Status = "Missing in Folder A"
            })
        }
    }
}

# Output results
if ($differences.Count -eq 0) {
    Write-Host "No differences found." -ForegroundColor Green
}
else {
    Write-Host "Found $($differences.Count) differences." -ForegroundColor Yellow
    
    $sortedDifferences = $differences | Sort-Object -Property Status, File
    
    if ($outputFile) {
        $sortedDifferences | Export-Csv -Path $outputFile -NoTypeInformation
        Write-Host "Results exported to '$outputFile'" -ForegroundColor Green
    }
    else {
        $sortedDifferences | Format-Table -AutoSize
    }
    
    # Summary of differences
    $missingInB = ($sortedDifferences | Where-Object { $_.Status -eq "Missing in Folder B" }).Count
    $missingInA = ($sortedDifferences | Where-Object { $_.Status -eq "Missing in Folder A" }).Count
    $differentFiles = ($sortedDifferences | Where-Object { $_.Status -eq "Different" }).Count
    
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "- Missing in Folder B: $missingInB" -ForegroundColor Yellow
    if ($includeMissingFromA) {
        Write-Host "- Missing in Folder A: $missingInA" -ForegroundColor Yellow
    }
    Write-Host "- Different Files: $differentFiles" -ForegroundColor Yellow
}