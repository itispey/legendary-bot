local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type == 'private' then return end

	if u.is_superadmin(msg.from.id) then
		if blocks[1] == 'setsupportlink' then
			local link = blocks[2]
			if link then
				local data = u.loadFile(config.info_path) or {}
				data['support_info'] = {
					chat_id = msg.chat.id,
					chat_link = link
				}
				u.saveFile(config.info_path, data)
				api.sendReply(msg, 'لینک گروه پشتیبانی آپدیت شد.')
			end
		end
	end

	if not u.can(msg.chat.id, msg.from.id, 'can_invite_users') then return end
	local hash = 'chat:'..msg.chat.id..':info'
	local text

	if blocks[1]:lower() == 'link' or blocks[1] == 'لینک' then
		local link = db:hget(hash, 'link')
		local keyboard
		if not link then
			local link = api.exportChatInviteLink(msg.chat.id)
			if link then
				db:hset(hash, 'link', link.result)
				text = ('برای مشاهده لینک، روی یکی از گزینه های زیر بزنید.')
				keyboard = {inline_keyboard = {
					{{text = "به اشتراک گذاشتن 🚀", url = "https://t.me/share/url?url="..link.result}},
					{{text = "مشاهده لینک 📄", callback_data = "link:show_link:"..link.result}},
					{{text = "ارسال لینک به پیوی 👤", callback_data = "link:send_pv:"..link.result}}
				}}
			else
				text = 'لطفا با دستور setlink/ لینک گروه خودتان را تنظیم کنید.'
			end
		else
			text = ('برای مشاهده لینک، روی یکی از گزینه های زیر بزنید.')
			keyboard = {inline_keyboard = {
				{{text = "به اشتراک گذاشتن 🚀", url = "https://t.me/share/url?url="..link}},
				{{text = "مشاهده لینک 📄", callback_data = "link:show_link:"..link}},
				{{text = "ارسال لینک به پیوی 👤", callback_data = "link:send_pv:"..link}}
			}}
		end
		api.sendReply(msg, text, true, keyboard)
	end

	if blocks[1]:lower() == 'setlink' or blocks[1] == 'ذخیره لینک' then
		local link
		if not blocks[2] then
			text = 'لطفا بعد از دستور، لینک گروه خودتان را بگذارید.\n<code>/setlink https://t.me/joinchat/sKSFGfasfasGSDGSD</code>'
		else
			if string.len(blocks[2]) ~= 22 then
				text = 'لینک اشتباه می باشد.'
			else
				link = 'https://telegram.me/joinchat/'..blocks[2]
				db:hset(hash, 'link', link)
				text = 'لینک گروه شما با موفقیت ذخیره شد!'
			end
		end
		api.sendReply(msg, text)
	end

	if blocks[1]:lower() == 'change link' or blocks[1] == 'تغییر لینک' then
		local get_link = api.exportChatInviteLink(msg.chat.id).result
		db:hset(hash, 'link', get_link)
		api.sendReply(msg, 'لینک گروه شما با موفقیت تغییر کرد!')
	end
end

function plugin.onCallbackQuery(msg, blocks)
	if msg.from.admin then
		if blocks[1] == 'show_link' then
			local link = blocks[2]
			api.editMessageText(msg.chat.id, msg.message_id, ("[برای کپی کردن لینک، روی متن نگه دارید.](%s)"):format(link), true)
		end
		if blocks[1] == 'send_pv' then
			local res = api.sendMessage(msg.from.id, blocks[2])
			if not res then
				api.editMessageText(msg.chat.id, msg.message_id, "❌ لینک ارسال نشد!\nلطفا اول ربات را استارت کنید :)")
				return
			end
			api.editMessageText(msg.chat.id, msg.message_id, "✅ لینک با موفقیت به پیوی شما ارسال شد.")
		end
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(setsupportlink) (.*)$',
		config.cmd..'(setlink)$',
		config.cmd..'(setlink) https://telegram%.me/joinchat/(.*)',
		config.cmd..'(setlink) https://t%.me/joinchat/(.*)',
		config.cmd..'(link)$',
		config.cmd..'(change link)$',
		-----------------------------
		'^([Ss]etlink)$',
		'^([Ss]etlink) https://telegram%.me/joinchat/(.*)',
		'^([Ss]etlink) https://t%.me/joinchat/(.*)',
		'^([Ll]ink)$',
		'^([Cc]hange link)$',
		'^(تغییر لینک)$',
		'^(لینک)$',
		'^(ذخیره لینک)$',
		'^(ذخیره لینک) https://telegram%.me/joinchat/(.*)',
		'^(ذخیره لینک) https://t%.me/joinchat/(.*)'
	},
	onCallbackQuery = {
		'^###cb:link:(show_link):(.*)$',
		'^###cb:link:(send_pv):(.*)$'
	}
}

return plugin
