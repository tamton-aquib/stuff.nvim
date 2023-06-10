-- Plugin search on first line in installer window: M.install_picker()
-- Remove installed plugins by pressing enter on removed window: M.remove_picker()
local M = {}

local gline, buf
local plugin_list = {}
local curl = require("plenary.curl")
local json_path = vim.fn.stdpath("config") .. "/plugins.json"

-- NOTE: Kinda inefficient. Too lazy to do the normal way :(
local actions = {
    get = function() return vim.json.decode(table.concat(vim.fn.readfile(json_path))) end,

    set = function(p)
        vim.fn.writefile({vim.fn.json_encode(p)}, json_path)
        vim.notify("Wrote changes to plugins.json!")
    end
}

local remove_selected_plugin = function()
    local line = vim.trim(vim.api.nvim_get_current_line())
    local ps = actions.get()
    if not ps then return end

    local newt = {}
    for _,p in ipairs(ps) do
        if not p.url:match(vim.pesc(line)) then
            table.insert(newt, p)
        end
    end
    actions.set(newt)
    vim.api.nvim_del_current_line()
end
local install_selected_plugin = function()
    local result = vim.trim(vim.api.nvim_get_current_line())
    local selected = plugin_list[result].full_name

    local ps = actions.get()
    if not ps then return end
    table.insert(ps, {url=[[https://github.com/]]..selected, config=true})
    actions.set(ps)
end

local update_lines = function(d)
    plugin_list = vim.json.decode(d)
    vim.schedule(function()
        vim.api.nvim_buf_set_lines(buf, 1, -1, false, {})
        local t = vim.tbl_keys(plugin_list)
        vim.api.nvim_buf_set_lines(buf, 1, 2, false, t)
    end)
end

local search_plugins = function()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, true)[1]

    if vim.bo.ft ~= "lazy_search" or line:len() < 3 or line == gline then
        return
    end

    curl.get("https://api.nvimplugnplay.repl.co/search?max_count=10&query="..line, {
        callback=function(d) update_lines(d.body) end
    })

    gline = line
end

local picker_base = function()
    buf = vim.api.nvim_create_buf(false, true)
    vim.cmd [[leftabove vsplit | vert resize 30]]
    vim.api.nvim_set_current_buf(buf)
    vim.cmd [[set nonu nornu ft=lazy_search]]
    require("essentials.utils").set_quit_maps()
end

M.install_picker = function()
    picker_base()
    vim.keymap.set({"i", "n"}, "<CR>", install_selected_plugin, { buffer=buf })
    vim.api.nvim_create_autocmd('CursorHoldI', { callback=search_plugins }) -- :h timeoutlen?
end

M.remove_picker = function()
    picker_base()
    local ps = actions.get()
    if not ps then return end

    local newt = {}
    for _, p in ipairs(ps) do
        local json_bruh = p.url:gsub("https://github.com/", "")
        table.insert(newt, json_bruh)
    end
    vim.api.nvim_put(newt, "", false, false)
    vim.keymap.set({"i", "n"}, "<CR>", remove_selected_plugin, { buffer=buf })
end


return M
