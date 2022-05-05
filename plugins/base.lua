local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local JSON = require 'dkjson'

local plugin = {}

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type ~= 'private' then
		if msg.from.admin then

			if blocks[1]:lower() == 'del' or blocks[1] == 'حذف' then
				if msg.reply then
					api.deleteMessage(msg.chat.id, msg.reply.message_id)
					api.deleteMessage(msg.chat.id, msg.message_id)
					return
				end
			end

		end

		if blocks[1] == 'setsupport' and u.is_superadmin(msg.from.id) then
			local data = u.loadFile(config.info_path) or {}
			local link = api.exportChatInviteLink(msg.chat.id).result
			data['support_info'] = {
				link = link,
				id = msg.chat.id
			}
			u.saveFile(config.info_path, data)
			api.sendReply(msg, 'اطلاعات گروه پشتیبانی با موفقیت بروزرسانی شد.')
		end

		if blocks[1]:lower() == 'echo' or blocks[1] == 'اکو' and msg.from.admin then
			if msg.reply then
				api.sendMessage(msg.chat.id, blocks[2], nil, nil, msg.reply.message_id)
			else
				api.sendMessage(msg.chat.id, blocks[2])
			end
		end

		if blocks[1]:lower() == 'dicko' and msg.from.admin then
			if msg.reply then
				api.deleteMessage(msg.chat.id, msg.message_id)
				api.sendMessage(msg.chat.id, blocks[2], nil, nil, msg.reply.message_id)
			else
				api.deleteMessage(msg.chat.id, msg.message_id)
				api.sendMessage(msg.chat.id, blocks[2])
			end
		end

		if blocks[1]:lower() == 'ping' or blocks[1] == 'پینگ' and msg.from.admin then
			local ping = os.time() - msg.date
			api.sendReply(msg, ("✅ ربات هم اکنون آنلاین می باشد!\nپینگ از سرور: %s میلی ثانیه"):format(ping * 1000))
		end
	end

	if blocks[1] == 'dump' then
		api.sendReply(msg, u.vtext(msg.reply))
	end

end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(setsupport)$',
		config.cmd..'(dump)$',
		config.cmd..'(del)$',
		config.cmd..'(echo) (.*)$',
		config.cmd..'(dicko) (.*)$',
		config.cmd..'(ping)$',
		--------------------------
		'^([Dd]el)$',
		'^([Ee]cho) (.*)$',
		'^([Dd]icko) (.*)$',
		'^([Pp]ing)$',
		--------------------------
		'^(پینگ)$',
		'^(حذف)$',
    	'^(اکو) (.*)$'
	}
}

return plugin
