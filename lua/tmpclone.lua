local M = {}
local clones = {}

local convert = function(repo, t)
    local dirname = t == "-" and repo:gsub("/", "---") or repo:gsub("---", "/")
    local path = "/tmp/"..dirname
    return {dirname=dirname, path=path}
end

-- TODO: Better logic by traversing the /tmp/plugin dir.
local get_clones = function() return clones end

local clone = function(repo)
    local nice = convert(repo, "-")
    local cmd = "git clone --depth 1 https://github.com/"..repo..".git "..nice.path
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
end

local del = function(repo)
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

M.setup = function()
	for p,_ in pairs(package.loaded) do if p:match("^tempclone") then package.loaded[p]=nil end end

    vim.api.nvim_create_user_command('TmpClone', function(opts)
        clone(opts.args)
    end, { nargs=1, complete=get_clones })
    vim.api.nvim_create_user_command('TmpDel', function(opts)
        del(opts.args)
    end, { nargs=1, complete=get_clones })
    vim.api.nvim_create_user_command('TmpList', function()
        print(vim.inspect(clones))
    end, { nargs=0 })
end

return M
