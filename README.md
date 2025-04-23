# dap-logger

A Neovim plugin for logging Debug Adapter Protocol (DAP) variables to a file during debugging sessions.
Writes to log files with clear markers for breakpoints, making it easy to track variable states.

## Features

- Automatically log variables at each breakpoint
- Configure what variables to log (locals, globals, or both)
- Set verbose logging for specific variables
- Control the depth of object/dictionary expansion
- Enable/disable logging as needed
- Logs to files with clear breakpoint markers

## Requirements

- Neovim 0.7.0+
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "bearded-giant/dap-logger",
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  config = function()
    require("dap-logger").setup({
      -- optional configuration
      log_dir = vim.fn.expand("~/dap_logs"),
      max_depth = 3,
    })
  end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "bearded-giant/dap-logger",
  requires = {"mfussenegger/nvim-dap"},
  config = function()
    require("dap-logger").setup()
  end
}
```

## Configuration

```lua
require("dap-logger").setup({
  -- Directory where log files will be stored
  log_dir = vim.fn.expand("~/dap_logs"),
  
  -- Maximum depth for table expansion (default: 3)
  max_depth = 3,
  
  -- Whether to enable logging by default (false to minimize performance impact)
  auto_logging_enabled = false,
  
  -- What variables to log ("all", "local", or "global")
  log_scope = "all",
})
```

## Usage

Once configured, the plugin will automatically log variables when you hit a breakpoint in your debugging session.

### Commands

- `:DapLogVars` - Manually trigger variable logging
- `:DapLogEnable` - Enable automatic variable logging
- `:DapLogDisable` - Disable automatic variable logging
- `:DapLogAll` - Log both local and global variables
- `:DapLogLocal` - Log only local variables
- `:DapLogGlobal` - Log only global variables
- `:DapLogVerbose <varname>` - Add a variable to verbose logging (maximum depth)
- `:DapLogUnverbose <varname>` - Remove a variable from verbose logging
- `:DapLogDepth <number>` - Set the default depth for variable expansion

### Workflow

1. **Initial Setup**: Configure the plugin in your Neovim configuration with your preferred default settings.

2. **Pre-Debug Session**:
   - By default, automatic logging is disabled to avoid performance impacts
   - Enable it before or during a debug session when you need logging: `:DapLogEnable`
   - Set your logging scope if needed: `:DapLogLocal` or `:DapLogGlobal` or `:DapLogAll`

3. **During Debug Session**:
   - Enable/disable logging as needed with `:DapLogEnable` and `:DapLogDisable`
   - All configuration commands work in real-time during an active debug session
   - Use `:DapLogVars` to manually log at current position even if auto-logging is disabled
   - Add specific variables to verbose logging with `:DapLogVerbose <varname>` when you need deeper inspection

4. **Working with Log Files**:
   - A new log file is created for each debug session when the first breakpoint is hit
   - Log files are located in the configured `log_dir` with timestamps in their names
   - You can open these log files in Neovim or any text editor to analyze the variable state
   - Each breakpoint is clearly marked with file, line, and timestamp

Note: All configuration changes take effect immediately and will apply to subsequent breakpoints or manual logging calls.

## Log File Format

Logs are stored as text files in the configured `log_dir`. Each debugging session creates a new log file with a timestamp in the name format: `dap_vars_YYYYMMDD-HHMMSS.log`.

The log contains breakpoint markers with file location and timestamp, followed by the variable information in a readable format.

## License

MIT