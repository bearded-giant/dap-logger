-- Ensure the plugin loads early and properly registers commands
if vim.g.loaded_dap_logger then
  return
end

vim.g.loaded_dap_logger = true

-- Load the plugin with auto-logging disabled by default
require("dap-logger").setup({
  auto_logging_enabled = false  -- Ensures logging is opt-in
})