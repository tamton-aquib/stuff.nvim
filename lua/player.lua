-- TODO: major refacor needed (use ipc instead)
-- TODO: mouse support, implement queue, fix playlist bug, (maybe an optional discord presence)
-- TODO: dont update buffer extmark if buffer not shown
-- TODO: maybe a small visualizer

--- Basically call the toggle_player function to toggle the player window (runs on mpv + youtube-dl)
--- <CR> will prompt for song name or youtube link to play (playlist is kinda buggy)
--- p: pause/play                q: quit               m: mute
--- >: next                      <: prev (in playlists)

local M = {buf=nil, win=nil, ns=vim.api.nvim_create_namespace("player"), content_id=nil, title_id=nil}
local conf = { width=50, height=5 }
local state = {playing=false, jobid=nil, title="", paused=false, timing="", percent=0, muted=false, loaded=false}
local win_opts = { relative='editor', style='minimal', border='single', row=0, col=vim.o.columns-conf.width-2, height=conf.height, width=conf.width } -- , title='PLAYER', title_pos='center' }

-- NOTE: for statusline components
M.music_info = function() return state end

local by3 = (" "):rep(math.floor(conf.width/4)-1)
local refresh_screen = function()
    local dur = math.floor((state.percent/100) * conf.width)
    vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_text = {{state.title, "Function"}}, virt_text_pos='overlay',
        id=M.title_id
    })

    local time1, time2 = unpack(vim.split(state.timing, ' / '))
    vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_lines={
            {
                {time1, "Function"}, {(" "):rep(conf.width - 16)}, {time2, "Function"}
            },
            {
                {("▁"):rep(dur), "Function"}, {"", "PlayerGreen"}, {("▁"):rep(conf.width-dur), "Comment"}
            },
            {{"", ""}},
            {
                {by3.."ﲑ", "Function"}, {by3..(not state.paused and "" or ""), "Function"}, {by3.."ﲒ", "Function"}
            }
        },
        id=M.content_id
    })
end

M.toggle_player = function()
    vim.api.nvim_set_hl(0, 'PlayerGreen', {fg="#95c561",underline=true, bold=true})
    if state.loaded then
        vim.api.nvim_win_hide(M.win)
        state.loaded = false
        return
    end

    M.buf = vim.api.nvim_create_buf(false, true)
    M.win = vim.api.nvim_open_win(M.buf, true, win_opts)

    M.title_id = vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_text={{state.title, "Function"}}, virt_text_pos='overlay'
    })

    M.content_id = vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
        virt_lines={
            {
                {state.timing, "Function"}
            },
            {
                {("▁"):rep(math.floor((state.percent/100) * conf.width)), "Function"}
            },
            {{"", ""}},
            {
                {by3.."ﲑ", "Function"}, {by3..(state.paused and "" or ""), "Function"}, {by3.."ﲒ", "Function"}
            }
        },
    })

    vim.keymap.set({'n', 'i'}, '<CR>', function()
        if state.playing then
            vim.fn.jobstop(state.jobid)
            state.playing = false
            state.title = ""
        end

        vim.ui.input({width=40}, function(query)
            if query == "" then
                vim.notify("Query not provided!")
                return
            end

            M.title_id = vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
                virt_text={{'Searching for "'..query..'"...', "Function"}}, virt_text_pos='overlay', id=M.title_id
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
    map('m', 'm', function() state.muted = not state.muted end)
    map('>', '>')
    map('<', '<')
    -- map('<Left>', '\\e[[D')
    -- map('<Right>', "\\e[[C")
    state.loaded = true
end

return M
