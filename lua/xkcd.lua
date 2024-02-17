local M = {}
local ns = vim.api.nvim_create_namespace("xkcd")

local open_split_and_paste_image = function(s)
    local date = (" (%s/%s/%s)"):format(s.day, s.month, s.year)
    local heading =  s.title .. date
    vim.api.nvim_put({"", "", ""}, "", true, true)
    vim.api.nvim_buf_set_extmark(0, ns, 2, 0, {
        virt_text = {
            {(" "):rep((vim.api.nvim_win_get_width(0) - #heading - 2)/2)..s.title, "Function"},
            {date, "Comment"}
        }
    })

    require("image").from_url(
        s.img,
        { window = vim.api.nvim_get_current_win() },
        function(image)
            image:render({ x = 0, y = 4 }) -- width, height not working
            local win = vim.api.nvim_get_current_buf()
            vim.api.nvim_create_autocmd("BufEnter", {
                once = true,
                callback = function()
                    image:clear()
                    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
                    pcall(vim.api.nvim_win_close, win, true)
                end
            })
        end
    )
end

M.xkcd = function()
    math.randomseed(os.clock())

    vim.cmd [[vsp | enew | set nonu nornu bt=nofile bh=wipe]]
    vim.cmd("vert resize -20")

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
