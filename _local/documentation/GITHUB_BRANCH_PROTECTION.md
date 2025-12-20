# GitHub Branch Protection Setup Guide

## Why Protect the Main Branch?

Protecting your main branch prevents:
- Accidental force pushes
- Accidental deletion
- Merges without required checks
- Direct pushes (forces use of pull requests)

## Quick Setup Steps

### 1. Go to Repository Settings

1. Navigate to: `https://github.com/imvikverma/ah-v1-beta`
2. Click **Settings** (top right, in repository)
3. Click **Branches** (left sidebar)

### 2. Add Branch Protection Rule

1. Under **Branch protection rules**, click **Add rule** or **Add branch protection rule**
2. In **Branch name pattern**, enter: `main`
3. Configure the following settings:

### 3. Recommended Settings

#### Essential Protections:
- ✅ **Require a pull request before merging**
  - Required number of approvals: `1` (or `0` if solo)
  - Dismiss stale pull request approvals when new commits are pushed: ✅
  - Require review from Code Owners: Optional

- ✅ **Require status checks to pass before merging**
  - Required status checks:
    - ` ` (if you want deployments to block merges)
    - Or leave empty if you want deployments to run after merge

- ✅ **Require conversation resolution before merging**
  - Ensures all PR comments are addressed

- ✅ **Require signed commits** (Optional but recommended)
  - Adds extra security layer

#### Safety Protections:
- ✅ **Do not allow bypassing the above settings**
  - Even admins must follow rules

- ✅ **Restrict who can push to matching branches**
  - Only allow specific people/teams (optional)

- ✅ **Allow force pushes** - ❌ **UNCHECK THIS**
  - Prevents accidental force pushes

- ✅ **Allow deletions** - ❌ **UNCHECK THIS**
  - Prevents accidental branch deletion

### 4. Save the Rule

Click **Create** or **Save changes**

## Alternative: Quick Protection (Minimal)

If you want minimal protection:

1. Go to: Settings → Branches
2. Add rule for `main`
3. Check only:
   - ✅ **Require a pull request before merging**
   - ✅ **Do not allow force pushes**
   - ✅ **Do not allow deletions**

## For Solo Development

If you're working solo and want protection but still need flexibility:

1. Go to: Settings → Branches
2. Add rule for `main`
3. Check:
   - ✅ **Require a pull request before merging**
   - ✅ **Allow force pushes** - ❌ **UNCHECK**
   - ✅ **Allow deletions** - ❌ **UNCHECK**
   - ✅ **Do not allow bypassing** - ❌ **UNCHECK** (so you can still push directly if needed)

## Verification

After setting up:
- Try to force push: Should be blocked
- Try to delete branch: Should be blocked
- Direct push to main: May be blocked (if you enabled PR requirement)

## Current Status

Your main branch is currently **unprotected**. This means:
- ⚠️ Anyone with write access can force push
- ⚠️ Anyone with write access can delete the branch
- ⚠️ No required checks before merging

## Recommended for Production

For a production repository, enable:
1. ✅ Require pull request reviews
2. ✅ Require status checks (Cloudflare deployment)
3. ✅ Require conversation resolution
4. ✅ Do not allow force pushes
5. ✅ Do not allow deletions
6. ✅ Do not allow bypassing (even for admins)

