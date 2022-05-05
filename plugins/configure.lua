local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local text = ([[
🔶 به بخش تنظیمات خوش آمدید.

🔹 شما می توانید توسط دکمه های زیر، تنظیمات گروه خودتان را طبق سلیقه خودتان تغییر دهید.

• تنظیمات اصلی: در این بخش می توانید تنظیمات اصلی مانند پیام خوش آمدگویی، ضد ربات، تعیین تعداد اخطار ها و ... را تغییر دهید.
• تنظیمات حذف تبلیغات: در این بخش می توانید حذف تبلیغات، لینک های مختلف و ... را فعال کنید.
• تنظیمات حذف رسانه: در این بخش به سادگی می توانید حذف رسانه هایی مانند عکس، فیلم، استیکر، گیف و ... را فعال یا غیر فعال کنید.
• تنظیمات فیلتر کردن: در این بخش می توانید کلمه مورد نظر خودتان را فیلتر کنید تا هرکس آن را ارسال کرد، آن پیام حذف شود.
• تنظیمات حساسیت پیام: به سادگی جلوی پیام های رگباری و پشت سر هم را بگیرید و فرد ارسال کننده را مجازات کنید.
• تنظیمات قفل گروه: در این بخش به سادگی گروه خودتان را قفل کنید.
• تنظیمات ویژه: همچنین پیام هایی مانند پیام ورود و خروج و ... را در تنظیمات ویژه مدیریت کنید.
• تنظمیات کانال رویداد ها: در این بخش کانال رویداد ها رو مدیریت کنید و هر رویدادی در گروهتان رخ می دهد را به سادگی ثبت کنید.

🔺 <i>در صورتی که با سرعت زیادی روی کیبورد ها بزنید، برای بار اول تقریبا به مدت 180 ثانیه (2 دقیقه) از طرف تلگرام محدود می شوید و دکمه ها برای شما تغییری نخواهند کرد! پس آروم و بدون عجله روی دکمه ها بزنید </i>

این تنظیمات برای گروه [<b>%s</b>] می باشد.

<a href="https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q">Legendary Ch</a>
]])

local function cache_chat_title(chat_id, title)
	print('caching title...')
	local key = 'chat:'..chat_id..':title'
	db:set(key, title)
	db:expire(key, config.bot_settings.cache_time.chat_titles)
	return title
end

local function get_chat_title(chat_id)
	local cached_title = db:get('chat:'..chat_id..':title')
	if not cached_title then
		local chat_object = api.getChat(chat_id)
		if chat_object then
			return cache_chat_title(chat_id, chat_object.result.title)
		else
			return false, 'Unknown'
		end
	else
		return cached_title
  	end
end

local function do_keyboard_config(chat_id)
	local keyboard = {inline_keyboard = {
		{{text = ("تنظیمات اولیه ⚙️"), callback_data = 'config:menu:'..chat_id}},
		{{text = ("حذف تبلیغات 🗑"), callback_data = 'config:ads:'..chat_id}, {text = ("حذف رسانه ✨"), callback_data = 'config:media:'..chat_id}},
		{{text = ("قفل گروه 🍩"), callback_data = 'config:lock_group:'..chat_id}},
		{{text = ("پاکسازی پیام ها 🔮"), callback_data = 'config:clean:'..chat_id}, {text = ("پورنوگرافی 🔞"), callback_data = 'config:porno:'..chat_id}},
		{{text = ("تنظیم کانال رویداد ها 🎈"), callback_data = 'config:logchannel:'..chat_id}},
		{{text = ("فیلتر کردن 🍿"), callback_data = 'config:filter:'..chat_id}, {text = ("حساسیت پیام 🎸"), callback_data = 'config:antiflood:'..chat_id}}
	}}
	return keyboard
end

local function do_keyboard_sendprivate()
	local keyboard = {inline_keyboard = {
			{{text = ("مشاهده پنل تنظیمات 👀"), url = string.format('https://telegram.me/%s', bot.username)}}
		}}
	return keyboard
end

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type == 'private' then
		if not u.is_superadmin(msg.from.id) then
			api.sendReply(msg, ("کاربر گرامی، لطفا از این دستور در داخل _گروه خود_ استفاده کنید."), true)
			return
		else
			if blocks[1] and blocks[1]:match("(-%d+)") then
				local chat_id = blocks[1]
				local keyboard = do_keyboard_config(chat_id)
				local getTitle = get_chat_title(chat_id)
				if getTitle then
					api.sendMessage(msg.from.id, text:format(getTitle:escape_html()), 'html', keyboard)
				else
					api.sendReply(msg, 'گروه مورد نظر یافت نشد!')
				end
			end
		end
	else
		if msg.from.admin or u.is_superadmin(msg.from.id) then
			if not u.bot_is_admin(msg.chat.id) then
				api.sendReply(msg, "برای استفاده از این دستور ربات باید ادمین باشد (با دسترسی محدود کردن)")
				return
			end
			local chat_id = msg.chat.id
			local keyboard = do_keyboard_config(chat_id)
			if not db:get('chat:'..chat_id..':title') then
				cache_chat_title(chat_id, msg.chat.title)
			end
			local res = api.sendMessage(msg.from.id, text:format(msg.chat.title:escape_html()), 'html', keyboard)
			if res then
				local keyboard2 = do_keyboard_sendprivate()
				api.sendMessage(msg.chat.id, ("‼️ تنظیمات گروه به پیام خصوصی شما ارسال شد."), true, keyboard2)
			else
				u.sendStartMe(msg)
			end
		end
	end
end

function plugin.onCallbackQuery(msg, blocks)
	if blocks[1] == 'back' then
		local chat_id = msg.target_id
		local keyboard = do_keyboard_config(chat_id)
		local chat_title, error = get_chat_title(chat_id)
		if not chat_title and error then
			api.answerCallbackQuery(msg.cb_id, error, true)
			return
		end
		api.editMessageText(msg.chat.id, msg.message_id, text:format(chat_title:escape_html()), 'html', keyboard)
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'config$',
		config.cmd..'config (-%d+)$',
		config.cmd..'settings$',
		config.cmd..'settings (-%d+)$',
		'^تنظیمات$',
		'^[Cc]onfig$',
		'^[Cc]onfig (-%d+)$',
		'^[Ss]ettings',
		'^[Ss]ettings (-%d+)'
	},
	onCallbackQuery = {
		'^###cb:config:(back):'
	}
}

return plugin
