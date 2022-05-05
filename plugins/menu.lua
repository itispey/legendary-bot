local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function get_button_description(key)
	if key == 'Reports' then
		return ("در صورت فعال بودن این گزینه، اگر کاربری روی یک پیام کاربر دیگر ریپلای کند و عبارت report را بنویسد، آن پیام برای تمام ادمین ها گزارش می شود.")
	elseif key == 'Welcome' then
		return ("فعال/غیرفعال سازی پیام خوش آمدگویی.")
	elseif key == 'Welbut' then
		return ('اضافه شدن دکمه "مشاهده قوانین" زیر پیام خوش آمدگویی برای کسانی که تازه عضو گروه شده اند.')
	elseif key == 'Weldelchain' then
		return ("اگر این گزینه فعال باشد، زمانی که پیام خوش آمدگویی جدید ارسال می شود، پیام خوش آمدگویی قبلی حذف خواهد شد (جلوگیری از اسپم)")
	elseif key == 'Rules' then
		return ([[در صورت ارسال دستور /rules:
👥: قوانین در گروه ارسال می شوند.
👤: قوانین در پیوی شخص ارسال می شود.]])
	elseif key == 'Extra' then
		return ([[در صورت ارسال دستورات شخصی:
👥: پاسخ در گروه ارسال می شود.
👤: پاسخ در پیوی شخص ارسال می شود.]])
	elseif key == 'Antibot' then
		return ("در صورت فعال کردن این گزینه، اگر کاربری (غیر از ادمین) در گروه شما، ربات اضافه کند، لجندری آن را اخراج خواهد کرد.")
	elseif key == 'Antibotbutton' then
		return ("در صورت فعال بودن این گزینه، زمانی که کاربری ربات به گروه اضافه می کند، توسط دکمه اخراج کاربر می توانید کاربری که ربات را اضافه کرده را اخراج کنید.")
	elseif key == 'warnsnum' then
		return ("می توانید تنظیم کنید تا چه مدتی کاربر اخطار بگیرد و به چه عددی رسید اخراج/مسدود شود.")
	elseif key == 'warnsact' then
		return ("زمانی که اخطار های کاربر به حداکثر رسید، چه اتفاقی رخ دهد؟")
	elseif key == 'Change' then
		return ("با فعال کردن این بخش، هرکس در گروه نام یا نام کاربری خود را عوض کند، ربات به شما اطلاع خواهد داد (مخصوص گروه های ویژه)")
	else
		return ("توضیحاتی وجود ندارد.")
	end
end

local function changeSettingStatus(chat_id, field)
	local turned_off = {
		reports = ("☑️ ارسال گزارش ها غیرفعال شد."),
		welcome = ("☑️ پیام خوش آمدگویی غیرفعال شد."),
		extra = ("👤 از این پس ربات فقط به ادمین پاسخ می دهد."),
		rules = ("👤 از این به بعد دستور دستور /rules در پیوی نمایش داده می شود."),
		antibot = ("☑️ ضد ربات غیرفعال شد."),
		weldelchain = ("☑️ حذف پیام های خوش آمدگویی قبلی، غیرفعال شد."),
		welbut = ("☑️ پیام خوش آمدگویی دیگر حاوی دکمه قوانین نمی باشد."),
		antibotbutton = ("☑️ دکمه اخراج ضد ربات غیرفعال شد."),
		change = ("☑️ تشخیص تغییر نام غیرفعال شد.")
	}
	local turned_on = {
		reports = ("✅ ارسال گزارش ها فعال شد."),
		welcome = ("✅ پیام خوش آمدگویی فعال شد."),
		extra = ("👥 از این به بعد ربات به کاربران هم پاسخ خواهد داد."),
		rules = ("👥 از این به بعد دستور دستور /rules در گروه نمایش داده خواهد شد."),
		antibot = ("✅ از این به بعد ربات ها اخراج می شوند."),
		weldelchain = ("✅ حذف پیام های خوش آمدگویی قبلی، فعال شد."),
		welbut = ("✅ پیام خوش آمدگویی حاوی دکمه قوانین شد."),
		antibotbutton = ("✅ دکمه اخراج ضد ربات فعال شد."),
		change = ("✅ تشخیص تغییر نام فعال شد.")
	}
	if field:lower() == 'rules' then
		local check = db:hget('chat:'..chat_id..':info', 'rules')
		if not check then
			return ("شما قوانینی ننوشته اید!\nاول قوانین رو با دستور\n/setrules\nبنوسید؛ سپس مجدد تلاش کنید."), true
		end
	end
	if field:lower() == 'change' then
		if not u.is_vip_group(chat_id) then
			return ("این قابلیت مخصوص گروه های ویژه می باشد.\nاطلاع بیشتر با ارسال دستور panel/ داخل گروه خود :)"), true
		end
	end
	local hash = 'chat:'..chat_id..':settings'
	local now = db:hget(hash, field)
	if now == 'on' then
		db:hset(hash, field, 'off')
		return turned_off[field:lower()]
	else
		db:hset(hash, field, 'on')
		return turned_on[field:lower()]
	end
end

local function changeWarnSettings(chat_id, action)
	local current = tonumber(db:hget('chat:'..chat_id..':warnsettings', 'max')) or 3
	local new_val
	if action == 1 then
		if current > 12 then
			return ("این عدد بیشتر از 12 نمیشود.")
		else
			new_val = db:hincrby('chat:'..chat_id..':warnsettings', 'max', 1)
			return current..'->'..new_val
		end
	elseif action == -1 then
		if current < 2 then
			return ("این عدد کمتر از 1 نمی شود.")
		else
			new_val = db:hincrby('chat:'..chat_id..':warnsettings', 'max', -1)
			return current..'->'..new_val
		end
	elseif action == 'status' then
		local status = (db:hget('chat:'..chat_id..':warnsettings', 'type')) or config.chat_settings.warnsettings.type
		if status == 'kick' then
			db:hset('chat:'..chat_id..':warnsettings', 'type', 'ban')
			return ("⚘ از این به بعد اخطار ها به آخر برسد، کاربر مسدود می شود.")
		elseif status == 'ban' then
			db:hset('chat:'..chat_id..':warnsettings', 'type', 'mute')
			return ("❦ در صورتی که اخطار ها به آخر برسد، کاربر مورد نظر سایلنت می شود.")
		elseif status == 'mute' then
			db:hset('chat:'..chat_id..':warnsettings', 'type', 'kick')
			return ("➳ از این به بعد اخطار ها به آخر برسد، کاربر اخراج می شود.")
		end
	end
end

local function usersettings_table(settings, chat_id)
	local return_table = {}
	local icon_off, icon_on = '👤', '👥'
	for field, default in pairs(settings) do
		if field == 'Extra' or field == 'Rules' then
			local status = (db:hget('chat:'..chat_id..':settings', field)) or default
			if status == 'off' then
				return_table[field] = icon_off
			elseif status == 'on' then
				return_table[field] = icon_on
			end
		end
	end

	return return_table
end

local function adminsettings_table(settings, chat_id)
	local return_table = {}
	local icon_off, icon_on = '☑️', '✅'
	for field, default in pairs(settings) do
		if field ~= 'Extra' and field ~= 'Rules' then
			local status = (db:hget('chat:'..chat_id..':settings', field)) or default
			if status == 'off' then
				return_table[field] = icon_off
			elseif status == 'on' then
				return_table[field] = icon_on
			end
		end
	end

	return return_table
end

local function insert_settings_section(keyboard, settings_section, chat_id)
	local strings = {
		Welcome = ("• خوش آمدگویی"),
		Rules = ("• قوانین"),
		Extra = ("• دستورات شخصی"),
		Reports = ("• ارسال گزارش"),
		Welbut = ("• دکمه قوانین"),
		Weldelchain = ("• خوش آمدگویی کمتر"),
		Antibot = ("• ضد ربات"),
		Antibotbutton = ("• دکمه ضد ربات"),
		Change = ("• تغییر مشخصات")
	}

	for key, icon in pairs(settings_section) do
		local current = {
			{text = icon, callback_data = 'menu:'..key..':'..chat_id},
			{text = strings[key] or key, callback_data = 'menu:alert:'..key}
		}
		table.insert(keyboard.inline_keyboard, current)
	end

	return keyboard
end

local function doKeyboard_menu(chat_id)
	local keyboard = {inline_keyboard = {}}

	local settings_section = adminsettings_table(config.chat_settings['settings'], chat_id)
	keyboad = insert_settings_section(keyboard, settings_section, chat_id)

	settings_section = usersettings_table(config.chat_settings['settings'], chat_id)
	keyboad = insert_settings_section(keyboard, settings_section, chat_id)

	--warn
	local max = (db:hget('chat:'..chat_id..':warnsettings', 'max')) or config.chat_settings['warnsettings']['max']
	local action = (db:hget('chat:'..chat_id..':warnsettings', 'type')) or config.chat_settings['warnsettings']['type']
	if action == 'kick' then
		action = ("➳ اخراج")
	elseif action == 'ban' then
		action = ("⚘ مسدود")
	elseif action == 'mute' then
		action = ("❦ سایلنت")
	end
	local warn = {
		{
			{text = '－', callback_data = 'menu:DimWarn:'..chat_id},
			{text = ('اخطارها (%s)'):format(max), callback_data = 'menu:alert:warnsnum'},
			{text = '＋', callback_data = 'menu:RaiseWarn:'..chat_id}
		},
		{
			{text = action, callback_data = 'menu:ActionWarn:'..chat_id},
			{text = ('• حالت اخطار :'), callback_data = 'menu:alert:warnsact'}
		}
	}
	for i, button in pairs(warn) do
		table.insert(keyboard.inline_keyboard, button)
	end

	--back button
	table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})

	return keyboard
end

function plugin.onCallbackQuery(msg, blocks)
	local chat_id = msg.target_id
	if chat_id and not msg.from.admin then
		api.answerCallbackQuery(msg.cb_id, ("متاسفیم!\nشما دیگر مدیر گروه نمی باشید."))
	else
		local menu_first = ([[
🔶 به تنظیمات عمومی گروه خودتون خوش آمدید.

در این قسمت می توانید تنظیمات عمومی گروه خودتون رو مدیریت کنید.
اگر نمی دانید این دکمه ها چیست و کاربرد آنها چیست، کافیست روی آنها بزنید تا اطلاعات هر دکمه را ببینید.

اگر فکر میکنید به راهنمای بیشتری نیاز دارید، دستور /help را ارسال کنید.

[لجندری تیم](https://telegram.me/joinchat/D3BUeT7pRqNEt0X3oUeE7A)]])

		local keyboard, text, show_alert

		if blocks[1] == 'config' then
			local t, k = u.join_channel(msg.from.id, 'config:menu:'..chat_id)
			if t and k then
				api.editMessageText(msg.chat.id, msg.message_id, t, true, k)
				return
			end
			keyboard = doKeyboard_menu(chat_id)
			api.answerCallbackQuery(msg.cb_id, "برای مشاهده راهنمای هر دکمه، روی دکمه های سمت راست بزنید...")
			api.editMessageText(msg.chat.id, msg.message_id, menu_first, true, keyboard)
		else
			if blocks[2] == 'alert' then
				text = get_button_description(blocks[3])
				api.answerCallbackQuery(msg.cb_id, text, true, config.bot_settings.cache_time.alert_help)
				return
			end

			if blocks[2] == 'DimWarn' or blocks[2] == 'RaiseWarn' or blocks[2] == 'ActionWarn' then
				if blocks[2] == 'DimWarn' then
					text = changeWarnSettings(chat_id, -1)
				elseif blocks[2] == 'RaiseWarn' then
					text = changeWarnSettings(chat_id, 1)
				elseif blocks[2] == 'ActionWarn' then
					text = changeWarnSettings(chat_id, 'status')
				end
			else
				text, show_alert = changeSettingStatus(chat_id, blocks[2])
			end
			keyboard = doKeyboard_menu(chat_id)
			api.editMessageReplyMarkup(msg.chat.id, msg.message_id, keyboard)
			if text then
				api.answerCallbackQuery(msg.cb_id, text, show_alert)
			end
		end
	end
end

plugin.triggers = {
	onCallbackQuery = {
		'^###cb:(menu):(alert):([%w_]+)$',
		'^###cb:(menu):(.*):',
		'^###cb:(config):menu:(-?%d+)$'
	}
}

return plugin
