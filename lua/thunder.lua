-- Similar to thunderclient in vscode (no features yet.)
-- TODO: Just POC of winbar as clickable tabs, info
-- TODO: Does not work fully, just call the function when cursor on urls
local M = {}

local winbar = [[%1@v:lua.BCall@%#ResponseHighlight#Response%X%#None# %2@v:lua.BCall@%#HeaderHighlight#Header%X%#None# %3@v:lua.BCall@%#CookiesHighlight#Cookies%X%#None#%=]]

local panes = { "Response", "Header", "Cookies" }
local pane_contents = {
    Response = { "Fetching..." },
    Header = { "Fetching..." },
    Cookies = { "Fetching..." }
}
local pane = panes[1]
local buf, win, url
local counter = 0

local set_lines_and_stuff = function() vim.api.nvim_buf_set_lines(0, 0, -1, false, pane_contents[pane]) end

local set_winbar = function()
    vim.wo[win].winbar = winbar.. "%#ThunderCode#"..(M.status.." ok  " or "").. "%#ThunderSize#"..(M.length.." bytes  " or "").. "%#ThunderTime#"..(M.time.." s" or "")
end

local call_for_help = function()
    local start_time = vim.fn.reltimefloat(vim.fn.reltime())
    vim.fn.jobstart({"curl", "-i", url}, {
        stdout_buffered = true,
        on_stdout = function(_, res)
            res = vim.iter(res):map(function(i) return i and i:gsub("\r", "") or nil end):totable()

            local _, status_code = unpack(vim.split(res[1], " ")) -- http version
            local headers = vim.list_slice(res, 2, #res-1)
            local body = res[#res]

            local end_time = vim.fn.reltimefloat(vim.fn.reltime())

            pane_contents["Response"] = vim.split(vim.fn.system("jq", body), "\n")
            pane_contents["Header"] = headers
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
            pane_contents["Cookies"] = vim.tbl_isempty(cookies) and {"No Cookies"} or cookies

            M.length = body:len()
            M.status = status_code
            -- HACK(tamtonaquib): not really how it works.
            M.time = ("%.2f"):format(end_time - start_time)

            set_lines_and_stuff()
            set_winbar()
        end
    })
end

M.setup = function()
    -- https://catfact.ninja/fact
    -- https://www.thunderclient.com/welcome
    url = vim.fn.expand('<cfile>', nil, nil)
    if not url:match("^http") then
        vim.notify(url.. " is not a valid url!")
        return
    end

    -- buf = vim.api.nvim_create_buf(false, true)
    -- win = vim.api.nvim_open_win(buf, true, { style='minimal', border='double', relative='editor', row=5, col=5, width=100, height=20 })
    vim.cmd [[vert new | setl nonu nornu ft=json bt=nofile]]
    win = vim.api.nvim_get_current_win()
    buf = vim.api.nvim_get_current_buf()
    set_lines_and_stuff()
    vim.keymap.set('n', '<Tab>', function()
        -- counter = ((counter + 1) % 3) + 1
        local counters = {
            [0] = { nxt = 2, ft="dosini" },
            [1] = { nxt = 2, ft="dosini" },
            [2] = { nxt = 3, ft="dosini" },
            [3] = { nxt = 1, ft="json" }
        }
        counter = counters[counter].nxt
        BCall(counter)
        vim.cmd("set ft="..counters[counter].ft)
    end, {buffer=buf})
    vim.keymap.set('n', 'R', call_for_help, {buffer=buf})

    vim.cmd [[hi ResponseHighlight gui=underline guifg=red]]
    vim.cmd [[hi HeaderHighlight gui=none guifg=none]]
    vim.cmd [[hi CookiesHighlight gui=none guifg=none]]
    vim.cmd [[hi ThunderCode gui=bold guifg=green]]
    vim.cmd [[hi ThunderSize gui=bold guifg=green]]
    vim.cmd [[hi ThunderTime gui=bold guifg=green]]

    call_for_help()
    vim.wo[win].winbar = winbar
end


function BCall(selected)
    for p in vim.iter(panes) do vim.cmd("hi "..p.."Highlight gui=none guifg=none") end
    if pane ~= panes[selected] then
        pane = panes[selected]
        vim.cmd ("hi " .. pane .. "Highlight gui=underline,bold guifg=red")
        set_lines_and_stuff()
        set_winbar()
    end
end

return M
