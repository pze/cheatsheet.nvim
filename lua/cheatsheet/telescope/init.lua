-- local actions = require('telescope.actions')
-- local actions_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local pickers = require('telescope.pickers')

local config = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')

local cheatsheet = require('cheatsheet')
-- local utils = require('cheatsheet.utils')

local M = {}

-- Filter through cheats using Telescope
-- Highlight groups:
--     cheatMetadataSection, cheatDescription, cheatcode
-- Mappings:
--     <C-E> - Edit user cheatsheet in new buffer
--     <C-Y> - Yank the cheatcode
M.pick_cheat = function(telescope_opts, opts)
  telescope_opts = telescope_opts or {}

  pickers.new(
    telescope_opts, {
    prompt_title = 'Cheat',
    finder = finders.new_table {
      results = cheatsheet.get_cheats(opts),
      entry_maker = function(entry)
        local section_width = 10

        -- NOTE: the width calculating logic is not exact, but approx enough
        local displayer = entry_display.create {
          separator = " ▏",
          items = {
            { width = section_width }, -- section
            {
              remaining = true,
            }, -- description
          },
        }

        local function make_display(ent)
          return displayer {
            -- text, highlight group
            { ent.value.section, "cheatMetadataSection" },
            { ent.value.description, "cheatDescription" },
          }
        end

        local tags = table.concat(entry.tags, ' ')

        return {
          value = entry,
          -- generate the string that user sees as an item
          display = make_display,
          -- queries are matched against ordinal
          ordinal = string.format(
            '%s %s %s %s', entry.section, entry.description,
            tags, entry.cheatcode
          ),
        }
      end,
    },
    previewer = previewers.new({
      preview_fn = function(_, entry, status)
        local preview_win = status.preview_win
        local bufnr = vim.api.nvim_win_get_buf(preview_win)
        local text = { entry.value.cheatcode or "no code" }
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, text)
      end,
      title = function(_)
        return "Code"
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      local mappings = require('cheatsheet.config').options.telescope_mappings
      for keybind, action in pairs(mappings) do
        map('i', keybind, function() action(prompt_bufnr) end)
      end

      return true
    end,
    sorter = config.generic_sorter(telescope_opts),
  }
  ):find()
end

return M
