# Contributing to Secure Server Setup Framework

First off, thank you for considering contributing to this project! It's people like you that make this tool better for everyone.

## Code of Conduct

This project adheres to a simple code of conduct: be respectful, be constructive, and help make this project better.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected vs actual behavior**
- **System information** (OS version, architecture, etc.)
- **Relevant logs** (from `/var/log/server-setup/`)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Clear use case** - Why is this needed?
- **Detailed description** - What should it do?
- **Alternative approaches** - Have you considered other solutions?

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Test thoroughly**
5. **Update documentation**
6. **Commit with clear messages**
7. **Push to your fork**
8. **Open a Pull Request**

## Development Guidelines

### Script Standards

All scripts must:

1. **Start with a shebang**: `#!/usr/bin/env bash`
2. **Use strict mode**: `set -euo pipefail`
3. **Include header comments**: Purpose, description
4. **Follow naming convention**: `##-descriptive-name.sh`
5. **Be idempotent**: Safe to run multiple times
6. **Include error handling**: Proper error messages and exit codes
7. **Log all actions**: Use consistent logging format
8. **Be well commented**: Explain non-obvious code

### Code Style

```bash
# Use consistent indentation (4 spaces)
function my_function() {
    local var="value"

    if [[ condition ]]; then
        # Do something
    fi
}

# Use descriptive variable names
ADMIN_USERNAME="admin"  # Good
U="admin"               # Bad

# Quote variables
echo "$VARIABLE"        # Good
echo $VARIABLE          # Bad (unless you need word splitting)

# Use [[ ]] for conditionals
if [[ -f "$file" ]]; then  # Good
if [ -f "$file" ]; then    # OK but less powerful
```

### Testing Requirements

Before submitting a PR:

1. **Test on fresh Debian 13 installation**
2. **Run the test suite**: `./test-suite.sh`
3. **Verify idempotency**: Run setup twice
4. **Check for shellcheck warnings**: `shellcheck *.sh scripts/*.sh`
5. **Test backup and restore**: Verify backup/restore works

### Documentation

Update documentation when you:

- Add new features
- Change configuration options
- Modify installation flow
- Fix bugs that users might encounter

Documentation files to update:
- `README.md` - Main documentation
- `CHANGELOG.md` - Version history
- `.env.sample` - Configuration template
- Inline script comments

## Project Structure

```
/
├── setup.sh              # Bootstrap script (curl entry point)
├── scripts/              # Modular installation scripts
│   ├── 01-preflight.sh   # Pre-installation checks
│   ├── 02-ssh-hardening.sh
│   └── ...
├── backup.sh             # Backup utility
├── restore.sh            # Restore utility
├── test-suite.sh         # Automated tests
├── .env.sample           # Configuration template
├── README.md             # Main documentation
├── CHANGELOG.md          # Version history
├── CONTRIBUTING.md       # This file
└── LICENSE               # MIT License
```

## Adding New Features

### Adding a New Installation Script

1. Create script in `scripts/` directory with next number: `##-feature-name.sh`
2. Follow the script template:

```bash
#!/usr/bin/env bash
#
# ##-feature-name.sh - Brief description
#
# Detailed description of what this script does
#

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[FEATURE]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[FEATURE]${NC} $*"; }
log_error() { echo -e "${RED}[FEATURE]${NC} $*"; }

# Main installation logic
install_feature() {
    log_info "Installing feature..."

    # Your code here

    log_info "Feature installed"
}

# Main function
main() {
    log_info "Starting feature installation..."
    echo ""

    install_feature

    echo ""
    log_info "Feature installation complete!"

    return 0
}

main "$@"
```

3. Add to `setup.sh` execution flow
4. Add to test suite
5. Update README.md
6. Update CHANGELOG.md
7. Regenerate checksums: `sha256sum setup.sh scripts/*.sh ... > checksums.txt`

### Adding Configuration Options

1. Add to `.env.sample` with documentation
2. Add default value in scripts
3. Add to README.md configuration section
4. Test with and without the option set

### Adding Tests

Add tests to `test-suite.sh`:

```bash
test_my_feature() {
    log_test "My feature works correctly"
    if [[ condition ]]; then
        log_pass "Feature test passed"
        return 0
    else
        log_fail "Feature test failed"
        return 1
    fi
}
```

Then add to main test execution flow.

## Security Considerations

When contributing, please consider:

1. **Never commit secrets** - No API keys, passwords, private keys
2. **Validate user input** - Sanitize and validate all inputs
3. **Use secure defaults** - Default to most secure option
4. **Follow least privilege** - Run with minimum required permissions
5. **Document security implications** - Explain risks and mitigations

### Security-Sensitive Changes

Changes affecting these require extra scrutiny:

- SSH configuration
- Firewall rules
- User permissions
- Secret handling
- Network exposure
- Docker security settings

## Commit Messages

Use clear, descriptive commit messages:

```
Good:
- Add support for custom SSH port configuration
- Fix firewall rule ordering issue
- Update Docker hardening for CVE-2024-1234

Bad:
- Update
- Fix bug
- WIP
```

Format:
```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `security`: Security improvements
- `perf`: Performance improvements

## Release Process

Maintainers will:

1. Update version in scripts
2. Update CHANGELOG.md
3. Create git tag
4. Regenerate checksums
5. Create GitHub release
6. Update README if needed

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion
- Reach out to maintainers

## Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Credited in release notes
- Appreciated by the community!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making this project better! 🎉
