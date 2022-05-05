local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local JSON = require 'dkjson'

local plugin = {}
--------------------------------------------------------------------------------
function plugin.onTextMessage(msg, blocks)
	if msg.from.admin then
		if not u.can(msg.chat.id, msg.from.id, "can_restrict_members") then
			api.sendReply(msg, "شما دسترسی محدودیت اعضا را ندارید!")
			return
		end
		----------------------------------------------------------------------------
		local chat_id = msg.chat.id
		if blocks[1]:lower() == 'silent' then
			local text, get_t, calc, fa
			if not msg.reply or not blocks[2] then
				text = ("لطفا روی یک کاربری ریپلای کنید و زمان آن را بنویسید.")
			else
				local user_id = msg.reply.from.id
				if user_id == bot.id then
					api.sendReply(msg, "شما نمی توانید ربات را روی حالت سایلنت بگذارید.")
					return
				elseif u.is_admin(chat_id, user_id) then
					api.sendReply(msg, "شما نمی توانید ادمین ها رو سایلنت کنید.")
					return
				else
					local name = u.getname_final(msg.reply.from)
					local admin = u.getname_final(msg.from)
					if blocks[2] then
						if blocks[2]:match('(%d+)%s?mo') then
							get_t = blocks[2]:match('(%d+)%s?mo')
							if tonumber(get_t) > 12 then
								api.sendReply(msg, 'شما نمی توانید بیشتر از *12* ماه کسی رو سایلنت کنید!', true)
								return
							else
								calc = (tonumber(get_t) * 2592000) + os.time() -- month
								print(string.format("User muted %s month(s)", calc))
								fa = tonumber(get_t)..' ماه'
							end
						elseif blocks[2]:match('(%d+)%s?w') then
							get_t = blocks[2]:match('(%d+)%s?w')
							if tonumber(get_t) > 48 then
								api.sendReply(msg, 'شما نمی توانید کسی رو بیشتر از *48* هفته سایلنت کنید.', true)
								return
							else
								calc = (tonumber(get_t) * 604800) + os.time() -- week
								print(string.format("User muted %s week(s)", calc))
								fa = tonumber(get_t)..' هفته'
							end
						elseif blocks[2]:match('(%d+)%s?d') then
							get_t = blocks[2]:match('(%d+)%s?d')
							if tonumber(get_t) > 360 then
								api.sendReply(msg, 'شما نمی توانید کسی را بیشتر از *360* روز سایلنت کنید.', true)
								return
							else
								calc = (tonumber(get_t) * 86400) + os.time() -- day
								print(string.format("User muted %s day(s)", calc))
								fa = tonumber(get_t)..' روز'
							end
						elseif blocks[2]:match('(%d+)%s?h') then
							get_t = blocks[2]:match('(%d+)%s?h')
							if tonumber(get_t) > 8640 then
								api.sendReply(msg, 'شما نمی توانید کسی رو بیشتر از *8640* ساعت (1 سال) سایلنت کنید.', true)
								return
							else
								calc = (tonumber(get_t) * 3600) + os.time() -- hour
								print(string.format("User muted %s hour(s)", calc))
								fa = tonumber(get_t)..' ساعت'
							end
						elseif blocks[2]:match('[Ff]orever') then
							calc = nil
							fa = nil
						else
							api.sendReply(msg, 'دستور را اشتباه نوشتید!\nلطفا دستور help/ را در پیوی ربات ارسال کنید و راهنمای بخش "بی صدا کردن کاربران" را بخوانید.')
							return
						end
					end
					local res = api.muteUser(chat_id, user_id, calc)
					if not res then
						api.sendReply(msg, '🔸 من نمی توانم این کاربر را بی صدا کنم!\nاحتمالا این کاربر ادمین هست یا من دسترسی محدودیت اعضا را ندارم.')
						return
					end
					u.logEvent('silent', msg, {time = fa, admin = admin, user = name, user_id = user_id})
					if fa ~= nil then
						local getDate = u.getShamsiTime(calc)
						text = ([[
🔸 کاربر %s به مدت [%s] توانایی چت کردن نخواهد داشت!
• تا تاریخ : %s

🔹 محدودیت توسط ادمین: (%s)
						]])
						:format(name, fa, getDate, admin)
						db:hset('chat:'..chat_id..':silent', user_id, name..':'..getDate)
					else
						db:hset('chat:'..chat_id..':silent', user_id, name..":برای همیشه")
						text = ('🔻 کاربر %s برای همیشه بی صدا شد.\n\n🔹 محدودیت توسط ادمین: (%s)'):format(name, admin)
					end
				end
			end
			api.sendReply(msg, text, 'html')
		end
		--------------------------------------------------------------------------
		if blocks[1]:lower() == 'unsilent' then
			if not msg.reply and (not blocks[2] or (not blocks[2]:match('@[%w_]+$') and not blocks[2]:match('%d+$') and not msg.mention_id)) then
				api.sendReply(msg, 'لطفا روی یک کاربر ریپلای کنید یا از نام کاربری یا آیدی عددی اون کاربر استفاده کنید.\n`/unsilent @username`', true)
				return
			end
			local user_id, error = u.get_user_id(msg, blocks)
			if not user_id then
				api.sendReply(msg, error)
				return
			elseif user_id == bot.id then
				return
			elseif u.is_admin(chat_id, user_id) then
				return
			else
				local res = api.getChatMember(chat_id, user_id)
				local name, admin = u.getname_final(res.result.user), u.getname_final(msg.from)
				db:hdel('chat:'..chat_id..':silent', user_id)
				text = ("🔸 کاربر %s از حالت سایلنت خارج شد و هم اکنون توانایی چت کردن را دارد.\n🔹 توسط ادمین: (%s)"):format(name, admin)
				local change_permis = {
					can_send_messages = true,
					can_send_media_messages = true,
					can_send_other_messages = true,
					can_add_web_page_previews = true
				}
				u.logEvent('unsilent', msg, {admin = admin, user = name, user_id = user_id})
				local res = api.restrictChatMember(chat_id, user_id, change_permis)
				if not res then
					api.sendReply(msg, '🔸 من نمی توانم این کاربر را بی صدا کنم!\nاحتمالا این کاربر ادمین هست یا من دسترسی محدودیت اعضا را ندارم.')
					return
				end
				api.sendReply(msg, text, 'html')
				return
			end
		end
		--------------------------------------------------------------------------
		if blocks[1]:lower() == 'silentlist' then
			local text = '🔸 لیست اسامی سایلنت شده های گروه:\n\n'
			local users = db:hgetall('chat:'..chat_id..':silent')
			local i = 1
			if next(users) then
				for user_id, info in pairs(users) do
					local name, date = info:match('(.*):(.*)')
					text = text..i..'. '..name..'\n'..date..'\n\n'
					i = i + 1
				end
			else
				text = '🔻 لیست اسامی سایلنت شده های گروه، خالی می باشد.'
			end
			api.sendReply(msg, text, 'html')
		end

	end
	
end
--------------------------------------------------------------------------------
function plugin.onEveryMessage(msg) -- remove from silentlist if he's already unsilent
	if db:hget('chat:'..msg.chat.id..':silent', msg.from.id) then
		db:hdel('chat:'..msg.chat.id..':silent', msg.from.id)
	end
	return true
end
--------------------------------------------------------------------------------
plugin.triggers = {
	onTextMessage = {
    	config.cmd..'(silent)$',
		config.cmd..'(silent) (.+)$',
		config.cmd..'(unsilent)$',
		config.cmd..'(unsilent) (.+)$',
		config.cmd..'(silentlist)$',
		-----------------------------
    	'^([Ss]ilent)$',
		'^([Ss]ilent) (.+)$',
		'^([Uu]nsilent)$',
		'^([Uu]nsilent) (.+)$',
		'^([Ss]ilentlist)$'
  }
}

return plugin
