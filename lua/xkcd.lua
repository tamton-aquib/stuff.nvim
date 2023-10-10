-- Bind some key to `require("xkcd").xkcd()`
-- TODO: cleanify.
local M = {}
local tempfile, image
local ns = vim.api.nvim_create_namespace("xkcd")

local open_split_and_paste_image = function(s)
    local col = vim.fn.screencol()
    local title = s.title
    local date = (" (%s/%s/%s)"):format(s.day, s.month, s.year)
    local heading =  title .. date
    vim.api.nvim_put({"", "", ""}, "", true, true)
    vim.api.nvim_buf_set_extmark(0, ns, 2, 0, {
        virt_text = {
            {(" "):rep((vim.api.nvim_win_get_width(0) - #heading - 2)/2)..title, "Function"},
            {date, "Comment"}
        }
    })

    image = require("hologram.image"):new(tempfile, {})
    -- image:display(2, col-5, 0, {height=720, width=1300})
    image:display(4, col-5, 0, {
        rows=math.floor(vim.o.lines/3),
        cols=vim.api.nvim_win_get_width(0) - 5
    })

    local win = vim.api.nvim_get_current_buf()
    local b = vim.api.nvim_get_current_buf()
    vim.bo[b].buflisted = false
    vim.api.nvim_create_autocmd("BufEnter", {
        once = true,
        callback = function()
            image:delete(0, {free=true})
            pcall(vim.api.nvim_win_close, win, true)
            os.remove(tempfile)
            vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
        end
    })
end

M.xkcd = function()
    math.randomseed(os.clock())

    vim.cmd [[vsp enew | set nonu nornu bt=nofile bh=wipe]]
    vim.cmd("vert resize -20")
    local num = math.random(1, 2750)
    vim.fn.jobstart({"curl", "https://xkcd.com/"..num.."/info.0.json"}, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            local sauce = vim.json.decode(data[1])
            local img_url = sauce.img
            tempfile = os.tmpname()..".png"

            vim.fn.jobstart({"curl", img_url, "-o", tempfile}, {
                stdout_buffered = true,
                on_exit = function() open_split_and_paste_image(sauce) end
            })
        end
    })
end

return M
