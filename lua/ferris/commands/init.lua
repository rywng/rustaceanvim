---@mod ferris.commands

local config = require('ferris.config.internal')

---@class FerrisCommands
local M = {}

local rust_lsp_cmd_name = 'RustLsp'

---@type { string: fun(args: string[]) }
local command_tbl = {
  codeAction = function(_)
    require('ferris.commands.code_action_group')()
  end,
  crateGraph = function(args)
    require('ferris.commands.crate_graph')(args)
  end,
  debuggables = function(args)
    if #args == 0 then
      require('ferris.commands.debuggables')()
    elseif #args == 1 and args[1] == 'last' then
      require('ferris.cached_commands').execute_last_debuggable()
    else
      vim.notify('debuggables: unexpected arguments: ' .. vim.inspect(args), vim.log.levels.ERROR)
    end
  end,
  expandMacro = function(_)
    require('ferris.commands.expand_macro')()
  end,
  externalDocs = function(_)
    require('ferris.commands.external_docs')()
  end,
  hover = function(args)
    if #args < 2 then
      vim.notify("hover: called without 'actions' or 'range'", vim.log.levels.ERROR)
      return
    end
    local subcmd = args[1]
    if subcmd == 'actions' then
      require('ferris.hover_actions').hover_actions()
    elseif subcmd == 'range' then
      require('ferris.commands.hover_range')()
    else
      vim.notify('hover: unknown subcommand: ' .. subcmd .. " expected 'actions' or 'range'", vim.log.levels.ERROR)
    end
  end,
  runnables = function(args)
    if #args == 0 then
      require('ferris.runnables').runnables()
    elseif #args == 1 and args[1] == 'last' then
      require('ferris.cached_commands').execute_last_runnable()
    else
      vim.notify('runnables: unexpected arguments: ' .. vim.inspect(args), vim.log.levels.ERROR)
    end
  end,
  joinLines = function(_)
    require('ferris.commands.join_lines')()
  end,
  moveItem = function(args)
    if #args < 1 then
      vim.notify("moveItem: called without 'up' or 'down'", vim.log.levels.ERROR)
      return
    end
    if args[1] == 'down' then
      require('ferris.commands.move_item')()
    elseif args[1] == 'up' then
      require('ferris.commands.move_item')(true)
    else
      vim.notify(
        'moveItem: unexpected argument: ' .. vim.inspect(args) .. " expected 'up' or 'down'",
        vim.log.levels.ERROR
      )
    end
  end,
  openCargo = function(_)
    require('ferris.commands.open_cargo_toml')()
  end,
  parentModule = function(_)
    require('ferris.commands.parent_module')()
  end,
  ssr = function(args)
    if #args < 1 then
      vim.notify('ssr: called without a query', vim.log.levels.ERROR)
      return
    end
    local query = args[1]
    require('ferris.commands.ssr')(query)
  end,
  reloadWorkspace = function()
    require('ferris.commands.workspace_refresh')()
  end,
  syntaxTree = function()
    require('ferris.commands.syntax_tree')()
  end,
  flyCheck = function()
    require('ferris.commands.fly_check')()
  end,
}

---@param opts table
---@see vim.api.nvim_create_user_command
local function rust_lsp(opts)
  local fargs = opts.fargs
  local cmd = fargs[1]
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local command = command_tbl[cmd]
  if not command then
    vim.notify(rust_lsp_cmd_name .. ': Unknown subcommand: ' .. cmd, vim.log.levels.ERROR)
    return
  end
  command(args)
end

---Create the `:RustLsp` command
function M.create_rust_lsp_command()
  vim.api.nvim_create_user_command(rust_lsp_cmd_name, rust_lsp, {
    nargs = '+',
    desc = 'Interacts with the rust-analyzer LSP client',
    complete = function(arg_lead, cmdline, _)
      local commands = vim.tbl_keys(command_tbl)
      -- special case: crateGraph comes with graphviz backend completions
      if cmdline:match('^' .. rust_lsp_cmd_name .. ' cr%s+%w*$') then
        local backends = config.tools.crate_graph.enabled_graphviz_backends or {}
        return vim.tbl_map(function(backend)
          return 'crateGraph ' .. backend
        end, backends)
      end
      if cmdline:match('^' .. rust_lsp_cmd_name .. '%s+%w*$') then
        return vim
          .iter(commands)
          :filter(function(command)
            return command:find(arg_lead) ~= nil
          end)
          :totable()
      end
    end,
  })
end

--- Delete the `:RustLsp` command
function M.delete_rust_lsp_command()
  vim.api.nvim_del_user_command(rust_lsp_cmd_name)
end

return M