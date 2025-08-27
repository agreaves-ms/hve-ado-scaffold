#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Install HVE ADO Scaffold files into an existing repository
.DESCRIPTION
    This script downloads and installs the Hyper-Velocity Engineering (HVE) Azure DevOps scaffold
    files from the agreaves-ms/hve-ado-scaffold repository into your current repository.

    The script will merge in all important configuration files, prompts, chatmodes, and instructions
    needed to supercharge GitHub Copilot + Azure DevOps workflows.
.PARAMETER Force
    Overwrite existing files without prompting
.PARAMETER SkipVSCodeSettings
    Skip copying VS Code settings files (.vscode/settings.json and .vscode/mcp.json)
.PARAMETER SkipDevContainer
    Skip copying the dev container configuration (.devcontainer/devcontainer.json)
.PARAMETER TargetPath
    Target directory to install files into (defaults to current directory)
.EXAMPLE
    .\Install-HveAdoScaffold.ps1
    Install all HVE ADO scaffold files to the current directory
.EXAMPLE
    .\Install-HveAdoScaffold.ps1 -Force -SkipDevContainer
    Install files, overwriting existing ones, but skip the dev container configuration
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipVSCodeSettings,

    [Parameter()]
    [switch]$SkipDevContainer,

    [Parameter()]
    [string]$TargetPath = "."
)

# Configuration
$REPO_URL = "https://raw.githubusercontent.com/agreaves-ms/hve-ado-scaffold/main"
$TEMP_DIR = Join-Path $env:TEMP "hve-ado-scaffold-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Files to download and their target locations
$FILES_TO_COPY = @(
    # VS Code configuration
    @{ Source = ".vscode/settings.json"; Target = ".vscode/settings.json"; Category = "VSCode" }
    @{ Source = ".vscode/mcp.json"; Target = ".vscode/mcp.json"; Category = "VSCode" }

    # Dev container
    @{ Source = ".devcontainer/devcontainer.json"; Target = ".devcontainer/devcontainer.json"; Category = "DevContainer" }

    # GitHub configuration
    @{ Source = ".github/copilot-instructions.md"; Target = ".github/copilot-instructions.md"; Category = "Core" }

    # Prompts
    @{ Source = ".github/prompts/ado-get-build-info.prompt.md"; Target = ".github/prompts/ado-get-build-info.prompt.md"; Category = "Core" }
    @{ Source = ".github/prompts/ado-get-my-work-items.prompt.md"; Target = ".github/prompts/ado-get-my-work-items.prompt.md"; Category = "Core" }
    @{ Source = ".github/prompts/ado-process-my-work-items-for-task-planning.prompt.md"; Target = ".github/prompts/ado-process-my-work-items-for-task-planning.prompt.md"; Category = "Core" }
    @{ Source = ".github/prompts/ado-update-wit-items.prompt.md"; Target = ".github/prompts/ado-update-wit-items.prompt.md"; Category = "Core" }
    @{ Source = ".github/prompts/git-commit.prompt.md"; Target = ".github/prompts/git-commit.prompt.md"; Category = "Core" }
    @{ Source = ".github/prompts/git-commit-message.prompt.md"; Target = ".github/prompts/git-commit-message.prompt.md"; Category = "Core" }
    @{ Source = ".github/prompts/git-setup.prompt.md"; Target = ".github/prompts/git-setup.prompt.md"; Category = "Core" }

    # Chat modes
    @{ Source = ".github/chatmodes/adr-creation.chatmode.md"; Target = ".github/chatmodes/adr-creation.chatmode.md"; Category = "Core" }
    @{ Source = ".github/chatmodes/ado-prd-to-wit.chatmode.md"; Target = ".github/chatmodes/ado-prd-to-wit.chatmode.md"; Category = "Core" }
    @{ Source = ".github/chatmodes/prd-builder.chatmode.md"; Target = ".github/chatmodes/prd-builder.chatmode.md"; Category = "Core" }
    @{ Source = ".github/chatmodes/prompt-builder.chatmode.md"; Target = ".github/chatmodes/prompt-builder.chatmode.md"; Category = "Core" }
    @{ Source = ".github/chatmodes/task-planner.chatmode.md"; Target = ".github/chatmodes/task-planner.chatmode.md"; Category = "Core" }
    @{ Source = ".github/chatmodes/task-researcher.chatmode.md"; Target = ".github/chatmodes/task-researcher.chatmode.md"; Category = "Core" }

    # Instructions
    @{ Source = ".github/instructions/ado-get-build-info.instructions.md"; Target = ".github/instructions/ado-get-build-info.instructions.md"; Category = "Core" }
    @{ Source = ".github/instructions/ado-update-wit-items.instructions.md"; Target = ".github/instructions/ado-update-wit-items.instructions.md"; Category = "Core" }
    @{ Source = ".github/instructions/ado-wit-planning.instructions.md"; Target = ".github/instructions/ado-wit-planning.instructions.md"; Category = "Core" }
    @{ Source = ".github/instructions/commit-message.instructions.md"; Target = ".github/instructions/commit-message.instructions.md"; Category = "Core" }
    @{ Source = ".github/instructions/markdown.instructions.md"; Target = ".github/instructions/markdown.instructions.md"; Category = "Core" }
    @{ Source = ".github/instructions/task-implementation.instructions.md"; Target = ".github/instructions/task-implementation.instructions.md"; Category = "Core" }
    @{ Source = ".github/instructions/csharp/csharp.instructions.md"; Target = ".github/instructions/csharp/csharp.instructions.md"; Category = "Core" }
    @{ Source = ".github/instructions/csharp/csharp-tests.instructions.md"; Target = ".github/instructions/csharp/csharp-tests.instructions.md"; Category = "Core" }

    # Documentation template
    @{ Source = "docs/solution-adr-library/adr-template-solutions.md"; Target = "docs/solution-adr-library/adr-template-solutions.md"; Category = "Core" }

    # Configuration files
    @{ Source = ".markdownlint.json"; Target = ".markdownlint.json"; Category = "Core" }
    @{ Source = ".cspell.json"; Target = ".cspell.json"; Category = "Core" }
    @{ Source = ".cspell-dictionary.txt"; Target = ".cspell-dictionary.txt"; Category = "Core" }
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

function Test-GitRepository {
    if (-not (Test-Path ".git" -PathType Container)) {
        Write-ColoredOutput "❌ Error: Current directory is not a Git repository." "Red"
        Write-ColoredOutput "   Please run this script from the root of your Git repository." "Yellow"
        return $false
    }
    return $true
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
        [string]$TargetPath,
        [switch]$Force
    )

    $fullTargetPath = Join-Path $TargetPath $TargetPath
    $shouldCopy = $true

    if ((Test-Path $fullTargetPath) -and -not $Force) {
        do {
            $response = Read-Host "File '$TargetPath' already exists. Overwrite? (y/N/a=all)"
            $response = $response.ToLower()

            switch ($response) {
                'y' { $shouldCopy = $true; break }
                'yes' { $shouldCopy = $true; break }
                'a' { $shouldCopy = $true; $script:ForceAll = $true; break }
                'all' { $shouldCopy = $true; $script:ForceAll = $true; break }
                'n' { $shouldCopy = $false; break }
                'no' { $shouldCopy = $false; break }
                '' { $shouldCopy = $false; break }
                default { Write-ColoredOutput "Please enter 'y', 'n', or 'a'" "Yellow" }
            }
        } while ($response -notin @('y', 'yes', 'n', 'no', 'a', 'all', ''))
    }

    if ($shouldCopy) {
        try {
            New-DirectoryIfNotExists -Path $TargetPath

            Write-ColoredOutput "⬇️  Downloading: $TargetPath" "Cyan"
            Invoke-WebRequest -Uri $SourceUrl -OutFile $fullTargetPath -ErrorAction Stop

            Write-ColoredOutput "✅ Installed: $TargetPath" "Green"
            return $true
        }
        catch {
            Write-ColoredOutput "❌ Failed to download $TargetPath : $($_.Exception.Message)" "Red"
            return $false
        }
    }
    else {
        Write-ColoredOutput "⏭️  Skipped: $TargetPath" "Yellow"
        return $false
    }
}

function Show-PreInstallSummary {
    Write-ColoredOutput "🚀 HVE ADO Scaffold Installer" "Magenta"
    Write-ColoredOutput "==============================" "Magenta"
    Write-Host ""
    Write-ColoredOutput "Target directory: $(Resolve-Path $TargetPath)" "Blue"
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
            $exists = Test-FileExists -Path $file.Target
            $status = if ($exists) { "[EXISTS]" } else { "[NEW]" }
            $color = if ($exists) { "Yellow" } else { "Green" }
            Write-ColoredOutput "    $status $($file.Target)" $color
        }
    }

    Write-Host ""

    if ($Force) {
        Write-ColoredOutput "⚠️  Force mode enabled - existing files will be overwritten" "Yellow"
    }

    return $filesToInstall
}

function Show-PostInstallInstructions {
    Write-Host ""
    Write-ColoredOutput "🎉 Installation Complete!" "Green"
    Write-ColoredOutput "=========================" "Green"
    Write-Host ""
    Write-ColoredOutput "Next steps:" "Blue"
    Write-ColoredOutput "1. 🔧 Configure MCP settings in .vscode/mcp.json with your Azure DevOps details" "White"
    Write-ColoredOutput "2. 🚀 Open VS Code and start using Copilot Chat with the new prompts and chatmodes" "White"
    Write-ColoredOutput "3. 📖 Check out the README.md in the HVE ADO Scaffold repo for workflow examples" "White"
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

# Initialize global variable for force-all mode
$script:ForceAll = $false

# Main execution
try {
    Write-Host ""

    # Validate we're in a Git repository
    if (-not (Test-GitRepository)) {
        exit 1
    }

    # Resolve and validate target path
    $TargetPath = Resolve-Path $TargetPath -ErrorAction Stop

    # Show pre-install summary and get filtered file list
    $filesToInstall = Show-PreInstallSummary

    # Confirm installation
    if (-not $Force) {
        Write-Host ""
        $confirm = Read-Host "Proceed with installation? (Y/n)"
        if ($confirm.ToLower() -in @('n', 'no')) {
            Write-ColoredOutput "❌ Installation cancelled by user." "Yellow"
            exit 0
        }
    }

    Write-Host ""
    Write-ColoredOutput "🔄 Starting installation..." "Blue"

    # Download and install files
    $successCount = 0
    $skipCount = 0
    $failCount = 0

    foreach ($file in $filesToInstall) {
        $sourceUrl = "$REPO_URL/$($file.Source)"
        $forceThis = $Force -or $script:ForceAll

        $result = Copy-FileWithPrompt -SourceUrl $sourceUrl -TargetPath $file.Target -Force:$forceThis

        if ($result) {
            $successCount++
        }
        elseif (Test-FileExists -Path $file.Target) {
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
