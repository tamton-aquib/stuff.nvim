local M = {}
local timer
-- TODO: add animation for split opens.
-- TODO: integrate with focus.nvim or split related plugins.
-- TODO: integrate with bbye and bufclose related plugins.
-- TODO: maybe use `win_get_config` instead of `resize`
-- PERF: structuring, theres code duplicattion all over.

M.create_float = function()
    vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
        style='minimal', border='single', relative='editor',
        row=5,col=5, height=10, width=50
    })
end

M.setup = function()
    local counter = 0
    timer = vim.loop.new_timer()
    local conf = vim.api.nvim_win_get_config(0)
    if conf.relative == "" then
        if #vim.api.nvim_list_wins() >= 2 then
            timer:start(100, 10, vim.schedule_wrap(function()
                if vim.api.nvim_win_get_width(0) == vim.o.columns then
                    local height = vim.api.nvim_win_get_height(0)
                    -- 3
                    if height <= vim.opt.winheight:get() then
                        timer:stop()
                        timer:close()
                        vim.api.nvim_win_close(0, true)
                        return
                    end
                    vim.cmd [[resize -1]]
                elseif vim.api.nvim_win_get_height(0) then
                    local width = vim.api.nvim_win_get_width(0)
                    -- 15
                    if width <= vim.opt.winwidth:get() then
                        timer:stop()
                        timer:close()
                        vim.api.nvim_win_close(0, true)
                        return
                    end
                    vim.cmd [[vertical resize -2]]

                end
            end))
        else
            if #vim.api.nvim_list_bufs() >= 2 then
                vim.api.nvim_buf_delete(0, {force=true})
            else
                vim.api.nvim_win_close(0, true)
            end
        end
    else
        timer:start(100, 10, vim.schedule_wrap(function()
            local width = vim.api.nvim_win_get_width(0)
            if width <= vim.opt.winwidth:get() then
                timer:stop()
                timer:close()
                vim.api.nvim_win_close(0, true)
                return
            else
                vim.cmd [[vertical resize -1]]
                vim.cmd [[resize -1]]
            end
        end))
    end
end

-- M.setup = function()
    -- for p,_ in pairs(package.loaded) do if p:match("^animate") then package.loaded[p]=nil end end
    -- close()
    -- vim.keymap.set('n', '<leader>r', close, {})
    -- vim.defer_fn(M.create_float, 2000)
-- end

return M
