#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Install HVE ADO Scaffold files into an existing repository
.DESCRIPTION
    This script downloads and installs the Hyper-Velocity Engineering (HVE) Azure DevOps scaffold
    files from the agreaves-ms/hve-ado-scaffold repository into your current repository.

    The script will merge in all important configuration files, prompts, chatmodes, and instructions
    needed to supercharge GitHub Copilot + Azure DevOps workflows.
.PARAMETER TargetPath
    Target directory to install files into (defaults to current directory)
.PARAMETER WhatIf
    Shows what would happen if the command runs. No files will be downloaded or overwritten.
.PARAMETER Confirm
    Prompts for confirmation before executing actions that change files.
.EXAMPLE
    .\Install-HveAdoScaffold.ps1
    Install all HVE ADO scaffold files to the current directory
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$TargetPath = "."
)

# Configuration
$REPO_URL = "https://raw.githubusercontent.com/agreaves-ms/hve-ado-scaffold/main"

# Files to download and their target locations
$FILES_TO_INSTALL = @(
    # VS Code configuration
    @{ FilePath = ".vscode/settings.json" }
    @{ FilePath = ".vscode/mcp.json" }

    # Dev container
    @{ FilePath = ".devcontainer/devcontainer.json" }

    # GitHub configuration
    @{ FilePath = ".github/copilot-instructions.md" }

    # Prompts
    @{ FilePath = ".github/prompts/ado-get-build-info.prompt.md" }
    @{ FilePath = ".github/prompts/ado-get-my-work-items.prompt.md" }
    @{ FilePath = ".github/prompts/ado-process-my-work-items-for-task-planning.prompt.md" }
    @{ FilePath = ".github/prompts/ado-update-wit-items.prompt.md" }
    @{ FilePath = ".github/prompts/git-commit.prompt.md" }
    @{ FilePath = ".github/prompts/git-commit-message.prompt.md" }
    @{ FilePath = ".github/prompts/git-setup.prompt.md" }

    # Chat modes
    @{ FilePath = ".github/chatmodes/adr-creation.chatmode.md" }
    @{ FilePath = ".github/chatmodes/ado-prd-to-wit.chatmode.md" }
    @{ FilePath = ".github/chatmodes/prd-builder.chatmode.md" }
    @{ FilePath = ".github/chatmodes/prompt-builder.chatmode.md" }
    @{ FilePath = ".github/chatmodes/task-planner.chatmode.md" }
    @{ FilePath = ".github/chatmodes/task-researcher.chatmode.md" }

    # Instructions
    @{ FilePath = ".github/instructions/ado-get-build-info.instructions.md" }
    @{ FilePath = ".github/instructions/ado-update-wit-items.instructions.md" }
    @{ FilePath = ".github/instructions/ado-wit-planning.instructions.md" }
    @{ FilePath = ".github/instructions/commit-message.instructions.md" }
    @{ FilePath = ".github/instructions/markdown.instructions.md" }
    @{ FilePath = ".github/instructions/task-implementation.instructions.md" }
    @{ FilePath = ".github/instructions/csharp/csharp.instructions.md" }
    @{ FilePath = ".github/instructions/csharp/csharp-tests.instructions.md" }

    # Documentation template
    @{ FilePath = "docs/solution-adr-library/adr-template-solutions.md" }
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

    return Test-Path $directory
}

function Test-FileExists {
    param([string]$Path)

    $fullPath = Join-Path $TargetPath $Path
    return Test-Path $fullPath
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
    Write-Host ""
    Write-ColoredOutput "🚀 HVE ADO Scaffold Installer" "Magenta"
    Write-ColoredOutput "==============================" "Magenta"
    Write-Host ""
    Write-ColoredOutput "Target directory: $(Resolve-FilePath $TargetPath)" "Blue"
    Write-Host ""

    Write-ColoredOutput "📋 Files to install:" "Blue"

    foreach ($file in $FILES_TO_INSTALL) {
        $exists = Test-FileExists -Path $file.FilePath
        $status = if ($exists) { "[EXISTS]" } else { "[NEW]" }
        $color = if ($exists) { "Yellow" } else { "Green" }
        Write-ColoredOutput "    $status $($file.FilePath)" $color
    }

    Write-Host ""
}

enum InstallStatus {
    Success
    Skipped
    Failed
}

function Install-OneFileFromDownload {
    param(
        [string]$FilePath,
        [string]$SourceUrl,
        [string]$FullTargetPath
    )
    try {
        Write-ColoredOutput "  ⬇️  Downloading: $FilePath" "Cyan"
        Invoke-WebRequest -Uri $SourceUrl -OutFile $FullTargetPath -ErrorAction Stop

        Write-ColoredOutput "  ✅ Installed: $FilePath" "Green"
        return [InstallStatus]::Success
    }
    catch {
        Write-ColoredOutput "  ❌ Failed to download $FilePath : $($_.Exception.Message)" "Red"
        return [InstallStatus]::Failed
    }
}

function Install-VSCodeSettingsJson {
    return [InstallStatus]::Skipped
}

function Install-VSCodeMcpJson {
    return [InstallStatus]::Skipped
}

function Install-AllFiles {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param()

    Write-ColoredOutput "🔄 Starting installation..." "Blue"

    # Create target directory if it doesn't exist
    if (-not (New-DirectoryIfNotExists -Path $TargetPath)) {
        Write-ColoredOutput "❌ Failed to create target directory: $TargetPath" "Red"
        exit 1
    }
    $TargetPath = Resolve-Path $TargetPath

    # Download and install files
    $successCount = 0
    $skipCount = 0
    $failCount = 0

    foreach ($file in $FILES_TO_INSTALL) {
        $filePath = $file.FilePath
        $sourceUrl = "$REPO_URL/$($filePath)"

        New-DirectoryIfNotExists -Path $filePath | Out-Null

        Write-ColoredOutput "📥 Installing $filePath" "Blue"
        $fullTargetPath = Join-Path $TargetPath $filePath
        $targetPathExists = Test-Path $fullTargetPath

        # If the file doesn't exist, simply download it
        if (-not $targetPathExists) {
            $result = Install-OneFileFromDownload `
                -FilePath $filePath `
                -SourceUrl $sourceUrl `
                -FullTargetPath $fullTargetPath
        }
        elseif ($filePath -eq ".vscode/settings.json") {
            # settings.json is required, so we need to ensure it is installed
            $result = Install-VSCodeSettingsJson
        }
        elseif ($filePath -eq ".vscode/mcp.json") {
            # mcp.json is required, so we need to ensure it is installed
            $result = Install-VSCodeMcpJson
        }
        elseif ($PSCmdlet.ShouldProcess($filePath, "Installing over existing file")) {
            # For all other fiels, ask the user if they want to overwrite the existing file
            $result = Install-OneFileFromDownload `
                -FilePath $filePath `
                -SourceUrl $sourceUrl `
                -FullTargetPath $fullTargetPath
        }
        else {
            # This file is skipped
            Write-ColoredOutput "  ⚠️  Skipping existing file: $filePath" "Yellow"
            $result = [InstallStatus]::Skipped
        }

        # Increment counters
        switch ($result) {
            "Success" { $successCount++ }
            "Skipped" { $skipCount++ }
            "Failed" { $failCount++ }
        }
    }

    # Show results summary
    Write-Host ""
    Write-ColoredOutput "📊 Installation Summary:" "Blue"
    Write-ColoredOutput "  ✅ Installed: $successCount files" "Green"
    Write-ColoredOutput "  ⏭️  Skipped: $skipCount files" "Yellow"
    Write-ColoredOutput "  ❌ Failed: $failCount files" "Red"

    return @{
        SuccessCount = $successCount
        SkipCount    = $skipCount
        FailCount    = $failCount
    }
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
    Show-PreInstallSummary

    if ($WhatIfPreference) {
        Write-ColoredOutput "ℹ️  Run without WhatIf specified to actually install the files." "Yellow"
        exit 0
    }

    $installStats = Install-AllFiles

    if ($installStats.FailCount -eq 0) {
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
