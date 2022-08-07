local M = {}
local uv = vim.loop
local ascii = [[
           .             
          / \            
         /   \           
        /^.   \          
       /  .-.  \         
      /  (   ) _\        
     / _.~   ~._^\       
    /.^         ^.\      
]]

local command = function(str)
    local cmd = io.popen(str, "r")
    if cmd ~= nil then
        local res = cmd:read("*l")
        cmd:close()
        return res
    else
        return ""
    end
end
local uptime = function()
    -- TODO: uv.uptime()
    local hour, min = unpack(vim.split(command("uptime"):match("(%d?%d:%d%d?),"), ":"))
    return hour.."hrs, "..min.."mins"
end

M.setup = function()
	for p,_ in pairs(package.loaded) do if p:match("^neofetch") then package.loaded[p]=nil end end

    local u = uv.os_uname()
    local stuff = {
        uv.os_gethostname().."@"..os.getenv("USER"),
        "Machine: " .. u.sysname .. " " .. u.machine,
        "Release: " .. u.release,
        -- Ram and usage?
        "Uptime : " .. uptime(),
        "DE/WM  : " .. "ᗪᗯᗰ "
    }

    -- for i, line in ipairs(vim.split(ascii, '\n')) do
        -- local res = line .. (i <= #stuff and stuff[i] or '')
        -- print(res)
    -- end
    -- print(vim.inspect(uv.getrusage()))
    print(vim.inspect(stuff))
end

-- local set_lines = function(lines)
	-- local buf = vim.api.nvim_create_buf(false, true)
	-- vim.api.nvim_set_current_buf(buf)
	-- vim.api.nvim_buf_set_option(buf, 'filetype', 'dashboard')

	-- vim.api.nvim_put(lines, "", true, true)
-- end
return M
