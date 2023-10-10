-- FIX: Gets stuck after sometime.
local M = {}

M.rain = function()
    local ns = vim.api.nvim_create_namespace("rain")
    local N = 5
    local CHAR = "" -- "" -- "|" -- "💧"

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, false, { relative='editor', style='minimal', border='none', width=vim.o.columns, height=vim.o.lines, row=0, col=0 })
    vim.api.nvim_buf_set_lines(buf, 0, vim.o.lines, false, (function() local stuff = {} for _=1, vim.o.lines do table.insert(stuff, (" "):rep(vim.o.columns)) end return stuff end)())
    vim.cmd [[hi NormalFloat guibg=none]]
    vim.wo[win].winblend = 100

    local counter = 0
    local gtimer = vim.loop.new_timer()
    gtimer:start(1000, 500, vim.schedule_wrap(function()
        -- local ids = vim.api.nvim_buf_get_extmarks()
        -- vim.api.nvim_buf_del_extmark(buf, ns, id)
        local numbers = {}
        for _=1, N do
            local n = math.random(1, vim.o.columns)
            table.insert(numbers, { c=n, l=0 })
        end

        for _, d in ipairs(numbers) do
            local id = vim.api.nvim_buf_set_extmark(buf, ns, d.l, d.c, {virt_text={{CHAR, "Identifier"}}, virt_text_pos="overlay"})

            -- TODO: should these go above?
            local timer = vim.loop.new_timer()
            counter = counter + 1
            timer:start(0, 35, vim.schedule_wrap(function()
                if d.l >= vim.o.lines or d.c >= vim.o.columns then
                    timer:close()
                    timer:stop()
                    -- vim.api.nvim_buf_del_extmark(buf, ns, id)
                    return
                end
                vim.api.nvim_buf_set_extmark(buf, ns, d.l, d.c, { virt_text={{CHAR, "Identifier"}}, virt_text_pos="overlay", id=id })
                d.l = d.l + 1
                d.c = d.c + 1
            end))
        end
    end))
end

return M
