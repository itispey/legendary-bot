local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function get_button_description(key)
	if key == 'num' then
		return ("🏅 برای تغییر عدد، روی + یا - بزنید.")
	elseif key == 'voice' then
		return ("⚠️ لطفا روی تیک سبز یا گزینه قرمز در سمت راست بزنید.")
	else
		return ("توضیحاتی موجود نیست ❌")
	end
end

local function do_keyboard_flood(chat_id)
	--no: enabled, yes: disabled
	local status = db:hget('chat:'..chat_id..':settings', 'Flood') or config.chat_settings['settings']['Flood'] --check (default: disabled)
	if status == 'on' then
		status = ("✅ | فعال")
	else
		status = ("❌ | غیر فعال")
	end

	local hash = 'chat:'..chat_id..':flood'
	local action = (db:hget(hash, 'ActionFlood')) or config.chat_settings['flood']['ActionFlood']
	if action == 'kick' then
		action = ("👞️ اخراج")
	elseif action == 'ban' then
		action = ("🔨 مسدود")
	elseif action == 'mute' then
		action = ("👁 سایلنت")
	end
	local num = (db:hget(hash, 'MaxFlood')) or config.chat_settings['flood']['MaxFlood']
	local keyboard = {
		inline_keyboard = {
			{
				{text = status, callback_data = 'flood:status:'..chat_id},
				{text = action, callback_data = 'flood:action:'..chat_id},
			},
			{
				{text = '➖', callback_data = 'flood:dim:'..chat_id},
				{text = tostring(num), callback_data = 'flood:alert:num'},
				{text = '➕', callback_data = 'flood:raise:'..chat_id},
			}
		}
	}

	local exceptions = {
		text = ("متن 📋"),
		forward = ("فوروارد 🐤"),
		sticker = ("استیکر 🎗"),
		photo = ("عکس 🛤"),
		gif = ("گیف 🎲"),
		video = ("فیلم 🎥"),
	}
	local hash = 'chat:'..chat_id..':floodexceptions'
	for media, translation in pairs(exceptions) do
		--ignored by the antiflood-> yes, no
		local exc_status = db:hget(hash, media) or config.chat_settings['floodexceptions'][media]
		if exc_status == 'yes' then
			exc_status = '☑️'
		else
			exc_status = '✅'
		end
		local line = {
			{text = exc_status, callback_data = 'flood:exc:'..media..':'..chat_id},
			{text = translation, callback_data = 'flood:alert:voice'},
		}
		table.insert(keyboard.inline_keyboard, line)
	end

	--back button
	table.insert(keyboard.inline_keyboard, {{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}})

	return keyboard
end

local function changeFloodSettings(chat_id, screm)
	local hash = 'chat:'..chat_id..':flood'
	if type(screm) == 'string' then
		if screm == 'mute' then
			db:hset(hash, 'ActionFlood', 'ban')
			return ("از این به بعد فرد اسپمر مسدود می شود 🚫")
		elseif screm == 'ban' then
			db:hset(hash, 'ActionFlood', 'kick')
			return ("از این به بعد فرد اسپمر اخراج می شود ⚡️")
		elseif screm == 'kick' then
			db:hset(hash, 'ActionFlood', 'mute')
			return ("از این پس فرد اسپمر سایلنت می شود 🚫")
		end
	elseif type(screm) == 'number' then
		local old = tonumber(db:hget(hash, 'MaxFlood')) or 5
		local new
		if screm > 0 then
			new = db:hincrby(hash, 'MaxFlood', 1)
			if new > 25 then
				db:hincrby(hash, 'MaxFlood', -1)
				return ("عدد %d مجاز نیست!\n"):format(new)
        .. ("حساسیت پیام باید بین 3 تا 26 باشد!")
			end
		elseif screm < 0 then
			new = db:hincrby(hash, 'MaxFlood', -1)
			if new < 3 then
				db:hincrby(hash, 'MaxFlood', 1)
				return ("عدد %d مجاز نیست!\n"):format(new)
        .. ("حساسیت پیام باید بین 3 تا 26 باشد!")
			end
		end
		return string.format('%d → %d', old, new)
	end
end

function plugin.onCallbackQuery(msg, blocks)
	local chat_id = msg.target_id
	if chat_id and not msg.from.admin then
		api.answerCallbackQuery(msg.cb_id, ("‼️ متاسفیم!\nشما دیگر مدیر گروه نمی باشید."))
	else
		local header = ([[
شما می توانید تنظیمات ضد اسپم گروه خود را در این بخش مدیریت کنید.

ردیف اول:
• روشن/خاموش: شما میتوانید توسط دکمه روشن/خاموش ضد اسپم گروه خودتون را خاموش یا روشن کنید.
• اخراج - مسدود - سایلنت: تنظیم اخراج یا مسدود یا بی صدا کردن کاربر در زمان ارسال پیام های پشت سر هم.

ردیف دوم:
• شما میتوانید توسط ➕ و ➖ که در زیر مشاهده می کنید، تعداد پیام های مجاز که در 5 ثانیه ارسال می شود را کم یا زیاد کنید.
• به این معنی می باشد کاربران در گروه اگر مثلا در 5 ثانیه 4 بار بگویند سلام، اخراج یا مسدود می شود.
• کمترین عدد 4 و بیشترین عدد 25 می باشد.

ردیف سوم:
شما میتوانید بعضی از رسانه های خاص مانند استیکر را تغییر دهید (به صورتی که اگر کاربر استیکر پشت سر هم فرستادن اخراج نشود.)
• ✅: اگر گزینه شما روی تیک سبز بود، سیستم ضد اسپم، اسپم را تشخیص خواهد داد و کاربر اخراج یا مسدود می شود.
• ☑️: اگر روی گزینه قرمز بود، سیستم ضد اسپم محاسبه نخواهد شد.

[Legendary TM](https://telegram.me/joinchat/D3BUeT7pRqNEt0X3oUeE7A)
]])

		local text

		if blocks[1] == 'config' then
			local t, k = u.join_channel(msg.from.id, 'config:antiflood:'..chat_id)
			if t and k then
				api.editMessageText(msg.chat.id, msg.message_id, t, true, k)
				return
			end
			text = ("🔷 به قسمت ضد اسپم خوش آمدید.\n"
			.."شما میتوانید از این قسمت گروه خودتون رو ضد اسپم کنید.\n"
			.."لطفا متن راهنما را با دقت بخوانید.")
			api.answerCallbackQuery(msg.cb_id, text, true)
		end

		if blocks[1] == 'alert' then
			text = get_button_description(blocks[2])
			api.answerCallbackQuery(msg.cb_id, text, true, config.bot_settings.cache_time.alert_help)
			return
		end

		if blocks[1] == 'exc' then
			local media = blocks[2]
			local hash = 'chat:'..chat_id..':floodexceptions'
			local status = (db:hget(hash, media)) or 'no'
			if status == 'no' then
				db:hset(hash, media, 'yes')
				text = ("اعمال شد ☑️")
			else
				db:hset(hash, media, 'no')
				text = ("اعمال شد ✅")
			end
		end

		local action
		if blocks[1] == 'action' or blocks[1] == 'dim' or blocks[1] == 'raise' then
			if blocks[1] == 'action' then
				action = db:hget('chat:'..chat_id..':flood', 'ActionFlood') or config.chat_settings.flood.ActionFlood
			elseif blocks[1] == 'dim' then
				action = -1
			elseif blocks[1] == 'raise' then
				action = 1
			end
			text = changeFloodSettings(chat_id, action)
		end

		if blocks[1] == 'status' then
			local status = db:hget('chat:'..chat_id..':settings', 'Flood')
			if status == 'on' then
				db:hset('chat:'..chat_id..':settings', 'Flood', 'off')
				text = "❌ قفل حساسیت پیام غیرفعال شد."
			else
				db:hset('chat:'..chat_id..':settings', 'Flood', 'on')
				text = "✅ قفل حساسیت پیام فعال شد."
			end
		end

		local keyboard = do_keyboard_flood(chat_id)
		api.editMessageText(msg.chat.id, msg.message_id, header, true, keyboard)
		api.answerCallbackQuery(msg.cb_id, text)
	end
end

plugin.triggers = {
	onCallbackQuery = {
		'^###cb:flood:(alert):([%w_]+)$',
		'^###cb:flood:(status):(-?%d+)$',
		'^###cb:flood:(action):(-?%d+)$',
		'^###cb:flood:(dim):(-?%d+)$',
		'^###cb:flood:(raise):(-?%d+)$',
		'^###cb:flood:(exc):(%a+):(-?%d+)$',

		'^###cb:(config):antiflood:'
	}
}

return plugin
