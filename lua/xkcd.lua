local M = {}
local ns = vim.api.nvim_create_namespace("xkcd")

local open_split_and_paste_image = function(s)
    local date = (" (%s/%s/%s)"):format(s.day, s.month, s.year)
    vim.api.nvim_put({"", "", ""}, "", true, true)
    vim.api.nvim_buf_set_extmark(0, ns, 2, 0, { virt_text = { {s.title, "Function"}, {date, "Comment"} } })

    require("image").from_url(
        s.img,
        { window = vim.api.nvim_get_current_win() },
        function(image)
            image:render({ x = 0, y = 4 })
        end
    )
end

M.xkcd = function()
    math.randomseed(os.clock())
    vim.cmd [[vsp | enew | set nonu nornu bt=nofile bh=wipe | vert resize -20 ]]

    local num = math.random(1, 2750)
    vim.fn.jobstart({"curl", "https://xkcd.com/"..num.."/info.0.json"}, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            local sauce = vim.json.decode(data[1])
            open_split_and_paste_image(sauce)
        end
    })
end

return M
