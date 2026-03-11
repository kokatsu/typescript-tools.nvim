local uv = vim.loop
local Path = require "plenary.path"
local Process = require "typescript-tools.process"

---@param shim_dirs string[]
---@return table
local function make_process_stub(shim_dirs)
  return setmetatable({ shim_dirs = shim_dirs }, { __index = Process })
end

---@param base string
---@param name string
---@param target string
local function create_simple_shim(base, name, target)
  local nm = base .. "/node_modules"
  uv.fs_mkdir(nm, tonumber("755", 8))
  uv.fs_symlink(target, nm .. "/" .. name)
end

---@param base string
---@param scope string
---@param name string
---@param target string
local function create_scoped_shim(base, scope, name, target)
  local nm = base .. "/node_modules"
  uv.fs_mkdir(nm, tonumber("755", 8))
  uv.fs_mkdir(nm .. "/" .. scope, tonumber("755", 8))
  uv.fs_symlink(target, nm .. "/" .. scope .. "/" .. name)
end

describe("Process shim dir cleanup", function()
  it("cleans up simple (unscoped) plugin shim dir", function()
    local shim_dir = uv.fs_mkdtemp(Path:new(uv.os_tmpdir(), "tsplug_test_XXXXXX"):absolute())
    create_simple_shim(shim_dir, "my-plugin", "/tmp")

    local proc = make_process_stub { shim_dir }
    assert.is.truthy(uv.fs_stat(shim_dir))

    proc:cleanup_shim_dirs()

    assert.is.falsy(uv.fs_stat(shim_dir))
    assert.are.same({}, proc.shim_dirs)
  end)

  it("cleans up scoped package (@scope/name) shim dir", function()
    local shim_dir = uv.fs_mkdtemp(Path:new(uv.os_tmpdir(), "tsplug_test_XXXXXX"):absolute())
    create_scoped_shim(shim_dir, "@vue", "typescript-plugin", "/tmp")

    local proc = make_process_stub { shim_dir }
    assert.is.truthy(uv.fs_stat(shim_dir))

    proc:cleanup_shim_dirs()

    assert.is.falsy(uv.fs_stat(shim_dir))
    assert.are.same({}, proc.shim_dirs)
  end)

  it("is idempotent (safe to call twice)", function()
    local shim_dir = uv.fs_mkdtemp(Path:new(uv.os_tmpdir(), "tsplug_test_XXXXXX"):absolute())
    create_simple_shim(shim_dir, "my-plugin", "/tmp")

    local proc = make_process_stub { shim_dir }
    proc:cleanup_shim_dirs()
    proc:cleanup_shim_dirs()

    assert.is.falsy(uv.fs_stat(shim_dir))
    assert.are.same({}, proc.shim_dirs)
  end)

  it("handles empty shim_dirs gracefully", function()
    local proc = make_process_stub {}
    proc:cleanup_shim_dirs()
    assert.are.same({}, proc.shim_dirs)
  end)

  it("handles missing node_modules dir gracefully", function()
    local shim_dir = uv.fs_mkdtemp(Path:new(uv.os_tmpdir(), "tsplug_test_XXXXXX"):absolute())
    -- shim_dir exists but has no node_modules inside

    local proc = make_process_stub { shim_dir }
    proc:cleanup_shim_dirs()

    assert.is.falsy(uv.fs_stat(shim_dir))
    assert.are.same({}, proc.shim_dirs)
  end)
end)
