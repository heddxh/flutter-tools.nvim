local utils = require("flutter-tools.utils")

describe("commands", function()
  local commands
  before_each(function() commands = require("flutter-tools.commands") end)
  after_each(function()
    commands = nil
    package.loaded["flutter-tools.commands"] = nil
  end)

  it("should open devtools directly when profiler url is available", function()
    local send_count = 0
    local open_count = 0
    local dev_tools = require("flutter-tools.dev_tools")
    local original_get_profiler_url = dev_tools.get_profiler_url
    local original_open_dev_tools = dev_tools.open_dev_tools

    commands.__set_runner({
      is_running = function() return true end,
      send = function() send_count = send_count + 1 end,
    })
    dev_tools.get_profiler_url = function() return "http://127.0.0.1:9100/?uri=ws://127.0.0.1:1234/ws" end
    dev_tools.open_dev_tools = function() open_count = open_count + 1 end

    commands.open_dev_tools()

    assert.are.same(1, open_count)
    assert.are.same(0, send_count)

    dev_tools.get_profiler_url = original_get_profiler_url
    dev_tools.open_dev_tools = original_open_dev_tools
  end)

  it("should fallback to runner when no profiler url is available", function()
    local send_count = 0
    local open_count = 0
    local dev_tools = require("flutter-tools.dev_tools")
    local original_get_profiler_url = dev_tools.get_profiler_url
    local original_open_dev_tools = dev_tools.open_dev_tools

    commands.__set_runner({
      is_running = function() return true end,
      send = function(_, cmd)
        send_count = send_count + 1
        assert.are.same("open_dev_tools", cmd)
      end,
    })
    dev_tools.get_profiler_url = function() return nil, false end
    dev_tools.open_dev_tools = function() open_count = open_count + 1 end

    commands.open_dev_tools()

    assert.are.same(0, open_count)
    assert.are.same(1, send_count)

    dev_tools.get_profiler_url = original_get_profiler_url
    dev_tools.open_dev_tools = original_open_dev_tools
  end)

  it(
    "should add project config options correctly",
    function()
      assert.are.same(
        { "run", "--flavor", "Production" },
        commands.__get_run_args({}, { flavor = "Production" })
      )
    end
  )

  it(
    "should add 'dart_defines' options correctly",
    function()
      assert.are.same(
        { "run", "--flavor", "Production", "--dart-define", "ENV=prod" },
        commands.__get_run_args({}, { flavor = "Production", dart_define = { ENV = "prod" } })
      )
    end
  )

  it(
    "should add 'target' config option correctly",
    function()
      assert.are.same(
        { "run", "--target", "lib/main_dev.dart" },
        commands.__get_run_args({}, { target = "lib/main_dev.dart" })
      )
    end
  )

  it(
    "should add 'dart-define-from-file' config option correctly",
    function()
      assert.are.same(
        { "run", "--dart-define-from-file", "config.json" },
        commands.__get_run_args({}, { dart_define_from_file = "config.json" })
      )
    end
  )

  it("should add multiple dart_defines", function()
    local args = commands.__get_run_args({}, {
      flavor = "Production",
      dart_define = { ENV = "prod", KEY = "VALUE" },
    })
    local result = utils.fold(function(acc, v)
      acc[v] = acc[v] and acc[v] + 1 or 1
      return acc
    end, args, {})

    assert.are.same(result, {
      ["run"] = 1,
      ["--flavor"] = 1,
      ["Production"] = 1,
      ["--dart-define"] = 2,
      ["ENV=prod"] = 1,
      ["KEY=VALUE"] = 1,
    })
  end)

  it(
    "should add '--profile' config option correctly",
    function()
      assert.are.same(
        { "run", "--profile" },
        commands.__get_run_args({}, { flutter_mode = "profile" })
      )
    end
  )

  it(
    "should add '--release' config option correctly",
    function()
      assert.are.same(
        { "run", "--release" },
        commands.__get_run_args({}, { flutter_mode = "release" })
      )
    end
  )
end)
