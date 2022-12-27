-- TODO: major refacor needed (use ipc instead?)
-- TODO: mouse support, implement queue, fix playlist bug, (maybe an optional discord presence)
-- TODO: dont update buffer extmark if buffer not shown
-- TODO: maybe a small visualizer
-- TODO: cleanify (priority: 1)

--- Basically call the toggle_player function to toggle the player window (runs on mpv + youtube-dl)
--- <CR> will prompt for song name or youtube link to play (playlist is kinda buggy)
--- p: pause/play                q: quit               m: mute
--- >: next                      <: prev (in playlists)

local M = {buf=nil, win=nil, ns=vim.api.nvim_create_namespace("player"), content_id=nil, title_id=nil}
local conf = { width=50, height=5 }
local state = {playing=false, jobid=nil, title=nil, paused=false, timing="", percent=0, muted=false, loaded=false}
local win_opts = {relative='editor', style='minimal', border='single', row=1, col=vim.o.columns-conf.width-2, height=conf.height, width=conf.width } -- , title='PLAYER', title_pos='center' }
local hls = {title="String", timer="Identifier", progress="Function"}

-- NOTE: for statusline components
M.music_info = function() return state end

local by3 = (" "):rep(math.floor(conf.width/4)-1)
local refresh_screen = function()
    local chars = { "🯅", "🯆", "🯇", "🯈" }
    local char = chars[math.floor(math.random() * #chars) + 1]

    local dur = math.floor((state.percent/100) * conf.width)
    vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_text = {{state.title, hls.title}}, virt_text_pos='overlay',
        id=M.title_id
    })

    local time1, time2 = unpack(vim.split(state.timing, ' / '))
    vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_lines={
            {
                {time1, hls.timer}, {(" "):rep(conf.width - 16)}, {time2, hls.timer}
            },
            {
                {("▁"):rep(dur), hls.progress}, {char, hls.progress}, {("▁"):rep(conf.width-dur), "Comment"}
            },
            {{"", ""}},
            {
                {by3.."ﲑ", hls.progress}, {by3..(not state.paused and "" or ""), hls.progress}, {by3.."ﲒ", hls.progress}
            }
        },
        id=M.content_id
    })
end

local left_mouse = function()
    local mouse = vim.fn.getmousepos()
    if M.win ~= mouse.winid then return end

    local pause = math.floor(conf.width/2)
    local prev = math.floor(conf.width/4)
    local next = math.floor(3 * (conf.width/4))
    if (mouse.winrow-1) == conf.height and math.abs(pause - mouse.wincol) < 3 then
        state.paused = not state.paused
        vim.api.nvim_chan_send(state.jobid, 'p')
        -- vim.pretty_print("Clear")
    elseif (mouse.winrow-1) == conf.height and math.abs(prev - mouse.wincol) < 3 then
        vim.api.nvim_chan_send(state.jobid, '<')
    elseif (mouse.winrow-1) == conf.height and math.abs(next - mouse.wincol) < 3 then
        vim.api.nvim_chan_send(state.jobid, '>')
    end
    refresh_screen()
end

M.toggle_player = function()
    if state.loaded then
        vim.api.nvim_win_hide(M.win)
        state.loaded = false
        return
    end

    M.buf = vim.api.nvim_create_buf(false, true)
    M.win = vim.api.nvim_open_win(M.buf, true, win_opts)

    M.title_id = vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_text={{state.title or '', hls.title}}, virt_text_pos='overlay'
    })

    M.content_id = vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_lines={
            {
                {state.timing, hls.timer}
            },
            {
                {("▁"):rep(math.floor((state.percent/100) * conf.width)), hls.progress}
            },
            {{"", ""}},
            {
                {by3.."ﲑ", hls.progress}, {by3..(state.paused and "" or ""), hls.progress}, {by3.."ﲒ", hls.progress}
            }
        },
    })

    vim.keymap.set({'n', 'i'}, '<CR>', function()
        if state.playing then
            vim.fn.jobstop(state.jobid)
            state.playing = false
            state.title = nil
        end

        vim.ui.input({width=40}, function(query)
            if query == "" then
                vim.notify("Query not provided!")
                return
            end

            M.title_id = vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
                virt_text={{'Searching for "'..query..'"...', hls.title}}, virt_text_pos='overlay', id=M.title_id
            })

            if not query:match([[https://(www.)\?youtube.com]]) then
                query = "ytdl://ytsearch:"..table.concat(vim.split(query, ' '), '+')
            end

            local command = {"mpv", "--term-playing-msg='${media-title}'", "--no-video", query}

            state.jobid = vim.fn.jobstart(command, {
                pty=true,
                on_stdout=function(_, data)
                    if data then
                        local time = data[1]:match([[%d%d:%d%d:%d%d / %d%d:%d%d:%d%d]])
                        local percent = data[1]:match([[(%d%d?%%)]])
                        if percent then state.percent=percent:sub(1, -2) end

                        if not data[1]:match("A:") and not data[1]:match("AO:") then
                            state.title = data[1]:match([['(.*)']]) or state.title
                        end

                        if time then
                            if state.timing ~= time then
                                state.timing = time
                                refresh_screen()
                            end
                        end
                    end
                end,
                on_exit = function()
                    state.playing = false
                    state.title = nil
                end
            })
            state.playing = true
        end)
    end, {buffer=M.buf})

    local map = function(bind, to, fn)
        vim.keymap.set('n', bind, function()
            vim.api.nvim_chan_send(state.jobid, to)
            if fn then fn() end
            refresh_screen()
        end, {buffer=M.buf})
    end

    map('q', 'q', function()
        state.title = 'Not Playing.'
        state.percent = 0
        refresh_screen()
    end)
    map('p', 'p', function() state.paused = not state.paused end)
    map('<space>', 'p', function() state.paused = not state.paused end)
    map('m', 'm', function() state.muted = not state.muted end)
    map('>', '>')
    map('<', '<')
    map('<LeftMouse>', '', left_mouse)
    -- TODO: add other keys like left and right
    -- map('<Left>', '\\e[[D')
    -- map('<Right>', "\\e[[C")
    state.loaded = true
end

return M
