local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function markup_tempban(chat_id, user_id, time_value)
	local key = ('chat:%s:%s:tbanvalue'):format(chat_id, user_id)
	local time_value = time_value or (db:get(key) or 3)

	local markup = {inline_keyboard={
		{--first line
			{text = '-', callback_data = ('tempban:val:m:%s:%s'):format(user_id, chat_id)},
			{text = '🕑 '..time_value, callback_data = 'tempban:nil'},
			{text = '+', callback_data = ('tempban:val:p:%s:%s'):format(user_id, chat_id)}
		},
		{--second line
			{text = 'دقیقه', callback_data = ('tempban:ban:m:%s:%s'):format(user_id, chat_id)},
			{text = 'ساعت', callback_data = ('tempban:ban:h:%s:%s'):format(user_id, chat_id)},
			{text = 'روز', callback_data = ('tempban:ban:d:%s:%s'):format(user_id, chat_id)},
		}
	}}

	return markup
end

local function get_motivation(msg)
	if msg.reply then
		return msg.text:match("ban (.+)") or msg.text:match("kick (.+)") or msg.text:match("tempban .+\n(.+)")
	else
		if msg.text:find("ban @%w[%w_]+ ") or msg.text:find("kick @%w[%w_]+ ") then
			return msg.text:match("ban @%w[%w_]+ (.+)") or msg.text:match("kick @%w[%w_]+ (.+)")
		elseif msg.text:find("ban %d+ ") or msg.text:find("kick %d+ ") then
			return msg.text:match("ban %d+ (.+)") or msg.text:match("kick %d+ (.+)")
		elseif msg.entities then
			return msg.text:match("ban .+\n(.+)") or msg.text:match("kick .+\n(.+)")
		end
	end
end

local function check_valid_time(temp)
	temp = tonumber(temp)
	if temp == 0 then
		return false, 1
	elseif temp > 168 then --1 week
		return false, 2
	else
		return temp
	end
end

local function get_hours_from_string(input)
	if input:match('^%d+$') then
		return tonumber(input)
	else
		local days = input:match('(%d)%s?d')
		if not days then days = 0 end
		local hours = input:match('(%d%d?)%s?h')
		if not hours then hours = 0 end
		if not days and not hours then
			return input:match('(%d+)')
		else
			return ((tonumber(days))*24)+(tonumber(hours))
		end
	end
end

local function get_time_reply(hours)
	local time_string = ''
	local time_table = {}
	time_table.days = math.floor(hours/24)
	time_table.hours = hours - (time_table.days*24)
	if time_table.days ~= 0 then
		time_string = time_table.days..' روز '
	end
	if time_table.hours ~= 0 then
		time_string = time_string..' '..time_table.hours..' ساعت '
	end
	return time_string, time_table
end

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type ~= 'private' then
		if u.can(msg.chat.id, msg.from.id, "can_restrict_members") then

			local user_id, error_translation_key = u.get_user_id(msg, blocks)

			if not user_id and blocks[1] ~= 'kickme' and blocks[1] ~= 'fwdban' then
				api.sendReply(msg, error_translation_key, true) return
			end
			if tonumber(user_id) == bot.id then return end

			local res
			local chat_id = msg.chat.id
			local check = api.getChatMember(chat_id, user_id)
			if not check then
				api.sendReply(msg, 'کاربر مورد نظر در گروه نمی باشد.')
				return
			end
			local admin, kicked = u.getname_final(msg.from), u.getname_final(check.result.user)

			print(clr.blue..get_motivation(msg)..clr.reset)

			if blocks[1]:lower() == 'tempban' then
				local time_value = msg.text:match(("tempban.*\n(%d+)"))
				if time_value then --save the time value passed by the user
					if tonumber(time_value) > 100 then
						time_value = 100
					end
					local key = ('chat:%s:%s:tbanvalue'):format(msg.chat.id, user_id)
					db:setex(key, 3600, time_value)
				end

				local markup = markup_tempban(msg.chat.id, user_id)
				api.sendReply(msg, ('از دکمه های + یا - برای کم و زیاد کردن عدد استفاده کنید. سپس زمان مورد نظر خودتان را انتخاب کنید.'), nil, markup)
			end
			if blocks[1]:lower() == 'kick' or blocks[1] == 'اخراج' then
				local res, code, motivation = api.kickUser(chat_id, user_id)
				if not res then
					if not motivation then
						motivation = ("من نمی توانم این کاربر رو اخراج کنم!\nبه احتمال زیاد، من ادمین نیستم یا این کاربر ادمین می باشد.")
					end
					api.sendReply(msg, motivation, true)
				else
					u.logEvent('kick', msg, {motivation = get_motivation(msg), admin = admin, user = kicked, user_id = user_id})
					api.sendMessage(msg.chat.id, ("کاربر %s توسط ادمین %s اخراج شد."):format(kicked, admin), 'html')
				end
			end
			if blocks[1]:lower() == 'ban' or blocks[1]:lower() == 'dban' or blocks[1] == 'مسدود' then
				local res, code, motivation = api.banUser(chat_id, user_id)
				if not res then
					if not motivation then
						motivation = ("من نمی توانم این کاربر رو اخراج کنم!\nبه احتمال زیاد، من ادمین نیستم یا این کاربر ادمین می باشد.")
					end
					api.sendReply(msg, motivation, true)
				else
					u.logEvent('ban', msg, {motivation = get_motivation(msg), admin = admin, user = kicked, user_id = user_id})
					api.sendMessage(msg.chat.id, ("کاربر %s توسط ادمین %s مسدود شد."):format(kicked, admin), 'html')
					if blocks[1]:lower() == 'dban' and msg.reply then
						api.deleteMessage(chat_id, msg.reply.message_id)
					end
				end
			end
			if blocks[1]:lower() == 'fwdban' then
				if not msg.reply or not msg.reply.forward_from then
					api.sendReply(msg, ("لطفا روی یک پیام فوروارد شده از کاربر ریپلای کنید و این دستور را بزنید."), true)
				else
					user_id = msg.reply.forward_from.id
					local res, code, motivation = api.banUser(chat_id, user_id)
					if not res then
						if not motivation then
							motivation = ("من نمی توانم این کاربر رو اخراج کنم!\nبه احتمال زیاد، من ادمین نیستم یا این کاربر ادمین می باشد.")
						end
						api.sendReply(msg, motivation, true)
					else
						u.logEvent('ban', msg, {motivation = get_motivation(msg), admin = admin, user = kicked, user_id = user_id})
						api.sendMessage(msg.chat.id, ("کاربر %s توسط ادمین %s مسدود شد."):format(u.getname_final(msg.reply.forward_from), admin), 'html')
					end
				end
			end
			if blocks[1]:lower() == 'unban' or blocks[1] == 'حذف مسدود' then
				if u.is_admin(chat_id, user_id) then
					api.sendReply(msg, 'این کاربر هم اکنون ادمین می باشد!')
					return
				end
				if check.result.status ~= 'kicked' then
					api.sendReply(msg, 'این کاربر اخراج نشده است یا بعد از اخراج شدن توسط یک ادمین دیگر آنبن شده است.')
					return
				end
				local res, code = api.unbanChatMember(chat_id, user_id)
				if res then
					u.logEvent('unban', msg, {motivation = get_motivation(msg), admin = admin, user = kicked, user_id = user_id})
					api.sendReply(msg, ("کاربر %s توسط ادمین %s از لیست مسدودی ها خارج شد."):format(kicked, admin), 'html')
				end
			end
		end
	end
end

function plugin.onCallbackQuery(msg, matches)
	if not u.can(msg.chat.id, msg.from.id, 'can_restrict_members') then
		api.answerCallbackQuery(msg.cb_id, ("شما دسترسی اخراج کردن کاربران را ندارید."), true)
	else
		if matches[1] == 'nil' then
			api.answerCallbackQuery(msg.cb_id, ("از دکمه های + یا - برای کم و زیاد کردن عدد استفاده کنید. سپس زمان مورد نظرتان را انتخاب کنید."), true)
		elseif matches[1] == 'val' then
			local user_id = matches[3]
			local key = ('chat:%d:%s:tbanvalue'):format(msg.chat.id, user_id)
			local current_value, new_value
			current_value = tonumber(db:get(key) or 3)
			if matches[2] == 'm' then
				new_value = current_value - 1
				if new_value < 1 then
					api.answerCallbackQuery(msg.cb_id, ("شما نمی توانید از عدد 1 پایین تر بیایید."))
					return --don't proceed
				else
					db:setex(key, 3600, new_value)
				end
			elseif matches[2] == 'p' then
				new_value = current_value + 1
				if new_value > 100 then
					api.answerCallbackQuery(msg.cb_id, ("صبر کنید! یکم آروم تر :)"), true)
					return --don't proceed
				else
					db:setex(key, 3600, new_value)
				end
			end

			local markup = markup_tempban(msg.chat.id, user_id, new_value)
			api.editMessageReplyMarkup(msg.chat.id, msg.message_id, markup)
		elseif matches[1] == 'ban' then
			local user_id = matches[3]
			local key = ('chat:%d:%s:tbanvalue'):format(msg.chat.id, user_id)
			local time_value = tonumber(db:get(key) or 3)
			local timeframe_string, until_date
			if matches[2] == 'h' then
				time_value = time_value <= 24 and time_value or 24
				timeframe_string = ('ساعت')
				until_date = msg.date + (time_value * 3600)
			elseif matches[2] == 'd' then
				time_value = time_value <= 30 and time_value or 30
				timeframe_string = ('روز')
				until_date = msg.date + (time_value * 3600 * 24)
			elseif matches[2] == 'm' then
				time_value = time_value <= 60 and time_value or 60
				timeframe_string = ('دقیقه')
				until_date = msg.date + (time_value * 60)
			end
			local res, code, motivation = api.banUser(msg.chat.id, user_id, until_date)
			if not res then
				motivation = motivation or ("من نمی توانم این کاربر رو اخراج کنم!\nبه احتمال زیاد، من ادمین نیستم یا این کاربر ادمین می باشد.")
				api.editMessageText(msg.chat.id, msg.message_id, motivation)
			else
				local text = ("کاربر مورد نظر به مدت %d %s مسدود شد."):format(time_value, timeframe_string)
				api.editMessageText(msg.chat.id, msg.message_id, text)
				db:del(key)
			end
		end
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(kick) (.+)',
		config.cmd..'(kick)$',
		config.cmd..'(ban) (.+)',
		config.cmd..'(ban)$',
		config.cmd..'(dban)$',
		config.cmd..'(fwdban)$',
		config.cmd..'(tempban)$',
		config.cmd..'(tempban) (.+)',
		config.cmd..'(unban) (.+)',
		config.cmd..'(unban)$',
		---------------------
		'^([Kk]ick) (.+)',
		'^([Kk]ick)$',
		'^([Bb]an) (.+)',
		'^([Bb]an)$',
		'^([Dd]ban)$',
		'^([Ff]wdban)$',
		'^([Tt]empban)$',
		'^([Tt]empban) (.+)',
		'^([Uu]nban) (.+)',
		'^([Uu]nban)$'
	},
	onCallbackQuery = {
		'^###cb:tempban:(val):(%a):(%d+):(-%d+)',
		'^###cb:tempban:(ban):(%a):(%d+):(-%d+)',
		'^###cb:tempban:(nil)$'
	}
}

return plugin
