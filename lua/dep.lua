local M = {}
local buf, win
local filter = {
    ["Cargo.toml"] = {name="name", homepage="homepage", version="max_stable_version"},
    ["package.json"] = {name="name", homepage="homepage", version="version"},
    ["pyproject.toml"] = {name="name", homepage="home_page", version="version"},
}

local set_stuff = function(data)
    local fname = vim.fn.expand("%:t")
    local f = filter[fname]
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Name: " .. data[f.name],
        "Version: " .. data[f.version],
        "HomePage: " .. data[f.homepage],
    })
    vim.api.nvim_win_set_config(win, {width=data[f.homepage]:len() + 10})
end

M.check = function()
    local cword = vim.fn.expand("<cword>")
    local filename = vim.fn.expand("%:t")

    buf = vim.api.nvim_create_buf(false, true)
    win = vim.api.nvim_open_win(buf, false, {
        relative="cursor", row=1, col=1, height=3, width=20,
        title="Dep", border="single", style="minimal"
    })

    if filename == "package.json" then

        vim.system(
            {"npm", "info", cword, "--json"},
            {text=true},
            vim.schedule_wrap(function(out)
                set_stuff(vim.json.decode(out.stdout))
            end)
        )

    elseif filename == "Cargo.toml" then

        require("plenary.curl").get("https://crates.io/api/v1/crates/"..cword, {
            callback = vim.schedule_wrap(function(res)
                set_stuff(vim.json.decode(res.body).crate)
            end)
        })

    elseif filename == "pyproject.toml" then

        require("plenary.curl").get("https://pypi.org/pypi/"..cword.."/json", {
            callback = vim.schedule_wrap(function(res)
                set_stuff(vim.json.decode(res.body).info)
            end)
        })
    else
        vim.notify("Does not support this filetype!")
        vim.api.nvim_buf_delete(buf, {force=true})
    end

    vim.api.nvim_create_autocmd("CursorMoved", {
        callback = function()
            if vim.api.nvim_get_current_win() ~= win then
                pcall(vim.api.nvim_win_close, win, true)
            end
        end
    })

end

return M
