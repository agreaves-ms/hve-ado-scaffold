#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Install HVE ADO Scaffold files into an existing repository
.DESCRIPTION
    This script downloads and installs the Hyper-Velocity Engineering (HVE) Azure DevOps scaffold
    files from the agreaves-ms/hve-ado-scaffold repository into your current repository.

    The script will merge in all important configuration files, prompts, chatmodes, and instructions
    needed to supercharge GitHub Copilot + Azure DevOps workflows.
.PARAMETER SkipVSCodeSettings
    Skip copying VS Code settings files (.vscode/settings.json and .vscode/mcp.json)
.PARAMETER SkipDevContainer
    Skip copying the dev container configuration (.devcontainer/devcontainer.json)
.PARAMETER TargetPath
    Target directory to install files into (defaults to current directory)
.PARAMETER WhatIf
    Shows what would happen if the command runs. No files will be downloaded or overwritten.
.PARAMETER Confirm
    Prompts for confirmation before executing actions that change files.
.EXAMPLE
    .\Install-HveAdoScaffold.ps1
    Install all HVE ADO scaffold files to the current directory
.EXAMPLE
    .\Install-HveAdoScaffold.ps1 -SkipDevContainer
    Install files but skip the dev container configuration

#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$SkipVSCodeSettings,

    [Parameter()]
    [switch]$SkipDevContainer,

    [Parameter()]
    [string]$TargetPath = "."
)

# Configuration
$REPO_URL = "https://raw.githubusercontent.com/agreaves-ms/hve-ado-scaffold/main"

# Files to download and their target locations
$FILES_TO_COPY = @(
    # VS Code configuration
    @{ FilePath = ".vscode/settings.json"; Category = "VSCode" }
    @{ FilePath = ".vscode/mcp.json"; Category = "VSCode" }

    # Dev container
    @{ FilePath = ".devcontainer/devcontainer.json"; Category = "DevContainer" }

    # GitHub configuration
    @{ FilePath = ".github/copilot-instructions.md"; Category = "Core" }

    # Prompts
    @{ FilePath = ".github/prompts/ado-get-build-info.prompt.md"; Category = "Core" }
    @{ FilePath = ".github/prompts/ado-get-my-work-items.prompt.md"; Category = "Core" }
    @{ FilePath = ".github/prompts/ado-process-my-work-items-for-task-planning.prompt.md"; Category = "Core" }
    @{ FilePath = ".github/prompts/ado-update-wit-items.prompt.md"; Category = "Core" }
    @{ FilePath = ".github/prompts/git-commit.prompt.md"; Category = "Core" }
    @{ FilePath = ".github/prompts/git-commit-message.prompt.md"; Category = "Core" }
    @{ FilePath = ".github/prompts/git-setup.prompt.md"; Category = "Core" }

    # Chat modes
    @{ FilePath = ".github/chatmodes/adr-creation.chatmode.md"; Category = "Core" }
    @{ FilePath = ".github/chatmodes/ado-prd-to-wit.chatmode.md"; Category = "Core" }
    @{ FilePath = ".github/chatmodes/prd-builder.chatmode.md"; Category = "Core" }
    @{ FilePath = ".github/chatmodes/prompt-builder.chatmode.md"; Category = "Core" }
    @{ FilePath = ".github/chatmodes/task-planner.chatmode.md"; Category = "Core" }
    @{ FilePath = ".github/chatmodes/task-researcher.chatmode.md"; Category = "Core" }

    # Instructions
    @{ FilePath = ".github/instructions/ado-get-build-info.instructions.md"; Category = "Core" }
    @{ FilePath = ".github/instructions/ado-update-wit-items.instructions.md"; Category = "Core" }
    @{ FilePath = ".github/instructions/ado-wit-planning.instructions.md"; Category = "Core" }
    @{ FilePath = ".github/instructions/commit-message.instructions.md"; Category = "Core" }
    @{ FilePath = ".github/instructions/markdown.instructions.md"; Category = "Core" }
    @{ FilePath = ".github/instructions/task-implementation.instructions.md"; Category = "Core" }
    @{ FilePath = ".github/instructions/csharp/csharp.instructions.md"; Category = "Core" }
    @{ FilePath = ".github/instructions/csharp/csharp-tests.instructions.md"; Category = "Core" }

    # Documentation template
    @{ FilePath = "docs/solution-adr-library/adr-template-solutions.md"; Category = "Core" }
)

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    if ($Host.UI.SupportsVirtualTerminal) {
        $colorCodes = @{
            "Red"     = "`e[31m"
            "Green"   = "`e[32m"
            "Yellow"  = "`e[33m"
            "Blue"    = "`e[34m"
            "Magenta" = "`e[35m"
            "Cyan"    = "`e[36m"
            "White"   = "`e[37m"
            "Reset"   = "`e[0m"
        }
        Write-Host "$($colorCodes[$Color])$Message$($colorCodes['Reset'])"
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function New-DirectoryIfNotExists {
    param([string]$Path)

    $fullPath = Join-Path $TargetPath $Path
    $directory = Split-Path $fullPath -Parent

    if ($directory -and -not (Test-Path $directory)) {
        Write-ColoredOutput "📁 Creating directory: $directory" "Blue"
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
}

function Test-FileExists {
    param([string]$Path)

    $fullPath = Join-Path $TargetPath $Path
    return Test-Path $fullPath
}

function Copy-FileWithPrompt {
    param(
        [string]$SourceUrl,
        [string]$TargetFile
    )

    $fullTargetPath = Join-Path $TargetPath $TargetFile
    $shouldCopy = $true

    if ((Test-Path $fullTargetPath)) {
        do {
            $response = Read-Host "File '$TargetFile' already exists. Overwrite? (y/N)"
            $response = $response.ToLower()

            switch ($response) {
                'y' { $shouldCopy = $true; break }
                'yes' { $shouldCopy = $true; break }
                'n' { $shouldCopy = $false; break }
                'no' { $shouldCopy = $false; break }
                '' { $shouldCopy = $false; break }
                default { Write-ColoredOutput "Please enter 'y' or 'n'" "Yellow" }
            }
        } while ($response -notin @('y', 'yes', 'n', 'no', ''))
    }

    if ($shouldCopy) {
        try {
            New-DirectoryIfNotExists -Path $TargetFile

            Write-ColoredOutput "⬇️  Downloading: $TargetFile" "Cyan"
            Invoke-WebRequest -Uri $SourceUrl -OutFile $fullTargetPath -ErrorAction Stop

            Write-ColoredOutput "✅ Installed: $TargetFile" "Green"
            return $true
        }
        catch {
            Write-ColoredOutput "❌ Failed to download $TargetFile : $($_.Exception.Message)" "Red"
            return $false
        }
    }
    else {
        Write-ColoredOutput "⏭️  Skipped: $TargetFile" "Yellow"
        return $false
    }
}

function Resolve-FilePath {
    param([string]$Path)
    try {
        return (Resolve-Path -Path $Path -ErrorAction Stop).Path
    }
    catch {
        return (Join-Path (Get-Location) $Path)
    }
}

function Show-PreInstallSummary {
    Write-ColoredOutput "🚀 HVE ADO Scaffold Installer" "Magenta"
    Write-ColoredOutput "==============================" "Magenta"
    Write-Host ""
    Write-ColoredOutput "Target directory: $(Resolve-FilePath $TargetPath)" "Blue"
    Write-Host ""

    $filesToInstall = $FILES_TO_COPY

    if ($SkipVSCodeSettings) {
        $filesToInstall = $filesToInstall | Where-Object { $_.Category -ne "VSCode" }
        Write-ColoredOutput "🚫 Skipping VS Code settings (--SkipVSCodeSettings specified)" "Yellow"
    }

    if ($SkipDevContainer) {
        $filesToInstall = $filesToInstall | Where-Object { $_.Category -ne "DevContainer" }
        Write-ColoredOutput "🚫 Skipping dev container config (--SkipDevContainer specified)" "Yellow"
    }

    Write-ColoredOutput "📋 Files to install:" "Blue"

    $categories = $filesToInstall | Group-Object Category
    foreach ($category in $categories) {
        Write-ColoredOutput "  $($category.Name):" "Cyan"
        foreach ($file in $category.Group) {
            $exists = Test-FileExists -Path $file.FilePath
            $status = if ($exists) { "[EXISTS]" } else { "[NEW]" }
            $color = if ($exists) { "Yellow" } else { "Green" }
            Write-ColoredOutput "    $status $($file.FilePath)" $color
        }
    }

    Write-Host ""

    return $filesToInstall
}

function Show-PostInstallInstructions {
    Write-Host ""
    Write-ColoredOutput "🎉 Installation Complete!" "Green"
    Write-ColoredOutput "=========================" "Green"
    Write-Host ""
    Write-ColoredOutput "Next steps:" "Blue"
    Write-ColoredOutput "1.  Open VS Code and start using Copilot Chat with the new prompts and chatmodes" "White"
    Write-ColoredOutput "2. 📖 Check out the README.md in the HVE ADO Scaffold repo for workflow examples" "White"
    Write-Host ""
    Write-ColoredOutput "Key features now available:" "Blue"
    Write-ColoredOutput "• Azure DevOps work item integration" "White"
    Write-ColoredOutput "• Automated task planning and research workflows" "White"
    Write-ColoredOutput "• PRD and ADR creation chatmodes" "White"
    Write-ColoredOutput "• Enhanced commit message generation" "White"
    Write-ColoredOutput "• Markdown linting and spell checking" "White"
    Write-Host ""
    Write-ColoredOutput "Repository: https://github.com/agreaves-ms/hve-ado-scaffold" "Cyan"
}

# Main execution
try {
    Write-Host ""

    # Show pre-install summary and get filtered file list
    $filesToInstall = Show-PreInstallSummary

    # Create target directory if it doesn't exist
    New-DirectoryIfNotExists -Path $TargetPath
    $TargetPath = Resolve-Path $TargetPath

    exit 2

    ######################################################################################################

    Write-Host ""
    Write-ColoredOutput "🔄 Starting installation..." "Blue"

    # Download and install files
    $successCount = 0
    $skipCount = 0
    $failCount = 0

    foreach ($file in $filesToInstall) {
        $sourceUrl = "$REPO_URL/$($file.FilePath)"

        $result = Copy-FileWithPrompt -SourceUrl $sourceUrl -TargetFile $file.FilePath

        if ($result) {
            $successCount++
        }
        elseif (Test-FileExists -Path $file.FilePath) {
            $skipCount++
        }
        else {
            $failCount++
        }
    }

    # Show results summary
    Write-Host ""
    Write-ColoredOutput "📊 Installation Summary:" "Blue"
    Write-ColoredOutput "  ✅ Installed: $successCount files" "Green"
    Write-ColoredOutput "  ⏭️  Skipped: $skipCount files" "Yellow"
    Write-ColoredOutput "  ❌ Failed: $failCount files" "Red"

    if ($failCount -eq 0) {
        Show-PostInstallInstructions
        exit 0
    }
    else {
        Write-ColoredOutput "⚠️  Some files failed to install. Check the errors above." "Yellow"
        exit 1
    }
}
catch {
    Write-ColoredOutput "❌ Unexpected error: $($_.Exception.Message)" "Red"
    exit 1
}
