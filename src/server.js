import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { PowerShell } from 'node-powershell';

// Import tool modules
import { registerSym } from './tools/sym-tools.js';

// CRITICAL: Use stderr for logging (stdout reserved for JSON-RPC)
const log = (message) => {
  console.error(`[PowerShell MCP] ${message}`);
};

log('Starting PowerShell MCP Server v1.1.1 - Symposium Edition...');

// Create an MCP server instance
const server = new McpServer({
  name: 'powershell-mcp-server',
  version: '1.1.1',
});

// Register Symposium tools only
log('Registering Symposium migration tools...');
registerSym(server);

// Set up transport and start listening
const transport = new StdioServerTransport();
await server.connect(transport);

// log('Symposium MCP Server is running and ready for Claude Desktop!');
log('Available tools: Symposium migration tools');
log('  - sym-search-replace');

// Error handling
process.on('uncaughtException', (error) => {
  log(`Uncaught exception: ${error.message}`);
});

process.on('unhandledRejection', (reason) => {
  log(`Unhandled rejection: ${reason}`);
});
