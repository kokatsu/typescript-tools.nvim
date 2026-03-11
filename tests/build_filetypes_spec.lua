local ts = require "typescript-tools"
local initialize = require "typescript-tools.protocol.initialize"

describe("build_filetypes", function()
  local default_filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  }

  it("returns default filetypes with no plugins", function()
    local ft = ts.build_filetypes {}
    assert.are.same(default_filetypes, ft)
  end)

  it("returns default filetypes with string-only plugins", function()
    local ft = ts.build_filetypes { "typescript-styled-plugin" }
    assert.are.same(default_filetypes, ft)
  end)

  it("appends languages from table plugins", function()
    local ft = ts.build_filetypes {
      { name = "@vue/typescript-plugin", languages = { "vue" } },
    }
    assert.are.same(7, #ft)
    assert.are.same("vue", ft[7])
  end)

  it("does not duplicate languages already in defaults", function()
    local ft = ts.build_filetypes {
      { name = "some-plugin", languages = { "typescript" } },
    }
    assert.are.same(default_filetypes, ft)
  end)

  it("deduplicates same language across multiple plugins", function()
    local ft = ts.build_filetypes {
      { name = "plugin-a", languages = { "vue" } },
      { name = "plugin-b", languages = { "vue" } },
    }
    assert.are.same(7, #ft)
    assert.are.same("vue", ft[7])
  end)

  it("handles empty languages array", function()
    local ft = ts.build_filetypes {
      { name = "some-plugin", languages = {} },
    }
    assert.are.same(default_filetypes, ft)
  end)

  it("handles mixed string and table plugins", function()
    local ft = ts.build_filetypes {
      "typescript-styled-plugin",
      { name = "@vue/typescript-plugin", languages = { "vue" } },
    }
    assert.are.same(7, #ft)
    assert.are.same("vue", ft[7])
  end)

  it("preserves order (defaults first, then plugin languages)", function()
    local ft = ts.build_filetypes {
      { name = "plugin-a", languages = { "vue", "svelte" } },
    }
    assert.are.same(8, #ft)
    for i, expected in ipairs(default_filetypes) do
      assert.are.same(expected, ft[i])
    end
    assert.are.same("vue", ft[7])
    assert.are.same("svelte", ft[8])
  end)
end)

describe("get_extra_file_extensions", function()
  it("returns empty for no plugins", function()
    local ext = initialize.get_extra_file_extensions {}
    assert.are.same({}, ext)
  end)

  it("returns empty for string-only plugins", function()
    local ext = initialize.get_extra_file_extensions { "typescript-styled-plugin" }
    assert.are.same({}, ext)
  end)

  it("builds correct extensions from table plugins with languages", function()
    local ext = initialize.get_extra_file_extensions {
      { name = "@vue/typescript-plugin", languages = { "vue" } },
    }
    assert.are.same(1, #ext)
    assert.are.same({
      extension = ".vue",
      isMixedContent = true,
      scriptKind = 7,
    }, ext[1])
  end)

  it("strips leading dot from language string", function()
    local ext = initialize.get_extra_file_extensions {
      { name = "some-plugin", languages = { ".vue" } },
    }
    assert.are.same(".vue", ext[1].extension)
  end)

  it("uses correct scriptKind (SCRIPT_KIND_DEFERRED = 7)", function()
    local ext = initialize.get_extra_file_extensions {
      { name = "some-plugin", languages = { "vue" } },
    }
    assert.are.same(7, ext[1].scriptKind)
  end)

  it("handles multiple languages per plugin", function()
    local ext = initialize.get_extra_file_extensions {
      { name = "some-plugin", languages = { "vue", "svelte" } },
    }
    assert.are.same(2, #ext)
    assert.are.same(".vue", ext[1].extension)
    assert.are.same(".svelte", ext[2].extension)
  end)

  it("handles multiple plugins with languages", function()
    local ext = initialize.get_extra_file_extensions {
      { name = "plugin-a", languages = { "vue" } },
      { name = "plugin-b", languages = { "svelte" } },
    }
    assert.are.same(2, #ext)
    assert.are.same(".vue", ext[1].extension)
    assert.are.same(".svelte", ext[2].extension)
  end)
end)
