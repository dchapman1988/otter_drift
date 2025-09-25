# 🔒 Security Checklist

## ✅ **Pre-Commit Security Checks**

Before committing any code, ensure:

### **API Keys & Credentials**
- [ ] No API keys hardcoded in source code
- [ ] No secret keys in configuration files
- [ ] No credentials in comments or documentation
- [ ] All sensitive data uses `--dart-define` or environment variables
- [ ] No `.env` files committed (they're in `.gitignore`)

### **Files to Check**
- [ ] `lib/services/security_config.dart` - Only contains validation logic, no actual keys
- [ ] `lib/services/config.dart` - Only contains environment variable references
- [ ] `build_scripts/` - Only example scripts, no real credentials
- [ ] `.vscode/launch.json` - Only example configurations
- [ ] Any new configuration files

### **Build Scripts**
- [ ] `run_dev.sh` is in `.gitignore` (contains real API key)
- [ ] `build_scripts/build_example.sh` is safe to commit (contains placeholders)
- [ ] No real credentials in any shell scripts

## 🚨 **What's Protected by .gitignore**

The updated `.gitignore` now protects:

### **API Keys & Secrets**
```
*.key, *.pem, *.p12, *.pfx, *.jks, *.keystore
api_keys.txt, secrets.txt, credentials.txt
.env, .env.local, .env.development, .env.staging, .env.production
```

### **Development Scripts**
```
run_dev.sh (contains real API key)
dev_scripts/
build_scripts/*.sh (except build_example.sh)
```

### **Configuration Files**
```
config/secrets.dart
config/api_keys.dart
config/credentials.dart
lib/config/secrets.dart
lib/config/api_keys.dart
lib/config/credentials.dart
```

### **Certificate Files**
```
*.crt, *.cer, *.der, *.p7b, *.p7c, *.spc
certificates/, certs/
```

### **Log Files**
```
*.log, logs/, *.log.*
```

### **IDE Files**
```
.vscode/settings.json, .vscode/launch.json
.idea/workspace.xml, .idea/encodings.xml, etc.
```

## 🔍 **How to Verify Security**

### **Check for Sensitive Data**
```bash
# Search for potential API keys in your codebase
grep -r "78f28fff" . --exclude-dir=.git --exclude-dir=build
grep -r "api_key" . --exclude-dir=.git --exclude-dir=build
grep -r "secret" . --exclude-dir=.git --exclude-dir=build
```

### **Check Git Status**
```bash
# Ensure no sensitive files are staged
git status
git diff --cached
```

### **Test Build Without Keys**
```bash
# This should fail (proving keys aren't hardcoded)
flutter run
```

## 📋 **Security Best Practices**

### **✅ DO**
- Use `--dart-define=API_KEY=your_key` for builds
- Keep example scripts with placeholder values
- Use environment variables for different environments
- Regularly audit your codebase for hardcoded secrets
- Use the security checklist before each commit

### **❌ DON'T**
- Hardcode API keys in source code
- Commit `.env` files with real credentials
- Put real API keys in example scripts
- Store secrets in version control
- Share API keys in chat/email/documentation

## 🚀 **Safe Development Workflow**

1. **Development**: Use `./run_dev.sh` or VS Code launch config
2. **Staging**: Use `--dart-define=API_KEY=staging_key`
3. **Production**: Use `--dart-define=API_KEY=production_key`
4. **Never**: Hardcode keys in source code

## 🔧 **Environment Management**

### **Development**
```bash
flutter run --dart-define=API_KEY=your_development_api_key_here
```

### **Staging**
```bash
flutter build apk --dart-define=API_KEY=staging_api_key_here
```

### **Production**
```bash
flutter build apk --dart-define=API_KEY=production_api_key_here
```

## 🆘 **If You Accidentally Commit Secrets**

1. **Immediately revoke the exposed API key**
2. **Remove from git history**:
   ```bash
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch path/to/file' --prune-empty --tag-name-filter cat -- --all
   ```
3. **Force push** (if already pushed to remote):
   ```bash
   git push origin --force --all
   ```
4. **Generate new API key**
5. **Update all environments with new key**

## 📞 **Security Contacts**

- **API Key Issues**: Contact your backend team
- **Security Questions**: Review this checklist and documentation
- **Emergency**: Revoke keys immediately and generate new ones

---

**Remember**: Security is everyone's responsibility. When in doubt, ask before committing!
