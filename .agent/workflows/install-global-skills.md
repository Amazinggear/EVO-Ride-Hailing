---
description: Auto-installs global skills into new projects
---

# Global Skills Installer Workflow

This workflow automates the process of copying your "Superpowers" (custom skills) from the central `geminiskillcreator` repository to any new project directory.

## Prerequisites
- The source repository must be at `c:\Google Antigravity Projects\geminiskillcreator`.
- You must be inside the root of the **destination** project where you want the skills installed.

## Workflow Steps

1.  **Check Destination Safety**
    - Verify that `.agent/skills` does not already contain conflicting modifications. (If it exists, ask for confirmation).

2.  **Copy Skills**
    - Copy the contents of `c:\Google Antigravity Projects\geminiskillcreator\.agent\skills` to `./.agent/skills`.
    - **Command:** `xcopy /E /I /Y "c:\Google Antigravity Projects\geminiskillcreator\.agent\skills" ".agent\skills"`
    - *Note:* This command recursively copies all directories and files.

3.  **Verify Installation**
    - Run `dir .agent\skills` to confirm the folders are present.

// turbo-all
4.  **Final Report**
    - Announce which skills were installed and that the agent is ready to use them.

## Usage
Simply say: *"Install my global skills here"* or run this workflow when starting a new project.
