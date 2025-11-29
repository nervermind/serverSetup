# Deployment Instructions

This guide explains how to deploy this project to GitHub and make it available for curl installation.

## 📋 Prerequisites

- GitHub account
- Git installed locally
- Repository created on GitHub

## 🚀 Initial Deployment

### 1. Initialize Git Repository

```bash
cd /path/to/serverSetup

# Initialize git if not already done
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Secure Server Setup Framework v1.0.0"
```

### 2. Connect to GitHub

```bash
# Add remote (replace USERNAME and REPO with your values)
git remote add origin https://github.com/USERNAME/REPO.git

# Verify remote
git remote -v
```

### 3. Push to GitHub

```bash
# Push to main branch
git branch -M main
git push -u origin main
```

### 4. Update URLs in Files

After pushing, update the following placeholders in your files:

**In setup.sh:**
```bash
readonly REPO_BASE_URL="${REPO_BASE_URL:-https://raw.githubusercontent.com/USERNAME/REPO/main}"
```

**In README.md:**
```markdown
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash
```

Replace `USERNAME` and `REPO` with your actual GitHub username and repository name.

**Files to update:**
- [setup.sh](setup.sh) - Line 18
- [README.md](README.md) - Multiple locations
- [INSTALL.md](INSTALL.md) - Multiple locations
- [QUICKREF.md](QUICKREF.md) - Line 7

### 5. Regenerate Checksums

After updating URLs, regenerate checksums:

```bash
sha256sum setup.sh scripts/*.sh backup.sh restore.sh test-suite.sh .env.sample > checksums.txt
```

### 6. Commit and Push Updates

```bash
git add setup.sh README.md INSTALL.md QUICKREF.md checksums.txt
git commit -m "Update repository URLs and checksums"
git push
```

## 🔐 Optional: GPG Signing

For enhanced security, sign your releases with GPG.

### Generate GPG Key (if you don't have one)

```bash
gpg --full-generate-key
```

Follow prompts:
- Key type: RSA and RSA
- Key size: 4096
- Expiration: Your choice
- Name and email

### Sign Checksums

```bash
# Sign checksums file
gpg --armor --detach-sign checksums.txt

# This creates checksums.txt.asc
```

### Export Public Key

```bash
# Export your public key
gpg --armor --export YOUR_EMAIL > public-key.asc

# Add to repository
git add checksums.txt.asc public-key.asc
git commit -m "Add GPG signatures and public key"
git push
```

### Update Documentation

Add to README.md:

```markdown
## GPG Verification

To verify GPG signatures:

\`\`\`bash
# Import public key
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/public-key.asc | gpg --import

# Verify signature
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/checksums.txt -o checksums.txt
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/checksums.txt.asc -o checksums.txt.asc
gpg --verify checksums.txt.asc checksums.txt
\`\`\`
```

## 📦 Creating Releases

### Create a Release Tag

```bash
# Tag the release
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag
git push origin v1.0.0
```

### Create GitHub Release

1. Go to your repository on GitHub
2. Click "Releases" → "Create a new release"
3. Select tag: `v1.0.0`
4. Release title: `v1.0.0 - Initial Release`
5. Description: Copy from [CHANGELOG.md](CHANGELOG.md)
6. Attach files:
   - checksums.txt
   - checksums.txt.asc (if using GPG)
7. Click "Publish release"

## 🧪 Testing Deployment

### Test Installation

On a fresh Debian 13 server:

```bash
# Test the curl installation
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh | sudo bash
```

### Verify Checksums

```bash
# Download and verify
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/checksums.txt -o checksums.txt
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh -o setup.sh
sha256sum -c checksums.txt --ignore-missing
```

## 📝 Post-Deployment Checklist

- [ ] Repository is public (or private if intended)
- [ ] All placeholder URLs updated
- [ ] Checksums regenerated and committed
- [ ] GPG signature created (optional)
- [ ] Release created on GitHub
- [ ] Installation tested on fresh server
- [ ] Documentation links verified
- [ ] License file present
- [ ] README.md displays correctly on GitHub
- [ ] All scripts have execute permissions

## 🔄 Updating the Project

### For Bug Fixes

```bash
# Make your changes
git add .
git commit -m "Fix: Description of bug fix"
git push

# Update checksums
sha256sum setup.sh scripts/*.sh backup.sh restore.sh test-suite.sh .env.sample > checksums.txt
git add checksums.txt
git commit -m "Update checksums"
git push

# Create patch release
git tag -a v1.0.1 -m "Patch release v1.0.1"
git push origin v1.0.1
```

### For New Features

```bash
# Work on feature branch
git checkout -b feature/new-feature
# Make changes
git add .
git commit -m "Add: New feature description"
git push origin feature/new-feature

# Create pull request on GitHub
# After merge to main:
git checkout main
git pull

# Update version and checksums
# Update CHANGELOG.md
sha256sum setup.sh scripts/*.sh backup.sh restore.sh test-suite.sh .env.sample > checksums.txt

git add .
git commit -m "Release v1.1.0"
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin main --tags
```

## 🌐 Making Repository Public

If starting with a private repository:

1. Go to repository Settings
2. Scroll to "Danger Zone"
3. Click "Change visibility"
4. Select "Make public"
5. Confirm action

## 📊 GitHub Repository Settings

### Recommended Settings

**General:**
- Description: "Production-ready, curl-installable secure server setup framework for Debian 13"
- Website: Link to documentation (if any)
- Topics: debian, docker, security, devops, automation, server-setup, traefik, nginx

**Features:**
- ✅ Issues
- ✅ Discussions (for community support)
- ✅ Wiki (for extended documentation)

**Security:**
- Enable Dependabot alerts
- Enable security advisories
- Add SECURITY.md (for responsible disclosure)

### Branch Protection

For `main` branch:
1. Go to Settings → Branches
2. Add rule for `main`
3. Enable:
   - Require pull request reviews before merging
   - Require status checks to pass (if CI/CD setup)
   - Require signed commits (if using GPG)

## 🎯 Continuous Improvement

### Monitor Usage

- Watch repository to track stars/forks
- Monitor Issues for bug reports
- Review Pull Requests for contributions
- Update documentation based on user feedback

### Regular Maintenance

- Monthly: Review and update dependencies
- Quarterly: Test on latest Debian version
- Annually: Review and update security practices

## 📞 Support Channels

Set up support channels:

1. **GitHub Issues**: Bug reports and feature requests
2. **GitHub Discussions**: Q&A and community support
3. **Security Policy**: Create SECURITY.md for vulnerability reports
4. **Email**: For private inquiries (optional)

## 🎉 Promotion

After deployment:

1. Write blog post or article
2. Share on social media (Twitter, Reddit, etc.)
3. Submit to awesome lists (awesome-sysadmin, awesome-docker)
4. Add to DevOps community forums
5. Create video tutorial (optional)

## ✅ Final Verification

Before announcing:

```bash
# Fresh server test
curl -fsSL https://raw.githubusercontent.com/USERNAME/REPO/main/setup.sh | sudo bash

# Verify all features work
/opt/server-setup/test-suite.sh

# Verify documentation links
# Check README.md renders correctly on GitHub
# Verify all badges/shields work
```

## 📄 License Reminder

This project uses MIT License. Users can:
- Use commercially
- Modify
- Distribute
- Use privately

But must:
- Include license and copyright notice
- Accept "as-is" with no warranty

---

**You're now ready to deploy!** 🚀

For questions, see [CONTRIBUTING.md](CONTRIBUTING.md) or open an issue.
