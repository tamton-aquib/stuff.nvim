local M = {}
local buf, win
local loaded = false

local eval = function() loadstring(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'))() end

M.toggle = function()
    if not loaded or not vim.api.nvim_win_is_valid(win) then
        if not buf or not vim.api.nvim_buf_is_valid(buf) then
            buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_option(buf, 'ft', 'lua')
            vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
            vim.keymap.set('n', '<leader>r', eval, {buffer=buf})
        end

        win = vim.api.nvim_open_win(buf, true, {
            relative='editor', border='rounded', style='minimal',
            row=0, col=math.ceil(vim.o.columns/2),
            height=math.ceil(vim.o.lines-3), width=math.ceil(vim.o.columns/2)
        })
    else
        vim.api.nvim_win_hide(win)
    end

    loaded = not loaded
end

return M
