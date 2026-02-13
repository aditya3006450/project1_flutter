# Creating a Release

This guide explains how to create a new release of PROJECT 1 with automated builds for all platforms.

## Prerequisites

1. **GitHub Actions enabled** - Go to Repository Settings → Actions → General → Allow actions
2. **Git configured** - Make sure Git is installed and configured with your GitHub account
3. **Version updated** - Update the version in `pubspec.yaml`

## Release Process

### Step 1: Update Version

Edit `pubspec.yaml` and update the version number:

```yaml
version: 1.0.0+1  # Change to your new version (e.g., 1.1.0+1)
```

### Step 2: Commit Your Changes

```bash
git add .
git commit -m "Release v1.0.0"
```

Replace `1.0.0` with your actual version number.

### Step 3: Create and Push Tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `v` prefix is important - the workflow triggers on tags matching `v*`.

## What Happens Automatically

Once you push the tag, GitHub Actions will:

1. **Build all platforms:**
   - Android (APK)
   - Windows (EXE + MSI)
   - Linux (AppImage + Deb)

2. **Create a GitHub Release:**
   - Named after the tag (e.g., "Release v1.0.0")
   - With release notes listing all downloads

3. **Attach all build artifacts**

This process takes ~10-15 minutes depending on build times.

## Downloading Your Release

After the workflow completes:

1. Go to your GitHub repository
2. Click on **Releases** (or visit: `https://github.com/aditya3006450/project1_flutter/releases`)
3. Click on your release tag
4. Download the appropriate file for your platform

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes

## Troubleshooting

### Workflow didn't trigger
- Make sure you're pushing a tag: `git push origin v1.0.0`
- Check Actions tab for any errors

### Build failed
- Check the Actions log for error details
- Common issues: Flutter SDK version, missing dependencies

### Release not created
- Ensure workflow completed successfully
- Check the "release" job output in Actions

## Quick Reference

```bash
# Full release commands
git add .
git commit -m "Release v1.0.0"
git tag v1.0.0
git push origin v1.0.0

# Check tags
git tag -l

# Delete a tag (if needed)
git tag -d v1.0.0
git push origin --delete v1.0.0
```

## Future Enhancements

Planned improvements:
- macOS builds (requires macOS runner)
- iOS builds (requires Apple Developer account)
- Auto-update within the app
- Release notes from Conventional Commits
