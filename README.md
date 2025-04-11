# powershell-compare-directories

![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A simple PowerShell script for comparing two directory structures to identify file differences.

## Compare-DirectoryStructure.ps1

This script helps identify:
- Missing files between directories
- Files with different sizes or timestamps
- Optional content comparison with MD5 hashes

## Requirements

- PowerShell 5.1 or higher
- Works on Windows, macOS (with PowerShell Core), and Linux (with PowerShell Core)
- No additional modules required
- Standard user permissions (admin privileges not required unless comparing protected directories)
- Sufficient memory for large directory comparisons (memory usage scales with the number of files)

The script is designed to be cross-platform compatible with minimal dependencies, making it easy to use in various environments.

## Usage

```powershell
.\Compare-DirectoryStructure.ps1 -folderA "C:\SourceFiles" -folderB "D:\BackupFiles"

# With additional options
.\Compare-DirectoryStructure.ps1 -folderA "C:\SourceFiles" -folderB "D:\BackupFiles" -showProgress -checkContent -outputFile "results.csv"
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `folderA` | String | Yes | Source directory |
| `folderB` | String | Yes | Target directory |
| `outputFile` | String | No | Save results as CSV |
| `showProgress` | Switch | No | Display progress bar |
| `checkContent` | Switch | No | Compare file contents with MD5 |
| `includeMissingFromA` | Switch | No | Find files in B missing from A |

## Installation

### Direct Download

1. Download `Compare-DirectoryStructure.ps1` from this repository
2. Save it to your preferred scripts directory
3. Run it directly using PowerShell

That's it! No complex setup required.

Example:
```powershell
# Navigate to where you saved the script
cd C:\Path\To\Scripts

# Run the script with parameters
.\Compare-DirectoryStructure.ps1 -folderA "C:\SourceFiles" -folderB "D:\BackupFiles"
```

## Sample Output

```
Found 3 differences.

File                FolderA_Size FolderB_Size Difference Status
----                ------------ ------------ ---------- ------
config.json         1245         978          Size       Different
data.csv            45678        Missing      Missing    Missing in Folder B
backup.ps1          Missing      2341         Missing    Missing in Folder A

Summary:
- Missing in Folder B: 1
- Missing in Folder A: 1
- Different Files: 1
```
