# PowerShell MCP Server

A comprehensive Model Context Protocol (MCP) server that enables Claude and other LLM applications to execute PowerShell commands, scripts, and perform system operations on Windows systems.

## 🛠️ **Available Tools**

### PowerShell Tools
- `sym-search-replace` - Performs search and replace operation agains content in your Sitecore environment
scripts


## 📋 **Prerequisites**

- **Windows** 10/11 or Windows Server 2016+
- **Node.js** 18.0.0 or higher
- **PowerShell** 5.1+ or PowerShell Core 7+
- **Sitecore** environment with SPE Remorting enabled


## Environmental variables

Before starting server, you must set below into your `.env` file:

```bash
# PowerShell Script Path
DEFAULT_SEARCH_REPLACE_SCRIPT=c:\Projects\Symposium\Custom-Sitecore-MCP-Server\examples\SearchReplace-SitecoreContent.ps1

# Sitecore SPE Remoting Configuration
SITECORE_CONNECTION_URI=https://xmcloudcm.localhost/
SITECORE_USERNAME=sitecore\speremoting
SPE_REMOTING_SECRET=YOUR_SPE_REMOTING_SECRET
```

## 🚀 **Quick Setup**

```bash
# Clone the repository
git clone https://github.com/Zont-Innovation/Custom-Sitecore-MCP-Server.git
cd Custom-Sitecore-MCP-Server

# Install dependencies
npm install

# Safely add to existing configuration
node recovery.js add-powershell

# Restart your MCP client (ie. Claude Desktop)
```

## 📖 **Usage Examples**

Ask Claude:
- *"Replace all field values 'SiteCore' to 'Sitecore' under /sitecore/content/Zont"*
- ... any other tool you may want to implement

## 🔧 **Commands**

### Server Commands
```bash
# Start the server
npm start

# Test components
npm test

# Run diagnostics
node diagnose.bat

# Start server directly
node src/server.js
```

## 📁 **Project Structure**

```
Custom-Sitecore-MCP-Server/
├── examples/               # Tool PowerShell script
├── src/
│   ├── server.js           # Main MCP server
│   ├── tools/              # Tool implementations
│   │   ├── sym-tools.js
│   └── utils/              # Utility modules
│       └── system-utils.js
├── scripts/                # Setup utilities
└── README.md
```

## ⚙️ **Claude Desktop Configuration**

The server uses this configuration:

```json
{
  "mcpServers": {
    "powershell": {
      "command": "node",
      "args": ["c:/Projects/Symposium/Custom-Sitecore-MCP-Server/src/server.js"],
      "env": {}
    }
  }
}
```

**Config location**: `%APPDATA%/Claude/claude_desktop_config.json`

## 🛡️ **Security Features**

- **Safe Execution**: Uses `-ExecutionPolicy Bypass` and `-NoProfile` for security
- **Input Validation**: All inputs validated with Zod schemas
- **Session Management**: PowerShell sessions properly disposed after use
- **Error Handling**: Comprehensive error handling prevents system issues
- **Logging**: All operations logged to stderr (not interfering with JSON-RPC)

## 🐛 **Troubleshooting**

### Server won't start
```bash
# Check Node.js version (need 18+)
node --version

# Check dependencies
npm install

# Test components
node test-server.js
```

### Claude Desktop integration issues
```bash
# Run setup again
setup.bat

# Check configuration
type "%APPDATA%/Claude/claude_desktop_config.json"

# Restart Claude Desktop completely
```

### PowerShell execution issues
```bash
# Test PowerShell
powershell -Command "Get-Date"

# Check execution policy
Get-ExecutionPolicy

# Run diagnostics
node diagnose.bat
```

