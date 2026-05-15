## 🤖 Setup Claude Code using a Single Command

### Linux (Ubuntu)

Run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/PriyanshuValiya/Claude-Code/main/linux-claude-setup.sh | bash
```

---

### Windows

1. Open **PowerShell as Administrator**
2. Run:

```powershell
irm https://raw.githubusercontent.com/PriyanshuValiya/Claude-Code/main/windows-claude-setup.ps1 | iex
```

If you get a script execution policy error, run this one-time setup command first:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then run the installation command again.

---

> **Note:** Review scripts before executing commands directly from the internet if you're using them in production or on important systems.
