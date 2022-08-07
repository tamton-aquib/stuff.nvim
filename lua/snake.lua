local Snake = {}
local Food = {}
local uv = vim.loop
local snake_win, timer, snake_buf
local food_win, food_buf
local score = 0
local food_pos

function Food.init()
	Food.set_random()
end
local function rand_gen(limit)
	math.randomseed(os.clock())
	return math.floor(math.random() * limit)
end
function Food.set_random()
	local rand_col = rand_gen(vim.o.columns-3)
	local rand_row = rand_gen(vim.o.lines-3)
	if rand_col % 2 ~= 0 then rand_col = rand_col - 1 end
	food_pos = {rand_row, rand_col}

	food_buf = vim.api.nvim_create_buf(false, true)
	food_win = vim.api.nvim_open_win(food_buf, false, {
		style='minimal', relative='editor', width=2, height=1, row=rand_row, col=rand_col
	})
	vim.api.nvim_win_set_option(food_win, 'winhighlight', "Normal:SnakeFood")
end

function Food.destroy()
	vim.api.nvim_win_close(food_win, true)
	vim.api.nvim_buf_delete(food_buf, {force = true})
end

function Snake.game_over()
	vim.api.nvim_buf_delete(0, {force=true})
	vim.api.nvim_win_close(snake_win, true)
	vim.api.nvim_win_close(food_win, true)
	timer:stop()
	timer:close()
end

function Snake.init()
	snake_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(snake_buf)

	vim.keymap.set('n', 'q', function() Snake.game_over() end, {})
	vim.keymap.set('n', 'j', function() if Snake.direction ~= "Up" then Snake.direction = "Down" end end, {buffer=snake_buf})
	vim.keymap.set('n', 'k', function() if Snake.direction ~= "Down" then Snake.direction = "Up" end end, {buffer=snake_buf})
	vim.keymap.set('n', 'l', function() if Snake.direction ~= "Left" then Snake.direction = "Right" end end, {buffer=snake_buf})
	vim.keymap.set('n', 'h', function() if Snake.direction ~= "Right" then Snake.direction = "Left" end end, {buffer=snake_buf})

	snake_win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
		style='minimal', row=0, col=0, width=2, height=1, relative='editor'
	})
	vim.api.nvim_win_set_option(snake_win, 'winhighlight', "Normal:Snake")
end

function Snake.check_score()
	local win_cfg = vim.api.nvim_win_get_config(snake_win)
	local col, row = win_cfg["col"][false], win_cfg["row"][false]
	if col >= vim.o.columns-1 or row >= vim.o.lines-1 then
		print("Game Over..!!  Score: " .. score)
		Snake.game_over()
		return 1
	end
end

function Snake.ate_food()
	local win_cfg = vim.api.nvim_win_get_config(snake_win)
	local col, row = win_cfg["col"][false], win_cfg["row"][false]

	if col == food_pos[2] and row == food_pos[1] then
		return true
	end
	return false
end

Snake.setup = function()
	for p,_ in pairs(package.loaded) do if p:match("^snake") then package.loaded[p]=nil end end
	vim.cmd [[
		hi SnakeFood guifg=#ee6d85 guibg=#ee6d85
		hi Snake guifg=#95c561 guibg=#95c561
	]]
	Snake.init()
	Food.init()

	timer = uv.new_timer()
	uv.timer_start(timer, 1000, 100, vim.schedule_wrap(function()
		if Snake.check_score() then return end
		local win_cfg = vim.api.nvim_win_get_config(snake_win)
		local col, row = win_cfg["col"][false], win_cfg["row"][false]

		if not Snake.direction then
			Snake.direction = "Right"
		elseif Snake.direction == "Right" then
			win_cfg["col"] = col + 2
		elseif Snake.direction == "Down" then
			win_cfg["row"] = row + 1
		elseif Snake.direction == "Left" then
			win_cfg["col"] = col - 2
		elseif Snake.direction == "Up" then
			win_cfg["row"] = row - 1
		end

		if Snake.ate_food() then
			Food.destroy()
			Food.set_random()
			-- Snake:increment()
			score = score + 1
		end
		print(score)

		vim.api.nvim_win_set_config(snake_win, win_cfg)
	end))
end

return Snake
