local M = {}
local clones = {}
local tmpclone_loaded = false

local convert = function(repo, t)
    local dirname = t == "-" and repo:gsub("/", "---") or repo:gsub("---", "/")
    local path = "/tmp/tmpclone/"..dirname
    return { dirname=dirname, path=path }
end

local get_clones = function() return vim.fn.readdir("/tmp/tmpclone/") end

local tmpclone = function(repo)
    local nice = convert(repo, "-")
    local bruh = repo:match("github.com") and repo or "https://github.com/"..repo
    local cmd = "git clone --depth 1 "..bruh.." "..nice.path
    vim.fn.jobstart(cmd, {
        on_exit = function(_, code, _) -- id, status
            if code == 0 then
                vim.notify("Cloned successfully!")
            else
                print("Already exists?")
                vim.cmd("tabe  "..nice.path)
                return
            end
            table.insert(clones, nice.dirname)
            vim.cmd("tabe  "..nice.path)
        end,
    })
    vim.notify("Cloning "..repo)
end

local tmpdel = function(repo)
    local nice = convert(repo, "-")
    if not repo then
        require("essentials").ui_picker(clones, function(option)
            vim.notify("Successfully deleted "..option)
            vim.fn.delete(option.path,  "rf")
        end)
    else
        vim.fn.delete(nice.path, "rf")
        vim.notify("Successfully deleted "..nice.dirname)
    end
    table.remove(clones, #clones)
end

M.clone = function()
    if not tmpclone_loaded then
        M.setup()
        tmpclone_loaded = true
    end

    vim.ui.input({prompt="Enter repo name: "}, function(repo)
        tmpclone(repo)
    end)
end

M.setup = function()
	-- for p,_ in pairs(package.loaded) do if p:match("^tmpclone") then package.loaded[p]=nil end end
    tmpclone_loaded = true

    vim.api.nvim_create_user_command('TmpClone', function(opts)
        tmpclone(opts.args)
    end, { nargs=1, complete=get_clones })
    vim.api.nvim_create_user_command('TmpDel', function(opts)
        tmpdel(opts.args)
    end, { nargs=1, complete=get_clones })
    vim.api.nvim_create_user_command('TmpList', function()
        print(vim.inspect(clones))
    end, { nargs=0 })
end

return M
