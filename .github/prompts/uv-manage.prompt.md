---
mode: "agent"
tools: ['runCommands', 'runTasks', 'edit', 'search', 'think', 'problems', 'githubRepo', 'context7', 'search', 'getPythonEnvironmentInfo', 'getPythonExecutableCommand', 'installPythonPackage', 'configurePythonEnvironment', 'configureNotebook', 'listNotebookPackages', 'installNotebookPackages', 'websearch']
description: "Create a uv project in the current workspace"
---

Must follow all instructions provided by #file:../instructions/uv-projects.instructions.md

# Create a uv project in the current workspace

Review any python files (*.py, *.ipynb, *.pyproj, *.toml, *.lock) in the current workspace using the search tool to discover any python dependencies and requirements. If a uv project has not yet been created, create one.

# Manage the uv project

If a uv project already exists, ensure the virtual environment is properly configured and up-to-date. Use the appropriate uv commands to add any missing dependencies, sync the environment, and lock the dependencies as needed.

