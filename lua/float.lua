-- TODO: maybe move tot fully fledged plugin in future
-- TODO: maybe do for splits too. (not works only for floats)
local F = {}
-- local selected_win

F.open = function(buf, enter, ...)
    local cfg = ({...})[1]
    local cfg_bak = vim.deepcopy(cfg)

    local timer = vim.loop.new_timer()
    local done = {h=false, w=false}

    cfg_bak["height"] = 1
    cfg_bak["width"] = 1
    local win = vim.api.nvim_open_win(buf, enter, cfg_bak)

    timer:start(50, 10, vim.schedule_wrap(function()
        if done.w and done.h then
            timer:stop()
            return
        end

        local config = vim.api.nvim_win_get_config(win)

        if config["height"] >= cfg.height then
            done.h = true
        else
            config["height"] = config["height"] + 1
        end

        if config["width"] >= cfg.width then
            done.w = true
        else
            config["width"] = config["width"] + 1
        end

        vim.api.nvim_win_set_config(win, config)
    end))
end

F.close = function()
    local timer = vim.loop.new_timer()
    local conf = vim.api.nvim_win_get_config(0)
    if conf.relative ~= "relative" then return end

    if #vim.api.nvim_list_wins() > 1 then
        timer:start(100, 10, vim.schedule_wrap(function()
            if vim.api.nvim_win_get_width(0) == vim.o.columns then

                local height = vim.api.nvim_win_get_height(0)
                if height <= vim.opt.winheight:get() then
                    timer:stop()
                    vim.api.nvim_win_close(0, true)
                    return
                end
                vim.cmd [[resize -1]]

            elseif vim.api.nvim_win_get_height(0) then

                local width = vim.api.nvim_win_get_width(0)
                if width <= vim.opt.winwidth:get() then
                    timer:stop()
                    vim.api.nvim_win_close(0, true)
                    return
                end
                vim.cmd [[vertical resize -2]]

            end
        end))
    end
    -- if conf.relative == "" then
    -- else
        -- if #vim.api.nvim_list_bufs() >= 2 then
            -- vim.api.nvim_buf_delete(0, {force=true})
        -- else
            -- vim.api.nvim_win_close(0, true)
        -- end
    -- end
    -- else
        -- timer:start(100, 10, vim.schedule_wrap(function()
            -- local width = vim.api.nvim_win_get_width(0)
            -- if width <= vim.opt.winwidth:get() then
                -- timer:stop()
                -- -- timer:close()
                -- vim.api.nvim_win_close(0, true)
                -- return
            -- else
                -- vim.cmd [[vertical resize -1]]
                -- vim.cmd [[resize -1]]
            -- end
        -- end))
    -- end
end

local move_float = function(conf, dir)
	if dir == "down" then
		conf["row"][false] = conf["row"][false] + 1
	elseif dir == "up" then
		conf["row"][false] = conf["row"][false] - 1
	elseif dir == "left" then
		conf["col"][false] = conf["col"][false] - 1
	elseif dir == "right" then
		conf["col"][false] = conf["col"][false] + 1
	end

	return conf
end

local change_win_prop = function(direction)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local conf = vim.api.nvim_win_get_config(win)
		if conf.relative ~= "" then
			conf = move_float(conf, direction)
            -- selected_win = win
			-- vim.api.nvim_win_set_config(selected_win, conf)
			vim.api.nvim_win_set_config(win, conf)
		end
	end
end

-- NOTE: <C-w>w already exists
-- local entered_already = {}
-- F.enter_float = function()
    -- if #entered_already == #vim.api.nvim_list_wins() then entered_already = {} end
    -- for _, win in ipairs(vim.api.nvim_list_wins()) do
        -- if not vim.tbl_contains(entered_already, win) then
            -- selected_win = win
            -- table.insert(entered_already, win)
            -- vim.api.nvim_set_current_win(selected_win)
            -- return
        -- end
    -- end
-- end

F.setup = function()
	vim.keymap.set('n', '<C-down>', function() change_win_prop("down") end)
	vim.keymap.set('n', '<C-up>', function() change_win_prop("up") end)
	vim.keymap.set('n', '<C-left>', function() change_win_prop("left") end)
	vim.keymap.set('n', '<C-right>', function() change_win_prop("right") end)
end

return F
