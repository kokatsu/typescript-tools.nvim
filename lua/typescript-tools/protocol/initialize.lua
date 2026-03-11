local c = require "typescript-tools.protocol.constants"
local make_capabilities = require "typescript-tools.capabilities"
local plugin_config = require "typescript-tools.config"
local TsserverProvider = require "typescript-tools.tsserver_provider"

local M = {}

local default_compiler_options = {
  module = "ESNext",
  target = "ES2020",
  jsx = "react",
  allowJs = true,
  strictNullChecks = true,
  sourceMap = true,
  allowSyntheticDefaultImports = true,
  allowNonTsExtensions = true,
  resolveJsonModule = true,
  moduleResolution = "Node",
  strictFunctionTypes = true,
}

-- Build extraFileExtensions from plugin languages config.
-- This tells tsserver that files like .vue should be handled by plugins
-- rather than parsed as plain TypeScript.
-- TypeScript ScriptKind.Deferred (handled by plugin)
local SCRIPT_KIND_DEFERRED = 7

---@param plugins (string|{name: string, location?: string, languages?: string[]})[]|nil
---@return table[]
function M.get_extra_file_extensions(plugins)
  local extensions = {}
  local seen = {}
  for _, plugin in ipairs(plugins or {}) do
    if type(plugin) == "table" and plugin.languages then
      for _, lang in ipairs(plugin.languages) do
        local ext = lang:gsub("^%.", "")
        if not seen[ext] then
          seen[ext] = true
          table.insert(extensions, {
            extension = "." .. ext,
            isMixedContent = true,
            scriptKind = SCRIPT_KIND_DEFERRED,
          })
        end
      end
    end
  end
  return extensions
end

local function get_configuration()
  return {
    command = c.CommandTypes.Configure,
    arguments = {
      hostInfo = "neovim",
      preferences = {
        providePrefixAndSuffixTextForRename = true,
        allowRenameOfImportPath = true,
        includePackageJsonAutoImports = "auto",
      },
      extraFileExtensions = M.get_extra_file_extensions(plugin_config.tsserver_plugins),
      watchOptions = {},
    },
  }
end

local function read_compiler_options()
  local config_path = TsserverProvider.get_instance():get_tsconfig_path()

  if not config_path then
    return default_compiler_options
  end

  local ok, config = pcall(vim.json.decode, config_path:read(), { luanil = { object = true } })

  if ok and config then
    local compiler_options = config.compilerOptions or {}
    local ret = {}

    for k, v in pairs(default_compiler_options) do
      local value = compiler_options[k]

      if value ~= nil and v ~= value then
        ret[k] = value
      end
    end

    return ret
  end

  return default_compiler_options
end

---@return TsserverRequest
local function get_compiler_options()
  local opts = read_compiler_options()

  return {
    command = c.CommandTypes.CompilerOptionsForInferredProjects,
    arguments = {
      options = vim.tbl_extend("force", {}, default_compiler_options, opts),
    },
  }
end

---@type TsserverProtocolHandler
function M.handler(request, response)
  request(get_configuration())
  -- tssever protocol reference:
  -- https://github.com/microsoft/TypeScript/blob/2b7d517907de7026c83e54ceab59a3926877a5d3/src/server/protocol.ts#L1914
  request(get_compiler_options())
  -- INFO: skip first response
  coroutine.yield()

  response { capabilities = make_capabilities() }
end

return M
