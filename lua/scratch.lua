local M = {}
local buf, win
local flag = false

local eval = function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    loadstring(table.concat(lines, '\n'))()
end

M.toggle = function()
    if flag then
        vim.api.nvim_win_close(win, true)
    else
        win = vim.api.nvim_open_win(buf, true, {
            relative='editor', border='rounded', style='minimal',
            row=0, col=math.ceil(vim.o.columns/2),
            height=math.ceil(vim.o.lines-3), width=math.ceil(vim.o.columns/2)
        })
    end
    flag = not flag
end

M.setup = function(opts)
    opts = opts or {}

    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'ft', 'lua')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')

    vim.keymap.set('n', '<leader>r', eval, {buffer=buf})

    vim.api.nvim_create_user_command('Scratch', M.toggle, {})
    -- vim.api.nvim_create_user_command('ScratchEval', eval, {})
end

return M
