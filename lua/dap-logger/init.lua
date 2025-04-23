-- This is the main module entry point
local M = {}

-- Forward to the logger module
function M.setup(opts)
  local logger = require("dap-logger.logger")
  return logger.setup(opts)
end

-- Expose the log_vars function
function M.log_vars(thread_id)
  local logger = require("dap-logger.logger")
  return logger.log_vars(thread_id)
end

return M