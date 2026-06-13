local M = {}
local buf, win
local ns = vim.api.nvim_create_namespace("jwt")
local last_token = ""
local orig_payload = ""
local secret = nil
local rendering = false

local strip = function(s)
	return s:match("^%s*(.-)%s*$")
end

local b64url_encode = function(data)
	local enc = vim.base64.encode(data)
	return enc:gsub("+", "-"):gsub("/", "_"):gsub("=", "")
end

local b64url_decode = function(str)
	if not str or str == "" then return nil end
	local pad = #str % 4
	if pad == 2 then str = str .. "=="
	elseif pad == 3 then str = str .. "="
	elseif pad ~= 0 then return nil end
	local ok, result = pcall(vim.base64.decode, str:gsub("-", "+"):gsub("_", "/"))
	return ok and result or nil
end

local json_lines = function(raw)
	if not raw or raw == "" then return { "(decode failed)" } end
	local ok2, out = pcall(function() return vim.fn.system("jq", raw) end)
	if ok2 and vim.v.shell_error == 0 then
		return vim.split(strip(out), "\n", { plain = true })
	end
	local ok, obj = pcall(vim.json.decode, raw)
	if not ok then return { raw } end
	return vim.split(vim.json.encode(obj), "\n", { plain = true })
end

local hmac_sha256 = function(key, msg)
	local ok, out = pcall(function()
		return vim.fn.system({ "openssl", "dgst", "-sha256", "-hmac", key }, msg)
	end)
	if not ok then return nil end
	local hex = out:match("= (%x+)")
	return hex and hex:lower() or nil
end

local verify_sig = function(token, key)
	local parts = vim.split(token, ".", { plain = true })
	if #parts ~= 3 then return false end
	local computed = hmac_sha256(key, parts[1] .. "." .. parts[2])
	if not computed then return false end
	local sig_bytes = b64url_decode(parts[3])
	if not sig_bytes then return false end
	local sig_hex = ""
	for i = 1, #sig_bytes do
		sig_hex = sig_hex .. string.format("%02x", sig_bytes:byte(i))
	end
	return computed == sig_hex
end

local is_jwt = function(str)
	return str and str:match("^[%w%-_]+%.[%w%-_]+%.[%w%-_]+$") ~= nil
end

local function find_line(prefix)
	local all = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for i, l in ipairs(all) do
		if l == prefix then return i end
	end
	return nil
end

local function read_section(prefix)
	local sl = find_line(prefix)
	if not sl then return nil end
	local lines = {}
	local all = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for i = sl + 1, #all do
		local l = all[i]
		if l == "" then break end
		table.insert(lines, l)
	end
	return #lines > 0 and lines or nil
end

local function set_display(lines)
	vim.api.nvim_buf_set_lines(buf, 1, -1, false, {})
	local raw = {}
	for _, l in ipairs(lines) do table.insert(raw, l.text) end
	vim.api.nvim_buf_set_lines(buf, 1, 1, false, raw)
	for i, l in ipairs(lines) do
		if l.hl and l.hl ~= "None" then
			vim.api.nvim_buf_add_highlight(buf, ns, l.hl, i, 0, -1)
		end
	end
	vim.api.nvim_win_set_config(win, { height = math.min(#lines + 2, vim.o.lines - 4) })
end

local function save_token()
	last_token = strip(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
end

local function build_lines(token, cur_secret)
	local lines = {}
	local function add(hl, text) table.insert(lines, { text = text, hl = hl }) end

	if not is_jwt(token) then
		add("Comment", "  not a valid jwt")
		return lines
	end

	local parts = vim.split(token, ".", { plain = true })
	local header_raw = b64url_decode(parts[1])
	local payload_raw = b64url_decode(parts[2])
	local sig = parts[3] or ""

	add("None", "")
	add("JwtHeader", "HEADER")
	for _, l in ipairs(json_lines(header_raw)) do add(nil, "  " .. l) end
	add("None", "")
	add("JwtPayload", "PAYLOAD")
	for _, l in ipairs(json_lines(payload_raw)) do add(nil, "  " .. l) end
	add("None", "")
	add("JwtSignature", "SIGNATURE")
	add("JwtSigText", "  " .. sig)
	add("None", "")
	add("JwtSecret", "SECRET")
	add("JwtSecretKey", "  " .. (cur_secret or ""))

	if cur_secret and cur_secret ~= "" then
		add("None", "")
		if verify_sig(token, cur_secret) then
			add("JwtVerified", "  ✓ signature verified")
		else
			add("JwtFailed", "  ✗ signature verification failed")
		end
	end

	return lines
end

local function render()
	if rendering then return end
	if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
	if not win or not vim.api.nvim_win_is_valid(win) then return end
	rendering = true

	local token = strip(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
	local pos = vim.api.nvim_win_get_cursor(win)

	if token ~= last_token then
		secret = nil
		local parts = vim.split(token, ".", { plain = true })
		orig_payload = #parts == 3 and (b64url_decode(parts[2]) or "") or ""
		set_display(build_lines(token, nil))
		save_token()
		pcall(vim.api.nvim_win_set_cursor, win, { math.min(pos[1], vim.api.nvim_buf_line_count(buf)), pos[2] })
		rendering = false
		return
	end

	local edited_lines = read_section("PAYLOAD")
	if edited_lines then
		local edited = table.concat(edited_lines, "\n"):gsub("\n  ", "\n"):gsub("^  ", "")
		local ok_e, obj_e = pcall(vim.json.decode, edited)
		local ok_o, obj_o = pcall(vim.json.decode, orig_payload)
		local changed = not (ok_e and ok_o and vim.deep_equal(obj_e, obj_o))
		if changed then
			local hdr = token:match("^([^.]+)")
			local sig = token:match("[^.]+$")
			local reencoded = vim.json.encode(obj_e)
			local new_token = hdr .. "." .. b64url_encode(reencoded) .. "." .. sig
			vim.api.nvim_buf_set_lines(buf, 0, 1, false, { new_token })
			orig_payload = reencoded
			last_token = new_token
			local sl = find_line("SECRET")
			local all = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			local cur = sl and sl < #all and strip(all[sl + 1]) or nil
			set_display(build_lines(new_token, cur))
			pcall(vim.api.nvim_win_set_cursor, win, { math.min(pos[1], vim.api.nvim_buf_line_count(buf)), pos[2] })
			rendering = false
			return
		end
	end

	local sl = find_line("SECRET")
	local all = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local cur = sl and sl < #all and strip(all[sl + 1]) or nil
	if cur ~= secret then
		secret = cur
		set_display(build_lines(token, secret))
		pcall(vim.api.nvim_win_set_cursor, win, { math.min(pos[1], vim.api.nvim_buf_line_count(buf)), pos[2] })
	end

	rendering = false
end

M.toggle = function()
	if win and vim.api.nvim_win_is_valid(win) then
		pcall(vim.api.nvim_win_close, win, true)
		win = nil
		return
	end

	buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	secret = nil
	last_token = ""
	orig_payload = ""

	win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		border = "double",
		style = "minimal",
		title = " JWT ",
		title_pos = "center",
		width = 66,
		height = 3,
		row = math.floor(vim.o.lines * 0.15),
		col = math.floor((vim.o.columns - 66) / 2),
	})

	vim.wo[win].wrap = false
	vim.wo[win].linebreak = false
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.api.nvim_win_set_hl_ns(win, ns)

	vim.api.nvim_set_hl(ns, "JwtHeader",     { fg = "#61afef", bold = true })
	vim.api.nvim_set_hl(ns, "JwtPayload",    { fg = "#c678dd", bold = true })
	vim.api.nvim_set_hl(ns, "JwtSignature",  { fg = "#e5c07b", bold = true })
	vim.api.nvim_set_hl(ns, "JwtSigText",    { fg = "#5c6370", italic = true })
	vim.api.nvim_set_hl(ns, "JwtSecret",     { fg = "#56b6c2", bold = true })
	vim.api.nvim_set_hl(ns, "JwtSecretKey",  { fg = "#d19a66" })
	vim.api.nvim_set_hl(ns, "JwtVerified",   { fg = "#98c379", bold = true })
	vim.api.nvim_set_hl(ns, "JwtFailed",     { fg = "#e06c75", bold = true })

	local paste = vim.fn.getreg("+")
	if not is_jwt(paste) then paste = vim.fn.getreg("*") end
	if is_jwt(paste) then
		vim.api.nvim_buf_set_lines(buf, 0, 1, false, { strip(paste) })
	end

	vim.api.nvim_create_autocmd("TextChanged", {
		buffer = buf,
		callback = render,
	})
	vim.api.nvim_create_autocmd("TextChangedI", {
		buffer = buf,
		callback = function()
			local t = strip(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
			if t ~= last_token then render() end
		end,
	})
	vim.api.nvim_create_autocmd("InsertLeave", {
		buffer = buf,
		callback = render,
	})

	vim.keymap.set("n", "q", function()
		pcall(vim.api.nvim_win_close, win, true)
		win = nil
	end, { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		pcall(vim.api.nvim_win_close, win, true)
		win = nil
	end, { buffer = buf, silent = true })

	render()
	vim.cmd("setlocal ft=json")
end

M.setup = function()
	vim.api.nvim_create_user_command("Jwt", M.toggle, {})
end

return M
