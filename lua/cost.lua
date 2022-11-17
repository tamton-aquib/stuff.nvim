-- TODO: avoid refetching every mod (very inefficient)
-- TODO: better var names
local M = {
    ns = vim.api.nvim_create_namespace("cost"),
    packs = {}
}
local url = "https://bundlephobia.com/api/size?package="

-- NOTE: plenary.curl was blocking so had to use jobstart()
-- local update_size = function(pack)
    -- local res = require("plenary.curl").get(url..pack, {})
    -- if not res then return end 
    -- if res.status ~= nil and res.status == 200 then
        -- return vim.json.decode(res.body)['gzip']
    -- end
    -- return "Not found"
-- end

-- FROM: https://github.com/thelostone-mc/importcost/blob/master/lib/utils.js
local convert = function(bytes)
    if bytes == 0 then return "0" end
    local METRIC_LIST = {"Byes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}
    local raised = math.floor(math.log(bytes) / math.log(1024))
    local nice = bytes / math.pow(1024, raised)
    return ("%.02f"):format(nice) .. " " .. METRIC_LIST[raised+1]
end

M.setup = function()
    local language_tree = vim.treesitter.get_parser(0, vim.bo.ft)
    local root = language_tree:parse()[1]

    -- TODO: better queries?
    local query = vim.treesitter.parse_query(vim.bo.ft, [[
    (import_statement
        (string
            (string_fragment) @capture))
    ]])

    for _, captures in query:iter_matches(root:root(), 0) do
        local text = vim.treesitter.query.get_node_text(captures[1], 0)
        local line = captures[1]:range()

        local id = vim.api.nvim_buf_set_extmark(0, M.ns, line, 0, {
            virt_text_pos = 'eol',
            virt_text = {{'0 B', 'Function'}}
        })

        text = text:gsub("/", "."):lower()
        M.packs[text] = {id=id, line=line, size=''}
    end

    -- vim.api.nvim_buf_clear_namespace(0, M.ns, 0, -1)
    for pack, packinfo in pairs(M.packs) do
        vim.fn.jobstart({"curl", url..pack}, {
            stdout_buffered = true,

            on_stdout = function(_, data)
                local size = vim.json.decode(data[1])['gzip']
                M.packs[pack].size = size

                vim.api.nvim_buf_set_extmark(0, M.ns, packinfo.line, 0, {
                    virt_text = {{convert(size), 'Function'}},
                    id = packinfo.id
                })
            end
        })
    end
end

return M
