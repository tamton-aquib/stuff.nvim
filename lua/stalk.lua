local S = {}

local pad = function(str, pad) return (" ") .. str .. (" "):rep(pad-#str) end
local parse_json = function(json_data)
    local events = { "GH User Events", "--------------" }

    for _, event in ipairs(json_data) do
        local action, icon
        local user = event["actor"]["display_login"]

        if event.payload["forkee"] then               action = "forked"    icon = " "
        elseif event.type == "CreateEvent" then       action = "created"   icon = " "
        elseif event.type == "IssueCommentEvent" then action = "commented" icon = " "
        elseif event.type == "IssuesEvent" then       action = "opened"    icon = " "
        elseif event.payload.action == "started" then action = "starred"   icon = " "
        else                                          action = "undefined" icon = " "
        end

        local repo = event.repo.name
        table.insert(events, ("%s %s %s %s"):format(icon, pad(user, 20), pad(action, 10), repo))
    end
    return events
end

S.stalk = function()
  vim.schedule(function()
    vim.ui.input({prompt="Enter gh username: "}, function(username)
          vim.cmd [[vsp | enew | setl nonu nornu bt=nofile bh=wipe]]
          vim.keymap.set('n', 'q', '<CMD>q<CR>', {buffer=0})
      local url = ("https://api.github.com/users/%s/received_events"):format(username)

      vim.schedule(function()
        local sauce = require("plenary.job"):new({ command = "curl", args = {url} }):sync()
        local json_data = vim.json.decode(table.concat(sauce, ''))
        vim.api.nvim_put(parse_json(json_data), "", false, false)
      end)
    end)
  end)
end

S.setup = function()
    vim.api.nvim_create_user_command("Stalk", S.stalk, {})
end

return S
