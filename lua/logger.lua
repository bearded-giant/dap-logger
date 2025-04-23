local M = {}

-- Configuration options
M.config = {
  auto_logging_enabled = true,
  current_log_file = nil,
  log_dir = vim.fn.expand("~/dap_logs"),
  max_depth = 3,
  verbose_vars = {},  -- Variables to log at maximum depth
  log_scope = "all",  -- "all", "local", or "global"
}

-- Helper function to format values with depth control
function M.format_value(value, depth, var_name)
  -- Check if this variable should be logged verbosely (at max depth)
  local is_verbose = M.config.verbose_vars[var_name] ~= nil
  
  if type(value) ~= "table" or depth <= 0 and not is_verbose then
    return tostring(value)
  end
  
  local max_depth = is_verbose and 10 or M.config.max_depth
  local actual_depth = depth > max_depth and max_depth or depth
  
  local lines = {"{"}
  for k, v in pairs(value) do
    if type(v) == "table" and actual_depth > 1 then
      local nested = M.format_value(v, actual_depth - 1, var_name)
      lines[#lines + 1] = string.format("  %s = %s,", k, nested)
    else
      lines[#lines + 1] = string.format("  %s = %s,", k, tostring(v))
    end
  end
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n")
end

-- Setup auto variable logging to file using DAP evaluate requests
function M.log_vars(thread_id)
  if not M.config.auto_logging_enabled then
    return
  end
  
  local session = require("dap").session()
  if not session then
    return
  end
  
  -- first call: create log file
  if not M.config.current_log_file then
    local ts = os.date("%Y%m%d-%H%M%S")
    vim.fn.mkdir(M.config.log_dir, "p")
    M.config.current_log_file = string.format("%s/dap_vars_%s.log", M.config.log_dir, ts)
    local f = assert(io.open(M.config.current_log_file, "w"))
    f:write("DAP Variable Logging Started: " .. os.date() .. "\n\n")
    f:close()
    vim.notify("DAP logging → " .. M.config.current_log_file, vim.log.levels.INFO)
  end

  -- helper to append a block of text
  local function append_block(lines)
    local f = assert(io.open(M.config.current_log_file, "a"))
    for _, l in ipairs(lines) do
      f:write(l, "\n")
    end
    f:close()
  end

  -- mark the breakpoint
  local file = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  append_block({
    ("---- BREAK @ %s:%d  (%s) ----"):format(file, line, os.date("%H:%M:%S")),
    "",
  })

  -- ensure we know which frame to query
  thread_id = thread_id or session.current_thread or (session.stopped_threads and session.stopped_threads[1])
  local frame = session.current_frame and session.current_frame.id
  
  -- Get all local variables
  if M.config.log_scope == "all" or M.config.log_scope == "local" then
    session:request("scopes", {
      frameId = frame
    }, function(err, scopes)
      if err or not scopes then
        append_block({ "ERROR getting scopes:", err and err.message or "no response" })
        return
      end
      
      -- Loop through each scope (locals, globals, etc)
      for _, scope in ipairs(scopes.scopes or {}) do
        if scope.name == "Local" then
          session:request("variables", {
            variablesReference = scope.variablesReference
          }, function(vars_err, vars)
            if vars_err or not vars then
              append_block({ "ERROR getting local variables:", vars_err and vars_err.message or "no response" })
              return
            end
            
            append_block({ "==== LOCAL VARIABLES ====", "" })
            
            for _, var in ipairs(vars.variables or {}) do
              append_block({
                string.format("%s = %s", var.name, var.value),
                "",
              })
            end
            
            append_block({ "==== END LOCAL VARIABLES ====", "" })
          end)
        end
      end
    end)
  end
  
  -- Get all global variables
  if M.config.log_scope == "all" or M.config.log_scope == "global" then
    session:request("scopes", {
      frameId = frame
    }, function(err, scopes)
      if err or not scopes then
        append_block({ "ERROR getting scopes:", err and err.message or "no response" })
        return
      end
      
      -- Loop through each scope (locals, globals, etc)
      for _, scope in ipairs(scopes.scopes or {}) do
        if scope.name == "Global" then
          session:request("variables", {
            variablesReference = scope.variablesReference
          }, function(vars_err, vars)
            if vars_err or not vars then
              append_block({ "ERROR getting global variables:", vars_err and vars_err.message or "no response" })
              return
            end
            
            append_block({ "==== GLOBAL VARIABLES ====", "" })
            
            for _, var in ipairs(vars.variables or {}) do
              append_block({
                string.format("%s = %s", var.name, var.value),
                "",
              })
            end
            
            append_block({ "==== END GLOBAL VARIABLES ====", "" })
          end)
        end
      end
    end)
  end
  
  -- Log verbose variables if any are defined
  for var_name, _ in pairs(M.config.verbose_vars) do
    session:request("evaluate", {
      expression = var_name,
      context = "watch",
      frameId = frame,
    }, function(err, resp)
      if err or not resp then
        append_block({ 
          string.format("ERROR evaluating verbose var '%s':", var_name), 
          err and err.message or "no response" 
        })
        return
      end
      
      append_block({ 
        string.format("==== VERBOSE: %s ====", var_name),
        resp.result,
        string.format("==== END VERBOSE: %s ====", var_name),
        ""
      })
    end)
  end
end

-- Setup function to be called
function M.setup(opts)
  -- Apply user config if provided
  if opts then
    for k, v in pairs(opts) do
      M.config[k] = v
    end
  end

  -- Create convenience commands
  vim.api.nvim_create_user_command("DapLogVars", function()
    M.log_vars()
  end, {})

  vim.api.nvim_create_user_command("DapLogEnable", function()
    M.config.auto_logging_enabled = true
    vim.notify("DAP variable logging enabled", vim.log.levels.INFO)
  end, {})

  vim.api.nvim_create_user_command("DapLogDisable", function()
    M.config.auto_logging_enabled = false
    vim.notify("DAP variable logging disabled", vim.log.levels.INFO)
  end, {})
  
  -- New commands for controlling logging scope
  vim.api.nvim_create_user_command("DapLogAll", function()
    M.config.log_scope = "all"
    vim.notify("DAP logging all variables (local and global)", vim.log.levels.INFO)
  end, {})
  
  vim.api.nvim_create_user_command("DapLogLocal", function()
    M.config.log_scope = "local"
    vim.notify("DAP logging local variables only", vim.log.levels.INFO)
  end, {})
  
  vim.api.nvim_create_user_command("DapLogGlobal", function()
    M.config.log_scope = "global"
    vim.notify("DAP logging global variables only", vim.log.levels.INFO)
  end, {})
  
  -- Command to add a variable to verbose logging
  vim.api.nvim_create_user_command("DapLogVerbose", function(opts)
    if opts.args and opts.args ~= "" then
      M.config.verbose_vars[opts.args] = true
      vim.notify("Added " .. opts.args .. " to verbose logging", vim.log.levels.INFO)
    else
      vim.notify("Please provide a variable name", vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    complete = function(ArgLead, CmdLine, CursorPos)
      -- Could be enhanced to provide completion from current scope variables
      return {}
    end
  })
  
  -- Command to remove a variable from verbose logging
  vim.api.nvim_create_user_command("DapLogUnverbose", function(opts)
    if opts.args and opts.args ~= "" then
      if M.config.verbose_vars[opts.args] then
        M.config.verbose_vars[opts.args] = nil
        vim.notify("Removed " .. opts.args .. " from verbose logging", vim.log.levels.INFO)
      else
        vim.notify(opts.args .. " was not in verbose logging", vim.log.levels.WARN)
      end
    else
      -- List all verbose variables
      local vars = {}
      for v, _ in pairs(M.config.verbose_vars) do
        table.insert(vars, v)
      end
      if #vars > 0 then
        vim.notify("Verbose variables: " .. table.concat(vars, ", "), vim.log.levels.INFO)
      else
        vim.notify("No verbose variables defined", vim.log.levels.INFO)
      end
    end
  end, {
    nargs = "?",
    complete = function(ArgLead, CmdLine, CursorPos)
      local completion = {}
      for var, _ in pairs(M.config.verbose_vars) do
        if var:find(ArgLead, 1, true) == 1 then
          table.insert(completion, var)
        end
      end
      return completion
    end
  })
  
  -- Set the max depth for variable expansion
  vim.api.nvim_create_user_command("DapLogDepth", function(opts)
    local depth = tonumber(opts.args)
    if depth and depth > 0 then
      M.config.max_depth = depth
      vim.notify("Set DAP logging depth to " .. depth, vim.log.levels.INFO)
    else
      vim.notify("Please provide a positive number", vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
  })

  -- Hook into DAP stopped event to automatically log variables
  vim.api.nvim_create_autocmd("User", {
    pattern = "DapStopped",
    callback = function()
      M.log_vars()
    end,
  })

  return M
end

return M