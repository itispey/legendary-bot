local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function get_alert_text(key)
	if key == 'new_chat_member' then
		return ("🔸 زمانی که عضوی وارد گروه شما می شود، اطلاعات او در کانال ثبت می شود.")
	elseif key == 'ban' then
		return ("🔸 زمانی که کاربری \"به وسیله ربات\" مسدود می شود، در کانال ثبت می شود. (مسدود کردن بدون ربات ثبت نمی شود) ")
	elseif key == 'unban' then
		return ("🔸 زمانی که یک ادمین کاربری را از لیست مسدود ها (توسط ربات) خارج کند، گزارش آن به ثبت می رسد.")
	elseif key == 'tempban' then
		return ("🔸 درصورتی که کاربری با دستور /tempban مسدود شود، در کانال رویداد به ثبت می رسد.")
	elseif key == 'kick' then
		return ("🔸 زمانی که کاربری \"به وسیله ربات\" اخراج می شود، در کانال ثبت می شود. (اخراج کردن بدون ربات ثبت نمی شود) ")
	elseif key == 'warn' then
		return ("🔸 اخطار هایی که به وسلیه دستور warn/ داده می شوند، در کانال ثبت می شوند (همراه با دلیل)")
	elseif key == 'flood' then
		return ("🔸 زمانی که یک کاربر در حال اسپم باشد (در حال ارسال پیام پشت سر هم) ، در کانال ثبت می شود.")
	elseif key == 'new_chat_photo' then
		return ("🔸 گزارش تغییر عکس گروه در کانال.")
	elseif key == 'delete_chat_photo' then
		return ("🔸 گزارش حذف عکس گروه.")
	elseif key == 'new_chat_title' then
		return ("🔸 گزارش تغییر نام گروه در کانال.")
	elseif key == 'pinned_message' then
		return ("🔸 گزارش سنجاق کردن پیام.")
	elseif key == 'nowarn' then
		return ("🔸 در صورتی که ادمینی اخطار های فردی را با دستور nowarn/ حذف کند، در کانال رویداد ها به ثبت می رسد.")
	elseif key == 'report' then
		return ("🔸 گزارش ها (report/) در کانال رویداد به ثبت می رسد.")
	elseif key == 'silent' then
		return ("🔸 در صورت سایلنت شدن کاربری با دستور silent/ در کانال رویداد به ثبت خواهد رسید.")
	else
		return ("توضیحات موجود نمی باشد.")
	end
end

local function toggle_event(chat_id, event)
	local hash = ('chat:%s:tolog'):format(chat_id)
	local current_status = db:hget(hash, event) or config.chat_settings['tolog'][event]

	if current_status == 'yes' then
		db:hset(hash, event, 'no')
		return 'گزینه مورد نظر لغو شد ☑️'
	else
		db:hset(hash, event, 'yes')
		return 'گزینه مورد نظر انتخاب شد ✅'
	end
end

local function doKeyboard_logchannel(chat_id)
	local event_pretty = {
		['ban'] = ('مسدود 🚫'),
		['kick'] = ('اخراج 👞'),
		['unban'] = ('حذف مسدودی ها 💯'),
		['tempban'] = ('مسدود موقت 🚷'),
		['report'] = ('گزارش ها ✉️'),
		['warn'] = ('اخطار ها ⚠️'),
		['nowarn'] = ('حذف اخطار ها 🔖'),
		['new_chat_member'] = ('عضو های جدید 👤'),
		['flood'] = ('پیام رگباری 🐍'),
		['silent'] = ('سایلنت 😶'),
		['unsilent'] = ('حذف سایلنت 🤐'),
		['new_chat_photo'] = ('تغییر عکس گروه 🏙'),
		['delete_chat_photo'] = ('حذف عکس گروه 🗑'),
		['new_chat_title'] = ('تغییر نام گروه 🔺'),
		['pinned_message'] = ('سنجاق پیام 📌'),
	}

	local keyboard = {inline_keyboard={}}
	local icon

	table.insert(keyboard.inline_keyboard, {
		{text = 'لغو انتخاب همه ☑️', callback_data = 'logchannel:unselect_all:'..chat_id}, {text = 'انتخاب همه ✅', callback_data = 'logchannel:select_all:'..chat_id}
	})

	table.insert(keyboard.inline_keyboard, {{text = '------------------------------------------', callback_data = 'nothing'}})

	for event, default_status in pairs(config.chat_settings['tolog']) do
		local current_status = db:hget('chat:'..chat_id..':tolog', event) or default_status
		icon = '✅'
		if current_status == 'no' then icon = '☑️' end
		table.insert(keyboard.inline_keyboard, {
			{text = icon, callback_data = 'logchannel:toggle:'..event..':'..chat_id}, {text = event_pretty[event] or event, callback_data = 'logchannel:alert:'..event}
		})
	end

  table.insert(keyboard.inline_keyboard, {{text = '« حذف کانال رویداد »', callback_data = 'logchannel:delete_channel:'..chat_id}})
	table.insert(keyboard.inline_keyboard, {{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}})

	return keyboard
end

local f_text = ([[
🏖 کانال رویداد گروه خود را ثبت کنید!

🔸 توسط قابلیت جدید ربات لجندری، می توانید به سادگی رویداد های گروه خودتان را در کانال خصوصی به ثبت برسانید.
به طور مثال می توانید مشاهده کنید چه کسانی در گروهتان عضو شدند؟ چه کسانی اخراج شدند؟ توسط چه ادمینی اخراج شدند؟ چه کسی عکس گروه را تغییر میدهد؟ چه کسی اخطار می دهد یا اخطار ها رو حذف می کند؟ دلیل اخطار گرفتن یک کاربر چی بوده است؟

شاید با خودتون بگید این رویداد ها در بخش تنظیمات گروه (Recent Action) وجود دارد اما در این بخش اطلاعات فقط تا 48 ساعت باقی می ماند! ولیکن شما می توانید در کانال رویداد ها اطلاعات را برای همیشه باقی نگه دارید.

برای ثبت کانال خود، مراحل زیر را به ترتیب انجام دهید:
1. ابتدا یک کانال خصوصی بسازید! (به این معنی می باشد که کانال شما یوزرنیم نداشته باشد و فقط با لینک بتوان وارد آن شد)
2. ربات @%s را به کانال خود اضافه کنید و آن را مدیر کنید و دسترسی های لازم را به آن بدهید.
3. سپس روی دکمه ثبت کانال که در زیر وجود دارد بزنید.
4. در کانال خود عبارت "setlog/" یا "ثبت کانال" را ارسال کنید و آن را برای ربات فوروارد کنید! توجه داشته باشید بالای آن پیام باید *"Forward from ..."* یا "فوروارد شده از ..." نوشته شده باشد.

- _توجه: به هیچ وجه از فوروارد پیشرفته موبوگرام یا سایر تلگرام ها استفاده نکنید و پیام را با فوروارد اصلی، فوروارد کنید._

5. بعد از اتمام مراحل، کانال رویداد به ثبت می رسد و ربات یک پیام در کانال ارسال خواهد کرد.

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
]]):format(bot.username)

local org_text = [[
🔸 بخش کانال رویداد:

🔹 شما در این بخش می توانید به راحتی، اتفاقاتی که در گروه خود رخ می دهد را در کانال رویداد ها به ثبت برسانید!
مثلا چه کسانی اخطار گرفتند؟ توسط کدام ادمین؟ چه کسی اخراج شدند؟ دلیل اخراج آن ها چی بود؟ و قابلیت های دیگری که در این بخش پیدا می شود.

🔹 در صورتی که می خواهید تمام این رویداد ها رو در کانال به ثبت برسانید، از دکمه "انتخاب همه" و در صورتی که میخواهید همه را لغو کنید، از دکمه"لغو انتخاب همه" استفاده کنید.

🔹 همچنین میتوانید توسط دکمه "حذف کانال رویداد" ، کانال رویداد را حذف یا به کانالی دیگر منتقل کنید.

🔻 _توجه: در صورتی که نمی دانید هر گزینه چه کاری انجام می دهد، روی دکمه های سمت راست بزنید تا راهنمای مربوط به هرکدام را مشاهده کنید._

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
]]

function fr_keyboard(chat_id)
	local keyboard = {inline_keyboard = {
		{{text = 'ثبت کانال ✅', callback_data = 'logchannel:set_ch:'..chat_id}},
		{{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}}
	}}
	return keyboard
end

function plugin.onCallbackQuery(msg, blocks)
	local chat_id = msg.target_id
	local user_id = msg.from.id
	local keyboard, text

	if blocks[1] == 'logcb' then
		if u.is_admin(chat_id, msg.from.id) then
			if blocks[2] == 'unban' or blocks[2] == 'untempban' then
				local user_id = blocks[3]
				local res = api.unbanUser(chat_id, user_id)
				if not res then
					api.answerCallbackQuery(msg.cb_id, '🔹 مشکلی وجود دارد! احتمالا من ادمین گروه نیستم.', true)
				else
					api.answerCallbackQuery(msg.cb_id, '🔻 کاربر مورد نظر آنبن شد.', true)
					local key = {inline_keyboard={{{text = 'کاربر از لیست مسدود خارج شد ✅', callback_data = 'aaaa'}}}}
					api.editMessageText(msg.chat.id, msg.message_id, msg.original_text..('\n\n✅ کاربر از لیست مسدود خارج شد (توسط ادمین: %s)'):format(u.getname_final(msg.from)), 'html', key)
				end
			end
			if blocks[2] == 'unsilent' then
				local user_id = blocks[3]
				local change_permis = {
					can_send_messages = true,
					can_send_media_messages = true,
					can_send_other_messages = true,
					can_add_web_page_previews = true
				}
				local res = api.restrictChatMember(chat_id, user_id, change_permis)
				if not res then
					api.answerCallbackQuery(msg.cb_id, '🔹 مشکلی وجود دارد! احتمالا من ادمین گروه نیستم.', true)
				else
					api.answerCallbackQuery(msg.cb_id, '🔻 کاربر مورد نظر از لیست سایلنت ها خارج شد.', true)
					local key = {inline_keyboard={{{text = 'کاربر از لیست سایلنت خارج شد ✅', callback_data = 'aaaa'}}}}
					api.editMessageText(msg.chat.id, msg.message_id, msg.original_text..('\n\n✅ کاربر از لیست سایلنت خارج شد (توسط ادمین: %s)'):format(u.getname_final(msg.from)), 'html', key)
				end
			end
		end
	end

	if blocks[1] == 'config' then
		local keyboard, text
	  if chat_id and not msg.from.admin then
			api.answerCallbackQuery(msg.cb_id, ("متاسفانه شما مدیر گروه نمی باشید."), true)
		else
			local t, k = u.join_channel(msg.from.id, 'config:logchannel:'..chat_id)
			if t and k then
				api.editMessageText(msg.chat.id, msg.message_id, t, true, k)
				return
			end
			--------------------------------- ==> [[Check logchannel]] <== ---------------------------------
			local check_ch = db:hget('bot:chatlogs', chat_id)
			if not check_ch then
				api.editMessageText(user_id, msg.message_id, f_text, true, fr_keyboard(chat_id))
			else
				keyboard = doKeyboard_logchannel(chat_id)
				api.editMessageText(user_id, msg.message_id, org_text, true, keyboard)
			end
		end
	end

	if blocks[1] == 'set_ch' then
		db:setex('logchannel:waiting:'..user_id, 3600, chat_id)
		local keyboard = {inline_keyboard = {{{text = 'لغو عملیات 🚫', callback_data = 'logchannel:cancel_set:'..chat_id}}}}
		api.sendMessage(user_id, '🔹 لطفا دستور را در کانال وارد کرده و آن را برای من فوروارد کنید...', true, keyboard)
		api.editMessageText(user_id, msg.message_id, f_text, true)
	end

	if blocks[1] == 'cancel_set' then
		db:del('logchannel:waiting:'..user_id)
		api.editMessageText(user_id, msg.message_id, '🚫 عملیات لغو شد.')
		api.sendMessage(user_id, f_text, true, fr_keyboard(chat_id))
	end

	if blocks[1] == 'delete_channel' then
		if db:get('logchannel:del_ch:'..chat_id) then
			api.answerCallbackQuery(msg.cb_id, '🔸 کانال رویداد با موفقیت حذف شد.', true)
			local ch_id = db:hget('bot:chatlogs', chat_id)
			api.sendMessage(ch_id, ('به درخواست ادمین %s، من از کانال خارج می شوم.'):format(u.getname_final(msg.from)), 'html')
			api.leaveChat(ch_id)
			db:hdel('bot:chatlogs', chat_id)
			db:del('logchannel:del_ch:'..chat_id)
			api.editMessageText(user_id, msg.message_id, f_text, true, fr_keyboard(chat_id))
		else
			api.answerCallbackQuery(msg.cb_id, '🔻 آیا شما از انجام این کار مطمئن هستید؟ اگر مطمئن هستید بار دیگر روی این دکمه بزنید.', true)
			db:setex('logchannel:del_ch:'..chat_id, 60, true)
		end
	end

	if blocks[1] == 'select_all' then
		for event, _ in pairs(config.chat_settings['tolog']) do
			db:hset('chat:'..chat_id..':tolog', event, 'yes')
		end
		api.answerCallbackQuery(msg.cb_id, 'تمام گزینه ها انتخاب شدند.')
		api.editMessageReplyMarkup(user_id, msg.message_id, doKeyboard_logchannel(chat_id))
	end

	if blocks[1] == 'unselect_all' then
		for event, _ in pairs(config.chat_settings['tolog']) do
			db:hset('chat:'..chat_id..':tolog', event, 'no')
		end
		api.answerCallbackQuery(msg.cb_id, 'تمام گزینه ها لغو شدند.')
		api.editMessageReplyMarkup(user_id, msg.message_id, doKeyboard_logchannel(chat_id))
	end

	if blocks[1] == 'alert' then
		local text = get_alert_text(blocks[2])
		api.answerCallbackQuery(msg.cb_id, text, true, config.bot_settings.cache_time.alert_help)
	end

	if blocks[1] == 'toggle' then
		local text = toggle_event(chat_id, blocks[2])
		if text then
			api.answerCallbackQuery(msg.cb_id, text)
		end
		api.editMessageReplyMarkup(user_id, msg.message_id, doKeyboard_logchannel(chat_id))
	end

end

function plugin.onTextMessage(msg, blocks)
	local user_id = msg.from.id
	if msg.chat.type == 'private' then

		local chat_id = db:get('logchannel:waiting:'..user_id)

		if chat_id then
			local keyboard = {inline_keyboard = {{{text = 'لغو عملیات 🚫', callback_data = 'logchannel:cancel_set:'..chat_id}}}}
			if blocks[1] == 'setlog' or blocks[1] == 'ثبت کانال' then
				if msg.forward_from_chat then
					if msg.forward_from_chat.type == 'channel' then
						if not msg.forward_from_chat.username then
							local res, code = api.getChatMember(msg.forward_from_chat.id, msg.from.id)
							if not res then
								if code == 429 then
									api.sendReply(msg, ('🔻 تلاش زیاد! لطفا بعدا امتحان کنید.'), true)
									db:del('logchannel:waiting:'..user_id)
								else
									api.sendReply(msg, ('🔻 من باید در کانال شما ادمین باشم.'), true, keyboard)
								end
							else
								if res.result.status == 'creator' then
									local text
									local old_log = db:hget('bot:chatlogs', chat_id)
									if old_log == tostring(msg.forward_from_chat.id) then
										text = ('🔻 این کانال از قبل اضافه شده بود.')
									else
										db:hset('bot:chatlogs', chat_id,  msg.forward_from_chat.id)
										text = ('🔻 کانال با موفقیت اضافه شد :)')
										local info = api.getChat(chat_id)
										api.sendMessage(msg.forward_from_chat.id, ('از این به بعد رویداد های مربوط به گروه "%s" در این کانال ارسال خواهند شد.'):format(info.result.title:escape_html()), 'html')
										api.sendMessage(msg.from.id, org_text, true, doKeyboard_logchannel(chat_id))
									end
									api.sendReply(msg, text, true)
									db:del('logchannel:waiting:'..user_id)
								else
									api.sendReply(msg, ('🔻 تنها سازنده کانال می تواند کانال را اضافه کند.'), true, keyboard)
									db:del('logchannel:waiting:'..user_id)
								end
							end
						else
							api.sendReply(msg, ('🔻 کانال باید خصوصی باشد! لطفا مجدد امتحان کنید.'), true, keyboard)
						end
					end
				else
					api.sendReply(msg, ('🔻 شما حتما باید عبارت "ثبت کانال" یا "setlog" را از کانال خود فوروارد کنید!'), true, keyboard)
				end
			else
				api.sendReply(msg, ('🔻 لطفا دستور setlog/ یا به فارسی "ثبت کانال" را در کانال خصوصی خود زده و آن را در اینجا فوروارد کنید.'))
			end
		end

		if blocks[1] == 'photo' then
			api.sendPhotoId(msg.chat.id, blocks[2], nil, '🔸 عکس جدید گروه')
		end
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(setlog)$',
		config.cmd..'(unsetlog)$',
		config.cmd..'(logchannel)$',
		'(setlog)$',
		'^(ثبت کانال)$',

		--deeplinking from log buttons
		'^/start (photo)_(.*)$'
	},
	onCallbackQuery = {
		 --callbacks from the log channel
		'^###cb:(logcb):(%w-):(%d+):(-%d+)$',

		--callbacks from the configuration keyboard
		'^###cb:logchannel:(toggle):([%w_]+):(-?%d+)$',
		'^###cb:logchannel:(alert):([%w_]+)$',
		'^###cb:logchannel:([%w_]+):(-?%d+)$',
		'^###cb:(config):logchannel:(-?%d+)$'
	}
}

return plugin
