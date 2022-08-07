local M = {}
local toggle_bookmark = false
local map = {
    a="ᵃ",b="ᵇ",c="ᶜ",d="ᵈ",e="ᵉ",f="ᶠ",g="ᵍ",h="ʰ",i="ⁱ",j="ʲ",k="ᵏ",l="ˡ", m="ᵐ",
    n="ⁿ",o="ᵒ", p="ᵖ",q="q",r="ʳ",s="ˢ",t="ᵗ",u="ᵘ",v="ᵛ",w="ʷ",x="ˣ",y="ʸ",z="ᶻ"
}

local toggle = function()
    local id=0
	toggle_bookmark = not toggle_bookmark
	for letter, sub in pairs(map) do -- 📑          🔖
		local row, col = unpack(vim.api.nvim_buf_get_mark(0, letter))

		if row ~= 0 or col ~= 0 then
            id = id + 1

			if toggle_bookmark then
				vim.b.bookmark = " "
				vim.fn.sign_define("nicemark"..letter, {text=sub or "", texthl="Function"})
				vim.fn.sign_place(id, 'nicemark', "nicemark"..letter, vim.api.nvim_buf_get_name(0), {lnum=row})
			elseif not toggle_bookmark then
				vim.b.bookmark = " "
				vim.fn.sign_undefine("nicemark"..letter)
				vim.fn.sign_unplace("nicemark", {id=id, buffer=vim.api.nvim_get_current_buf()})
			else
				return
			end

		end
	end
end

M.setup = function()
	-- vim.keymap.set('n', '<leader>b', toggle, {silent=true})
    vim.api.nvim_create_user_command('Bt', toggle, {})
end

return M
