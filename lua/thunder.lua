-- Similar to thunderclient in vscode (no features yet.) (Inspired from rest.nvim)
-- TODO: Just POC of winbar as clickable tabs, info
local M = {}
M.current_pane_index = 1

local winbar = [[%1@v:lua.BCall@%#ResponseHighlight#Response%X%#Normal# %2@v:lua.BCall@%#HeaderHighlight#Header%X%#Normal# %3@v:lua.BCall@%#CookiesHighlight#Cookies%X%#Normal#%=]]
local buf --, win

M.cmap = {
    [1] = { name="Response", ft="json", contents={ "Fetching..." } },
    [2] = { name="Header", ft="yaml"  , contents={ "Fetching..." } },
    [3] = { name="Cookies", ft="dosini" , contents={ "Fetching..." } },
}

local set_lines_and_stuff = function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, M.cmap[M.current_pane_index].contents)
    vim.cmd("setf " .. M.cmap[M.current_pane_index].ft)
end

local set_winbar = function()
    vim.wo.winbar = winbar ..
    "%#ThunderCode#"..(M.status.." ok  " or "") ..
    "%#ThunderSize#"..(M.length.." bytes  " or "") ..
    "%#ThunderTime#"..(M.time.." s" or "")
end

local call_for_help = function()
    local request_data = {}
    local request_headers = {}

    local pattern = "^([A-Z]+)%s*(.*)$"
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local append_to_headers = true

    local method, url = lines[1]:match(pattern)
    table.remove(lines, 1)
    for _, line in ipairs(lines) do
        if not vim.startswith(line, "#") then
            if line == "" then
                append_to_headers = false
            else
                if append_to_headers then
                    table.insert(request_headers, line)
                else
                    table.insert(request_data, line)
                end
            end
        end
    end

    local start_time = vim.fn.reltimefloat(vim.fn.reltime())
    local command = { "curl", "-sL", "-i", url, "-X", method }
    if request_data then
        table.insert(command, "-d")
        table.insert(command, table.concat(request_data))
    end
    if request_headers then
        table.insert(command, "-H")
        table.insert(command, table.concat(request_headers))
    end

    vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, res)
            if not res or res == "" or (#res == 1 and  res[1] == "") then
                vim.cmd.quit()
                vim.notify("[thunder.nvim] No data, returning from the callback")
                return
            end
            res = vim.iter(res):map(function(i) return i and i:gsub("\r", "") or nil end):totable()

            local _, status_code = unpack(vim.split(res[1], " ")) -- http version
            local headers = vim.list_slice(res, 2, #res-1)
            local body = res[#res]

            local end_time = vim.fn.reltimefloat(vim.fn.reltime())

            M.cmap[1].contents = vim.split(vim.fn.system("jq", body), "\n")
            M.cmap[2].contents = headers
            local header_stuff = vim.iter(headers):map(function(item)
                if item ~= "" then
                    return item:match("(.*): (.*)")
                end
            end)

            local cookies = header_stuff:map(function(k, v)
                if k == "set-cookie" then
                    return v
                end
            end):totable()
            M.cmap[3].contents = vim.tbl_isempty(cookies) and {"No Cookies"} or cookies

            M.length = body:len() -- + header-len?
            M.status = status_code
            -- HACK(tamtonaquib): not really how it works. vim.uv?
            M.time = ("%.2f"):format(end_time - start_time)

            set_lines_and_stuff()
            set_winbar()
        end
    })
end

-- local vline_id, vtext_id, target
-- local vmethod, vurl, vheaders
-- M.setup = function()
    -- vim.api.nvim_create_autocmd("BufEnter", {
        -- pattern = "http",
        -- callback = function()
            -- vline_id = nil
            -- vtext_id = nil
            -- target = nil
            -- local vlines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            -- vmethod, vurl = vlines[1]:match("^([A-Z]+)%s*(.*)$")
            -- for i, line in ipairs(vlines) do
                -- if line == "" then
                    -- target = i
                -- end
            -- end
        -- end
    -- })
-- end

M.run = function()
    package.loaded["thunder"] = nil
    -- https://catfact.ninja/fact
    -- https://www.thunderclient.com/welcome
    -- win = vim.api.nvim_get_current_win()
    buf = vim.api.nvim_get_current_buf()


    vim.cmd [[vert new | setl nonu nornu ft=json bt=nofile bh=wipe cole=0 wrap sw=2 ts=2]]
    vim.keymap.set('n', '<leader>w', "<Cmd>q<Cr>", {buffer=0})
    vim.keymap.set('n', 'q', "<Cmd>q<CR>", {buffer=0})
    set_lines_and_stuff()

    call_for_help()

    vim.keymap.set('n', '<Right>', function()
        M.current_pane_index = M.current_pane_index + 1
        BCall()
    end, {buffer=0})
    vim.keymap.set('n', '<Left>', function()
        M.current_pane_index = M.current_pane_index - 1
        BCall()
    end, {buffer=0})
    vim.keymap.set('n', 'R', call_for_help, {buffer=0})

    vim.cmd [[hi ResponseHighlight gui=underline guifg=red]]
    vim.cmd [[hi HeaderHighlight gui=none guifg=none]]
    vim.cmd [[hi CookiesHighlight gui=none guifg=none]]
    vim.cmd [[hi ThunderCode gui=bold guifg=green]]
    vim.cmd [[hi ThunderSize gui=bold guifg=green]]
    vim.cmd [[hi ThunderTime gui=bold guifg=green]]

    vim.wo.winbar = winbar
end


function BCall(selected)
    if type(selected) == "number" then
        M.current_pane_index = selected
        selected = M.cmap[selected].name
    end
    if M.current_pane_index > 3 then
        M.current_pane_index = 1
    end
    if M.current_pane_index < 1 then
        M.current_pane_index = 3
    end

    for i, p in ipairs(M.cmap) do
        vim.cmd(
            "hi ".. p.name .. "Highlight"..
            " gui="..(i == M.current_pane_index and "underline,bold" or "none") ..
            " guifg="..(i == M.current_pane_index and "red" or "none")
        )
    end

    set_lines_and_stuff()
    set_winbar()
end

return M
