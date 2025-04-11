# powershell-compare-directories

A simple PowerShell script for comparing two directory structures to identify file differences.

## Compare-DirectoryStructure.ps1

This script helps identify:
- Missing files between directories
- Files with different sizes or timestamps
- Optional content comparison with MD5 hashes

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
