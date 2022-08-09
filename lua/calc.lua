local M = {}
local Calc = {}
local pressed = {}
local ns = vim.api.nvim_create_namespace('calc')
local result = 0
local backup_cursor
local calc_opened = false
-- TODO: priority(1) enable flexible measurements
-- local lmap = {
    -- ['1'] = {line=5, col={0, 7}}, ['2'] = {line=5, col={8, 14}}, ['3'] = {line=5, col={15, 21}},
    -- ['4'] = {line=7, col={0, 7}}, ['5'] = {line=7, col={8, 14}}, ['6'] = {line=7, col={15, 21}},
    -- ['7'] = {line=9, col={0, 7}}, ['8'] = {line=9, col={8, 14}}, ['9'] = {line=9, col={15, 21}},
-- }

--> Helper funcs
local pad_left = function(str) return (" "):rep(21 - #str - 3)..str end
local map = function(key, fn) vim.keymap.set('n', key, fn, {buffer=Calc.buf, silent=true}) end
local add_line = function(text, line, hl)
    vim.api.nvim_buf_set_lines(Calc.buf, line, line, false, {text})
    vim.api.nvim_buf_add_highlight(Calc.buf, ns, hl, line, 0, -1)
end

function Calc:update_query()
    local query = table.concat(pressed, '')
    vim.api.nvim_buf_set_lines(Calc.buf, 1, 2, false, {pad_left(query)})
    vim.api.nvim_buf_add_highlight(Calc.buf, ns, 'CalcQuery', 1, 0, -1)
end
function Calc:update_result()
    vim.api.nvim_buf_set_lines(Calc.buf, 3, 4, false, {pad_left(tostring(result))})
    vim.api.nvim_buf_add_highlight(Calc.buf, ns, 'CalcResult', 3, 0, -1)
end

local add_key = function(k)
    table.insert(pressed, ("+-*/"):match(vim.pesc(k)) and ' '..k..' ' or k)
    Calc:update_query()

    --> TODO: highlight on press part
    -- local combo = lmap[k]
        -- vim.schedule(function()
    -- if combo then
        -- vim.api.nvim_buf_add_highlight(Calc.buf, ns, 'CalcPressed', combo.line, combo.col[1], combo.col[2])
        -- -- end)
        -- vim.defer_fn(function()
            -- -- vim.api.nvim_buf_clear_namespace(Calc.buf, id, combo.line, combo.line)
            -- -- TODO: clear_namespace instead of rehighlighting
            -- vim.api.nvim_buf_add_highlight(Calc.buf, ns, 'CalcKeyPad', combo.line, combo.col[1], combo.col[2])
        -- end, 500)
    -- end
end

local calculate = function()
    local result_line = vim.trim(vim.api.nvim_buf_get_lines(Calc.buf, 1, 2, false)[1])
    if result_line then
        result = vim.fn.eval(result_line)
        Calc:update_result()
    end
end

local clear = function()
    pressed = { "" }
    result = 0
    Calc:update_query()
    Calc:update_result()
end

local quit = function()
    vim.opt.guicursor = backup_cursor
    vim.api.nvim_win_close(Calc.win, true)
    vim.api.nvim_buf_clear_namespace(Calc.buf, ns, 0, -1)
end

function Calc:set_maps()
    for _, l in ipairs(vim.split("1234567890-+/*().", '')) do map(l, function() add_key(l) end) end
    for key, mapping in pairs({
        ["="] = calculate,
        ["<CR>"] = calculate,
        ["q"] = quit,
        ["<Esc>"] = quit,
        ["<leader>w"] = quit,
        ["c"] = clear,
        ["<BS>"] = function()
            table.remove(pressed, #pressed)
            Calc:update_query()
        end,
    }) do
        map(key, mapping)
    end
end

local start_calc = function()
    -- Calc.buf, Calc.win = utils:init(ns)
	Calc.buf = vim.api.nvim_create_buf(false, true)
    Calc.win = vim.api.nvim_open_win(Calc.buf, true, {
        style='minimal', relative='cursor', border='double',
        row=0, col=0, width=21, height=13
    })

    for i=0,10,2 do add_line("", i, 'None') end

    vim.api.nvim_buf_set_lines(Calc.buf, 1,  1,  false, {""})

    add_line("─────────────────────", 4, "Comment")
    add_line("   1      2      3   ", 5, "CalcKeyPad")
    add_line("   4      5      6   ", 7, "CalcKeyPad")
    add_line("   7      8      9   ", 9, "CalcKeyPad")
    add_line("   C      0      =   ", 11, "CalcKeyPad")

    Calc:update_query()
    Calc:update_result()
    backup_cursor = vim.opt.guicursor:get()
    vim.opt_local.guicursor = "n:block-Normal"

    --> Dont know if bold and italic works here
    vim.api.nvim_set_hl(ns, 'CalcQuery', { link="Constant", bold=true })
    vim.api.nvim_set_hl(ns, 'CalcResult', { link="Function", bold=true})
    vim.api.nvim_set_hl(ns, 'CalcKeyPad', { link="String", italic=true })
    vim.api.nvim_set_hl(ns, 'CalcPressed', { link="White" })

    Calc:set_maps()
    vim.api.nvim__set_hl_ns(ns)
end

M.toggle = function()
    (calc_opened and quit or start_calc)()
    calc_opened = not calc_opened
end

M.setup = function()
    vim.api.nvim_create_user_command('Calc', M.toggle, {})
    -- map('<leader>k', toggle)
end

return M
