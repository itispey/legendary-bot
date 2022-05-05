local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function send_in_group(chat_id)
	local res = db:hget('chat:'..chat_id..':settings', 'Rules')
	if res == 'on' then
		return true
	else
		return false
	end
end

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type == 'private' then
		if blocks[1] == 'start' then
			msg.chat.id = tonumber(blocks[2])

			local res = api.getChat(msg.chat.id)
			if not res then
				api.sendMessage(msg.from.id, ("🚫 گروه پیدا نشد!"))
				return
			end
			-- Private chats have no an username
			local private = not res.result.username

			local res = api.getChatMember(msg.chat.id, msg.from.id)
			if not res or (res.result.status == 'left' or res.result.status == 'kicked') and private then
				api.sendMessage(msg.from.id, ("🚷 شما عضو این گروه نمی باشید! بنابرین نمی توانید قوانین این گروه را بخوانید."))
				return
			end
		else
			return
		end
	end

	local hash = 'chat:'..msg.chat.id..':info'
	if blocks[1]:lower() == 'rules' or blocks[1] == 'start' or blocks[1] == 'قوانین' then
		local rules = u.getRules(msg.chat.id)
		local reply_markup, rules = u.reply_markup_from_text(rules)
		local link_preview = rules:find('telegra%.ph/') ~= nil
		if msg.chat.type == 'private' or (not msg.from.admin and not send_in_group(msg.chat.id)) then
			api.sendMessage(msg.from.id, rules, true, reply_markup, nil, link_preview)
		else
			local res, code = api.sendReply(msg, rules, true, reply_markup, link_preview)
			if not res and code == 7 then
				local t = u.wrongFormat()
				api.sendReply(msg, t, true)
			end
		end
	end

	if not u.can(msg.chat.id, msg.from.id, 'can_change_info') then return end

	if blocks[1]:lower() == 'setrules' or blocks[1] == 'تنظیم قوانین' then
		local rules = blocks[2]
		--ignore if not input text
		if not rules then
			api.sendReply(msg, ("لطفا بعد از فاصله از دستور setrules/، متن قوانین خودتان را بنویسید.\n`Setrules قوانین گروه`"), true) return
		end
		local reply_markup, test_text = u.reply_markup_from_text(rules)
		local res, code = api.sendReply(msg, test_text, true, reply_markup)
		if not res then
			if code == 7 then
				local t = u.wrongFormat()
				api.sendReply(msg, t, true)
			else
				api.sendMessage(msg.chat.id, u.get_sm_error_string(code), true)
			end
		else
			db:hset(hash, 'rules', rules)
			local id = res.result.message_id
			api.editMessageText(msg.chat.id, id, ("قوانین با موفقیت ذخیره شدند."), true)
		end
	end

	if blocks[1]:lower() == 'delrules' or blocks[1] == 'حذف قوانین' then
		db:hdel(hash, 'rules')
		api.sendReply(msg, 'قوانین با موفقیت حذف شدند.')
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(setrules)$',
		config.cmd..'(setrules) (.*)',
		config.cmd..'(rules)$',
		config.cmd..'(delrules)$',
		-----------------------
		'^([Ss]etrules)$',
		'^([Ss]etrules) (.*)',
		'^([Rr]ules)$',
		'^([Dd]elrules)$',
		-----------------------
		'^(تنظیم قوانین)$',
		'^(تنظیم قوانین) (.*)',
		'^(قوانین)$',
		'^(حذف قوانین)$',
		'^/(start) (-?%d+)_rules$'
	}
}

return plugin
