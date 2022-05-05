local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local permissions = {
	can_change_info = ("نمی تواند عکس، اسم، و توضیحات گروه را تغییر دهد."),
	can_send_messages = ("نمی تواند پیام ارسال کند."),
	can_delete_messages = ("نمی تواند پیامی حذف کند."),
	can_invite_users = ("نمی تواند کاربری به گروه اضافه کند."),
	can_restrict_members = ("نمی تواند عضو ها را محدود کند."),
	can_pin_messages = ("نمی تواند پیامی را پین (سنجاق) کند."),
	can_promote_members = ("نمی تواند ادمین جدید اضافه کند."),
	can_send_media_messages = ("نمی تواند عکس، فیلم، فایل، موسیقی، صدا و فیلم سلفی ارسال کند."),
	can_send_other_messages = ("نمی تواند استیکر، گیف، بازی و پیام اینلاین بفرستد."),
	can_add_web_page_previews = ("نمی تواند توضیحات لینک را بفرستد.")
}

local function do_keyboard_cache(chat_id)
	local keyboard = {inline_keyboard = {{{text = ("به روزرسانی لیست مدیران ✅"), callback_data = 'recache:'..chat_id}, {text = ("راهنما 📚"), callback_data = 'helpcache:'..chat_id}}}}
	return keyboard
end

local function get_time_remaining(seconds)
	local final = ''
	local hours = math.floor(seconds/3600)
	seconds = seconds - (hours*60*60)
	local min = math.floor(seconds/60)
	seconds = seconds - (min*60)

	if hours and hours > 0 then
		final = final..hours..' ساعت '
	end
	if min and min > 0 then
		final = final..min..' دقیقه '
	end
	if seconds and seconds > 0 then
		final = final..seconds..' ثانیه '
	end

	return final
end

local function do_keyboard_userinfo(user_id)
	local keyboard = {
		inline_keyboard = {
			{{text = ("حذف اخطار ها ❌"), callback_data = 'userbutton:remwarns:'..user_id}}
		}
	}

	return keyboard
end

local function get_userinfo(user_id, chat_id)
	local res = api.getChatMember(chat_id, user_id).result
	local text = ("🔻 مشخصات کاربر مورد نظر:\n• شناسه کاربری: %s\n• نام: %s"):format(res.user.id, res.user.first_name)
	if res.user.last_name then
		text = text..("\n• نام خانوادگی: %s"):format(res.user.last_name)
	end
	if res.user.username then
		text = text..("\n• نام کاربری: @%s"):format(res.user.username)
	end
	local archiveNames = db:smembers('user:nickname:archived:'..user_id) or nil
	local archiveUsername = db:smembers('user:username:archived:'..user_id) or nil
	if #archiveNames > 1 then
		text = text.."\n\n🔸 نام های قبلی این کاربر:\n"
		for i = 1, #archiveNames do
			text = text..i..". "..archiveNames[i].."\n"
			if i == 5 then break end
		end
	end
	if #archiveUsername > 1 then
		text = text.."\n\n🔹 یوزرنیم های قبلی این کاربر:\n"
		for i = 1, #archiveUsername do
			text = text..i..". @"..archiveUsername[i].."\n"
			if i == 5 then break end
		end
	end
	text = text..("\n\n⚠️ اخطار های این کاربر: %s"):format(db:hget('chat:'..chat_id..':warns', user_id) or 0)
	return text
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1]:lower() == 'id' or blocks[1] == 'ایدی' or blocks[1] == 'آیدی' then
		if msg.from.admin then
			local text
			if msg.reply then
				if msg.reply.forward_from then
					text = ('شناسه کاربری که پیام از آن فوروارد شده است:\n`%d`'):format(msg.reply.forward_from.id)
				else
					text = ('شناسه کاربر:\n`%d`'):format(msg.reply.from.id)
				end
			else
				text = ('آیدی گروه:\n`%d`'):format(msg.chat.id)
			end
			api.sendReply(msg, text, true)
		end
	end

	if msg.chat.type == 'private' then return end

	if blocks[1]:lower() == 'adminlist' or blocks[1] == 'لیست ادمین ها' then
		local adminlist = u.getAdminlist(msg.chat.id)
		if not msg.from.admin then
			api.sendMessage(msg.from.id, adminlist, 'html')
		else
			api.sendReply(msg, adminlist, 'html')
		end
	end
	if blocks[1]:lower() == 'status' then
		if msg.from.admin then
			if not blocks[2] and not msg.reply then return end
			local user_id, error_tr_id = u.get_user_id(msg, blocks)
			if not user_id then
				api.sendReply(msg, (error_tr_id), true)
			else
				local res = api.getChatMember(msg.chat.id, user_id)

				if not res then
					api.sendReply(msg, ("این کاربر در گروه نمی باشد!"))
					return
				end
				local status = res.result.status
				local name = u.getname_final(res.result.user)
				local text
				if tonumber(res.result.user.id) == 284568421 then --Haminreza
					local texts = {
						'عه این بچه کونیه هست که 😃',
						'ادمین و سازنده کیونه گروه! حمید رضا',
						'کسخله گروه! %s\nاسم خودشم گذاشته ادمین 😒'
					}
					text = texts[math.random(#texts)]:format(name)
				elseif status == 'kicked' then
					local texts = {
						'کاربر %s اخراج شده 😨',
						'کاربر %s از گروه شوت شده بیرون 😐😂',
						'کاربر %s توسط ادمین های خشن اخراج شده 😮'
					}
					text = texts[math.random(#texts)]:format(name)
				elseif status == "left" then
					local texts = {
						'کاربر %s از گروه رفته 🙁\nشاید هم هیچوقت اینجا نبوده :(',
						'کاربر %s توی گروه نیس 😐\nشاید هم اخراج شده و توسط یکی unban/ شده 🤔'
					}
					text = texts[math.random(#texts)]:format(name)
				elseif status == "administrator" then
					local texts = {
						'با %s شوخی نکنید اون یک ادمینه 😰\nاینم دسترسی هاش:',
						'کاربر %s یک ادمینِ خشن هست 🤕',
						'پیداش کردم 😃\nادمین %s یک ادمینِ خیلی خوب و مهربونه ☺️❤️'
					}
					text = texts[math.random(#texts)]:format(name)
				elseif status == "creator" then
					local texts = {
						'وای خدا %s سازنده گروهه 😱',
						'الانه که توسط %s اخراج بشم 😥\nاون سازنده گروهه :(',
						'شما رو با سازنده گروه %s آشنا میکنم 😬'
					}
					text = texts[math.random(#texts)]:format(name)
				elseif status == "unknown" then
					local texts = 'هیچ اطلاعی از %s ندارم :('
					text = texts:format(name)
				elseif status == "member" then
					local texts = {
						'کاربر %s یه کاربر مهربون و بی آزار هست ☺️🌹',
						'کاربر %s یک عضو عادی می باشد ☺️'
					}
					text = texts[math.random(#texts)]:format(name)
				elseif status == "restricted" then
					local texts = {
						'کاربر %s محدود شده 😂\nمحدودیت ها:',
						'کاربر %s دارای محدودیت می باشد 🙄'
					}
					text = texts[math.random(#texts)]:format(name)
				end

				local denied_permissions = {}
				for permission, str in pairs(permissions) do
					if res.result[permission] ~= nil and res.result[permission] == false then
						table.insert(denied_permissions, str)
					end
				end

				if next(denied_permissions) then
					text = text..('\nمحدودیت ها: <i>%s</i>'):format(table.concat(denied_permissions, ', '))
				end

				api.sendReply(msg, text, 'html')
			end
		end
	end
	if blocks[1]:lower() == 'user' then
		if not msg.from.admin then return end

		local new_user_id, error = u.get_user_id(msg, blocks)
		if not new_user_id then
			api.sendReply(msg, error)
			return
		end
		-----------------------------------------------------------------------------

		local keyboard = do_keyboard_userinfo(new_user_id)

		local text = get_userinfo(new_user_id, msg.chat.id)

		api.sendMessage(msg.chat.id, text, 'html', keyboard)
	end
	if blocks[1]:lower() == 'cache' or blocks[1] == 'آپدیت ادمین ها' or blocks[1] == 'اپدیت ادمین ها' then
		if not msg.from.admin then return end
		local hash = 'cache:chat:'..msg.chat.id..':admins'
		local seconds = db:ttl(hash)
		local cached_admins = db:scard(hash)
		local text = ("🔷 بخش لیست مدیریت:\n\n🕘 زمان تا بروزرسانی خودکار: `%s`\n"
		.."👥 تعداد ادمین ها: `%d` نفر"):format(get_time_remaining(tonumber(seconds)), cached_admins)
		local keyboard = do_keyboard_cache(msg.chat.id)
		api.sendMessage(msg.chat.id, text, true, keyboard)
	end
	if blocks[1]:lower() == 'leave' then
		if msg.from.admin then
			u.remGroup(msg.chat.id, true)
			api.leaveChat(msg.chat.id)
		end
	end
end

function plugin.onCallbackQuery(msg, blocks)
	if not msg.from.admin then
		api.answerCallbackQuery(msg.cb_id, ("❗️ تنها ادمین های گروه به این بخش دسترسی دارند.")) return
	end

	if blocks[1] == 'helpcache' then
		local text = [[
راهنما:
توسط این قسمت، شما می توانید لیست مدیریت گروهتان را به روزرسانی کنید.

به صورت مثال شما یک نفر رو همین الان ادمین گروه کردید اما دستور می دهد و ربات پاسخ آن را نمی دهد...
در این مواقع از دستور `cache/` استفاده کنید و لیست رو توسط دکمه به روزرسانی آپدیت کنید.

[Legendary TM](https://telegram.me/joinchat/D3BUeT7pRqNEt0X3oUeE7A)
]]
		api.editMessageText(msg.chat.id, msg.message_id, text, true, do_keyboard_cache(msg.target_id))
	end

	if blocks[1] == 'remwarns' then
		local removed = {
			normal = db:hdel('chat:'..msg.chat.id..':warns', blocks[2]),
		}

		local name = u.getname_final(msg.from)
		local text = ("تمامی اخطار های کاربر حذف شد!\n(توسط ادمین: %s)"):format(name)
		api.editMessageText(msg.chat.id, msg.message_id, text:format(name), 'html')
		u.logEvent('nowarn', msg, {admin = name, user = ('<code>%s</code>'):format(msg.target_id), user_id = msg.target_id, rem = removed})
	end
	if blocks[1] == 'recache' and msg.from.admin then
		local missing_sec = tonumber(db:ttl('cache:chat:'..msg.target_id..':admins') or 0)
		local wait = 360
		if config.bot_settings.cache_time.adminlist - missing_sec < wait then
			local seconds_to_wait = wait - (config.bot_settings.cache_time.adminlist - missing_sec)
			api.answerCallbackQuery(msg.cb_id, ("لیست ادمین ها به تازگی به روزرسانی شده است. لطفا %d ثانیه دیگر امتحان کنید."):format(seconds_to_wait), true)
		else
			db:del('cache:chat:'..msg.target_id..':admins')
			u.cache_adminlist(msg.target_id)
			local cached_admins = db:smembers('cache:chat:'..msg.target_id..':admins')
			local time = get_time_remaining(config.bot_settings.cache_time.adminlist)
			local text = ("🔷 بخش لیست مدیریت:\n\n🕘 زمان تا بروزرسانی خودکار: `%s`\n"
			.."👥 تعداد ادمین ها: `%d` نفر")
				:format(time, #cached_admins)
			api.answerCallbackQuery(msg.cb_id, ("به روزرسانی شد ✅"))
			api.editMessageText(msg.chat.id, msg.message_id, text, true, do_keyboard_cache(msg.target_id))
			--api.sendLog('#recache\nChat: '..msg.target_id..'\nFrom: '..msg.from.id)
		end
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(id)$',
		config.cmd..'(adminlist)$',
		config.cmd..'(status) (.+)$',
		config.cmd..'(status)$',
		config.cmd..'(cache)$',
		config.cmd..'(user)$',
		config.cmd..'(user) (.*)',
		config.cmd..'(leave)$',
		---------------------
		'^([Ii]d)$',
		'^([Aa]dminlist)$',
		'^([Ss]tatus) (.+)$',
		'^([Ss]tatus)$',
		'^([Cc]ache)$',
		'^([Uu]ser)$',
		'^([Uu]ser) (.*)',
		'^([Ll]eave)$',
		---------------------
		'^(ایدی)$',
		'^(آیدی)$',
		'^(لیست ادمین ها)$',
		'^(آپدیت ادمین ها)$',
		'^(اپدیت ادمین ها)$'
	},
	onCallbackQuery = {
		'^###cb:userbutton:(remwarns):(%d+)$',
		'^###cb:(recache):'
	}
}

return plugin
