local M = {}

-- Map this function to something
M.chatgpt = function()
    vim.ui.input({ prompt="Prompt:", width=40 }, function(inp)
        vim.cmd("split | new | setlocal nonu nornu bufhidden=wipe wrap")
        require("essentials.utils").set_quit_maps()
        require("plenary.curl").post("https://api.openai.com/v1/chat/completions", {
            body = vim.json.encode({ max_tokens=150, model="gpt-3.5-turbo", messages={{role="user", content=inp}} }),
            auth = {vim.env.OPENAI_API_KEY or "No Token Provided!"},
            headers = { content_type = "application/json" },
            callback = function(response) vim.schedule(function()
                local body = vim.json.decode(response.body)

                vim.api.nvim_put(vim.split(
                    body.choices and vim.trim(body.choices[1].message.content)
                    or ("Something went wrong!\n%s"):format(vim.inspect(body.error.message))
                , '\n') , "", false, false)
            end) end
        })
    end)
end

return M
