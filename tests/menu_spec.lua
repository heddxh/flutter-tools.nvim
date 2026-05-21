describe("menu", function()
  local menu
  local commands
  local dev_tools
  local original_ui_select
  local originals

  before_each(function()
    menu = require("flutter-tools.menu")
    commands = require("flutter-tools.commands")
    dev_tools = require("flutter-tools.dev_tools")
    original_ui_select = vim.ui.select
    originals = {
      is_running = commands.is_running,
      run = commands.run,
      reload = commands.reload,
      open_dev_tools = commands.open_dev_tools,
      dev_tools_is_running = dev_tools.is_running,
    }
  end)

  after_each(function()
    vim.ui.select = original_ui_select
    commands.is_running = originals.is_running
    commands.run = originals.run
    commands.reload = originals.reload
    commands.open_dev_tools = originals.open_dev_tools
    dev_tools.is_running = originals.dev_tools_is_running
    package.loaded["flutter-tools.menu"] = nil
  end)

  it("should use vim.ui.select to run commands", function()
    local run_count = 0

    commands.is_running = function() return false end
    commands.run = function() run_count = run_count + 1 end
    dev_tools.is_running = function() return false end

    vim.ui.select = function(items, opts, on_choice)
      assert.are.same("Flutter tools commands", opts.prompt)
      assert.are.same("Run", items[1].label)
      assert.are.same("Run • Start a flutter project", opts.format_item(items[1]))
      on_choice(items[1])
    end

    menu.select_commands()

    assert.are.same(1, run_count)
  end)

  it("should show running app commands in the picker", function()
    local reload_count = 0

    commands.is_running = function() return true end
    commands.reload = function() reload_count = reload_count + 1 end
    dev_tools.is_running = function() return true end

    vim.ui.select = function(items, _, on_choice)
      local labels = vim.tbl_map(function(item) return item.label end, items)
      assert.are.same("Hot reload", items[1].label)
      assert.is_true(vim.tbl_contains(labels, "Open Dev Tools"))
      on_choice(items[1])
    end

    menu.select_commands()

    assert.are.same(1, reload_count)
  end)
end)
