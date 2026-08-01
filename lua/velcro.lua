local M = {}
local api = vim.api
local uv = vim.uv or vim.loop
local DQ = string.char(34)

local ns = api.nvim_create_namespace("velcro")

local cfg = {
  limit = 5,
  delay = 3000,
  keys = { p = "p", P = "P" },
  preview_hl = "VelcroPreview",
  label_hl = "VelcroLabel",
}

local ring = {}
local session = nil
local configured = false

local function recordable(r)
  return r == "" or r == DQ or r == "+" or r == "*"
end

local function record(op, contents, regtype, regname)
  if (op ~= "y" and op ~= "d") or not recordable(regname or "") then return end
  if type(contents) ~= "table" or #contents == 0 then return end
  for i = #ring, 1, -1 do
    if vim.deep_equal(ring[i].contents, contents) and ring[i].regtype == regtype then
      table.remove(ring, i)
    end
  end
  table.insert(ring, 1, { contents = vim.deepcopy(contents), regtype = regtype })
  if #ring > cfg.limit then table.remove(ring) end
end

local function default_register(r)
  return r == nil or r == "" or r == " " or r == DQ or r == "+" or r == "*"
end

local function render(buf, line, col, after, item, index, total)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  api.nvim_buf_set_extmark(buf, ns, line, 0, {
    virt_text = { { string.format(" [%d/%d]", index, total), cfg.label_hl } },
    virt_text_pos = "eol",
  })
  local hl = cfg.preview_hl
  if item.regtype == "V" then
    local virt_lines = {}
    for _, l in ipairs(item.contents) do
      table.insert(virt_lines, { { l, hl } })
    end
    api.nvim_buf_set_extmark(buf, ns, line, 0, {
      virt_lines = virt_lines,
      virt_lines_above = not after,
    })
  else
    api.nvim_buf_set_extmark(buf, ns, line, after and col + 1 or col, {
      virt_text = { { item.contents[1] or "", hl } },
      virt_text_pos = "inline",
    })
    if #item.contents > 1 then
      local virt_lines = {}
      for i = 2, #item.contents do
        table.insert(virt_lines, { { item.contents[i], hl } })
      end
      api.nvim_buf_set_extmark(buf, ns, line, 0, { virt_lines = virt_lines })
    end
  end
end

local function put_raw(contents, regtype, after)
  local ok, err = pcall(api.nvim_put, contents, regtype, after, false)
  if not ok then
    vim.notify("velcro: " .. tostring(err), vim.log.levels.ERROR)
  end
end

local function commit()
  if not session then return end
  local s = session
  session = nil
  pcall(api.nvim_buf_clear_namespace, s.buf, ns, 0, -1)
  if not api.nvim_buf_is_valid(s.buf) then return end
  local line, col = unpack(api.nvim_win_get_cursor(0))
  line = line - 1
  if api.nvim_get_current_buf() ~= s.buf or line ~= s.line or col ~= s.col then return end
  put_raw(s.contents, s.regtype, s.after)
end

local function start_timer()
  session.timer:stop()
  session.timer:start(cfg.delay, 0, vim.schedule_wrap(commit))
end

local function cancel()
  if not session then return end
  session.timer:stop()
  pcall(api.nvim_buf_clear_namespace, session.buf, ns, 0, -1)
  session = nil
end

local function paste(kind)
  local after = kind == "p"
  local reg = vim.v.register
  if vim.v.count > 1 then
    vim.cmd("normal! " .. vim.v.count .. (after and "p" or "P"))
    return
  end
  if not default_register(reg) then
    local i = vim.fn.getreginfo(reg)
    put_raw(i.regcontents, i.regtype, after)
    return
  end
  if #ring == 0 then
    local i = vim.fn.getreginfo(DQ)
    put_raw(i.regcontents, i.regtype, after)
    return
  end
  local buf = api.nvim_get_current_buf()
  local line, col = unpack(api.nvim_win_get_cursor(0))
  line = line - 1
  if session and session.buf == buf and session.line == line and session.col == col and session.after == after then
    session.index = session.index % #ring + 1
  else
    cancel()
    session = { buf = buf, line = line, col = col, after = after, index = 1, timer = uv.new_timer() }
  end
  local item = ring[session.index]
  session.contents = item.contents
  session.regtype = item.regtype
  local ok, err = pcall(render, buf, line, col, after, item, session.index, #ring)
  if not ok then
    cancel()
    vim.notify("velcro: preview failed: " .. tostring(err), vim.log.levels.WARN)
    return
  end
  start_timer()
end

M.setup = function(opts)
  cfg = vim.tbl_deep_extend("force", cfg, opts or {})
  cfg.limit = math.max(1, cfg.limit)
  cfg.delay = math.max(1, cfg.delay)
  while #ring > cfg.limit do table.remove(ring) end
  if configured then return end
  configured = true
  api.nvim_set_hl(0, cfg.preview_hl, { link = "Visual" })
  api.nvim_set_hl(0, cfg.label_hl, { link = "Comment" })
  local group = api.nvim_create_augroup("Velcro", { clear = true })
  api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
      local e = vim.v.event
      record(e.operator, e.regcontents, e.regtype, e.regname)
    end,
  })
  for _, ev in ipairs({ "CursorMoved", "CursorMovedI", "InsertEnter", "ModeChanged", "TextChanged", "TextChangedI", "BufLeave", "BufDelete", "VimLeavePre" }) do
    api.nvim_create_autocmd(ev, { group = group, callback = cancel })
  end
  for name, key in pairs(cfg.keys) do
    if key then
      vim.keymap.set("n", key, function()
        paste(name)
      end, { desc = "velcro: preview paste (" .. name .. ")" })
    end
  end
  api.nvim_create_user_command("VelcroCancel", cancel, {})
end

M.cancel = cancel
M.ring_size = function()
  return #ring
end

return M
