import { PowerShell } from 'node-powershell';
import { z } from 'zod';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

// Load environment variables from .env file
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.resolve(__dirname, '..', '..', '.env');
dotenv.config({ path: envPath });

/**
 * Helper function to mask SPE Remoting Secret
 * Shows first 6 characters, masks the rest
 */
function maskSecret(secret) {
  if (!secret) return 'N/A';
  if (secret.length <= 6) return secret;
  return secret.substring(0, 6) + '*'.repeat(Math.min(secret.length - 6, 10));
}



/**
 * Helper function to decode Base64 remotingConfig for logging
 */
function decodeRemotingConfig(base64Config) {
  try {
    return Buffer.from(base64Config, 'base64').toString('utf8');
  } catch (error) {
    return base64Config; // Return as-is if decode fails
  }
}

/**
 * Create and configure a PowerShell instance
 */
function createPowerShellInstance() {
  return new PowerShell({
    executableOptions: {
      '-ExecutionPolicy': 'Bypass',
      '-NoProfile': true,
    }
  });
}

/**
 * Execute a PowerShell command safely
 */
async function executePowerShellCommand(command, workingDirectory = null) {
  const ps = createPowerShellInstance();

  try {
    if (workingDirectory) {
      await ps.invoke(`Set-Location -Path "${workingDirectory}"`);
    }

    const result = await ps.invoke(command);
    return {
      success: true,
      output: result.raw || 'Command executed successfully with no output.',
      workingDirectory: workingDirectory || 'Default'
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      workingDirectory: workingDirectory || 'Default'
    };
  } finally {
    await ps.dispose();
  }
}

/**
 * Register all Symposium tools
 */
export function registerSym(server) {

  // Load configuration from environment variables
  const DEFAULT_SEARCH_REPLACE_SCRIPT = process.env.DEFAULT_SEARCH_REPLACE_SCRIPT || 'c:\\Projects\\Symposium\\Custom-Sitecore-MCP-Server\\examples\\SearchReplace-SitecoreContent.ps1';

  // Build remoting configuration from environment variables and encode to base64
  const remotingConfigObj = {
    connectionUri: process.env.SITECORE_CONNECTION_URI || 'https://xmcloudcm.localhost/',
    username: process.env.SITECORE_USERNAME || 'sitecore\\speremoting',
    SPE_REMOTING_SECRET: process.env.SPE_REMOTING_SECRET || ''
  };
  const DEFAULT_REMOTING_CONFIG = Buffer.from(JSON.stringify(remotingConfigObj)).toString('base64');

  // ============================================================================
  // SEARCH AND REPLACE TOOL
  // ============================================================================
  server.tool(
    'sym-search-replace',
    'Search and replace text in Sitecore content items. Standalone tool that does not require sym-initialize.',
    {
      FindText: z.string().describe('Text to find and replace'),
      ReplaceText: z.string().describe('Text to replace with'),
      ScopePaths: z.string().describe('Root node path under which to perform search and replace (e.g., /sitecore/content/Home)'),
      remotingConfig: z.string().optional().describe('Remoting configuration Base64 string for XM Cloud connection (uses default if not provided: https://xmcloudcm.localhost/ with sitecore\\speremoting)')
    },
    async ({ FindText, ReplaceText, ScopePaths, remotingConfig }) => {

      // Use provided remotingConfig or default
      const finalRemotingConfig = remotingConfig || DEFAULT_REMOTING_CONFIG;

      console.error('== SYM - Search and Replace ==');
      console.error(`Script: ${DEFAULT_SEARCH_REPLACE_SCRIPT}`);
      console.error(`Find Text: ${FindText}`);
      console.error(`Replace Text: ${ReplaceText}`);
      console.error(`Scope Paths: ${ScopePaths}`);
      console.error(`Remoting Config: ${remotingConfig ? '[User provided]' : '[Using default]'} - length: ${finalRemotingConfig.length}`);

      try {
        // Build the command with required parameters
        let command = `& "${DEFAULT_SEARCH_REPLACE_SCRIPT}" -FindText "${FindText}" -ReplaceText "${ReplaceText}" -ScopePaths "${ScopePaths}"`;
        command += ` -remotingConfig '${finalRemotingConfig}'`;

        console.error(`Executing command with search and replace parameters`);

        const result = await executePowerShellCommand(command, null);

        if (result.success) {
          return {
            content: [{
              type: 'text',
              text: `✅ **Search and Replace Completed Successfully**

**Find Text:** ${FindText}
**Replace Text:** ${ReplaceText}
**Scope Paths:** ${ScopePaths}

**Output:**
\`\`\`
${result.output}
\`\`\``
            }]
          };
        } else {
          return {
            content: [{
              type: 'text',
              text: `❌ **Search and Replace Failed**

**Find Text:** ${FindText}
**Replace Text:** ${ReplaceText}
**Scope Paths:** ${ScopePaths}
**Error:** ${result.error}

Please check your configuration and try again.`
            }],
            isError: true
          };
        }
      } catch (error) {
        return {
          content: [{
            type: 'text',
            text: `💥 Unexpected error executing PowerShell script: ${error.message}`
          }],
          isError: true
        };
      }
    }
  );

}
