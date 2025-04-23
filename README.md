# dap-logger

A Neovim plugin for logging Debug Adapter Protocol (DAP) variables to a file during debugging sessions.
Writes to JSON files with clear markers for breakpoints, making it easy to track variable states.

## Features

- Automatically log variables at each breakpoint
- Configure what variables to log (locals, globals, or both)
- Set verbose logging for specific variables
- Control the depth of object/dictionary expansion
- Enable/disable logging as needed
- Logs to JSON files with clear breakpoint markers

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

## Configuration

```lua
require("dap-logger").setup({
  -- Directory where log files will be stored
  log_dir = vim.fn.expand("~/dap_logs"),

  -- Maximum depth for table expansion (default: 3)
  max_depth = 3,

  -- Whether to enable logging by default
  auto_logging_enabled = true,

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

## Log File Format

Logs are stored as text files in the configured `log_dir`. Each debugging session creates a new log file with a timestamp in the name format: `dap_vars_YYYYMMDD-HHMMSS.log`.

The log contains breakpoint markers with file location and timestamp, followed by the variable information in a readable format.

## License

MIT
