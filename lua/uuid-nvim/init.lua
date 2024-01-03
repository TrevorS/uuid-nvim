--- @class UuidNvimSetup
--- @field case string|nil the case of the UUID, either "lower" or "upper".
--- @field quotes string|nil the type of quotes to use, either "double", "single", or "none"
--- @field prefix string|nil the prefix to prepend to the UUID.
--- @field suffix string|nil the suffix to append to the UUID.
--- @field templates table|nil the templates used to generate UUIDs.
--- @field templates.v4 string|nil the template used to generate a v4 UUID.
--- @usage require("uuid-nvim").setup({ case = "upper", quotes = "single", suffix = "," })
local uuid_nvim_setup = {
  case = "lower",
  quotes = "double",
  insert = "after",
  prefix = "",
  suffix = "",
  templates = {
    v4 = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx",
  },
}

local M = {}
M.highlighting = false

math.randomseed(os.time())

--- Validate the configuration.
--- @param config UuidNvimSetup
--- @return nil
local function validate_config(config)
  local valid_cases = { lower = true, upper = true }
  if config.case and not valid_cases[config.case] then
    error("Invalid 'case' value. Must be 'lower' or 'upper'.")
  end

  local valid_quotes = { double = true, single = true, none = true }
  if config.quotes and not valid_quotes[config.quotes] then
    error("Invalid 'quotes' value. Must be 'double', 'single', or 'none'.")
  end

  local valid_insert_options = { before = true, after = true }
  if config.insert and not valid_insert_options[config.insert] then
    error("Invalid 'insert' value. Must be 'before' or 'after'.")
  end

  if config.prefix and type(config.prefix) ~= "string" then
    error("Invalid 'prefix' value. Must be a string.")
  end

  if config.suffix and type(config.suffix) ~= "string" then
    error("Invalid 'suffix' value. Must be a string.")
  end

  if config.templates and type(config.templates) ~= "table" then
    error("Invalid 'templates' value. Must be a table.")
  end
end

--- Set the configuration.
--- @param opts UuidNvimSetup configuration options
M.setup = function(opts)
  uuid_nvim_setup = vim.tbl_extend("force", uuid_nvim_setup, opts or {})

  validate_config(uuid_nvim_setup)

  --- add neovim commands
  vim.cmd([[command! UuidV4 lua require('uuid-nvim').insert_v4()]])
  vim.cmd(
    [[command! UuidToggleHighlighting lua require('uuid-nvim').toggle_highlighting()]]
  )
end

--- Get the current configuration.
--- @return UuidNvimSetup
M.get_setup = function()
  return uuid_nvim_setup
end

--- Generate a v4 UUID.
--- @param opts UuidNvimSetup configuration overrides
--- @return string
M.get_v4 = function(opts)
  opts = vim.tbl_extend("force", uuid_nvim_setup, opts or {})

  validate_config(opts)

  local uuid = string.gsub(opts.templates.v4, "[xy]", function(c)
    local r = math.random()

    -- if c == 'x', generate a random hex digit (0-15)
    -- if c == 'y', generate a random hex digit (8-11)
    local v = c == "x" and math.floor(r * 0x10) or (math.floor(r * 0x4) + 8)

    return string.format("%x", v)
  end)

  -- Convert to upper case if requested (always lower case by default)
  if opts.case == "upper" then
    uuid = string.upper(uuid)
  end

  if opts.quotes == "double" then
    uuid = '"' .. uuid .. '"'
  elseif opts.quotes == "single" then
    uuid = "'" .. uuid .. "'"
  end

  if opts.prefix ~= "" then
    uuid = opts.prefix .. uuid
  end

  if opts.suffix ~= "" then
    uuid = uuid .. opts.suffix
  end

  return uuid
end

--- Insert a v4 UUID at the current cursor position.
--- @param opts UuidNvimSetup configuration overrides
M.insert_v4 = function(opts)
  local uuid = M.get_v4(opts)
  local after = uuid_nvim_setup.insert == "after"

  vim.api.nvim_put({ uuid }, "c", after, true)
end

M.toggle_highlighting = function()
  if M.highlighting then
    -- Disable UUID highlighting
    vim.cmd([[syntax clear UuidV4]])
  else
    -- Enable UUID highlighting
    vim.cmd(
      [[syntax match UuidV4 /\v[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}/]]
    )
    vim.cmd([[highlight link UuidV4 Constant]])
  end

  M.highlighting = not M.highlighting
end

return M
