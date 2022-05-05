local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function is_on(chat_id, setting)
	local hash = 'chat:'..chat_id..':settings'
	local current = db:hget(hash, setting) or config.chat_settings.settings[setting]
	if current == 'on' then
		return true
	else
		return false
	end
end

local function ban_bots(msg)
	if msg.from.id == msg.new_chat_member.id or msg.from.admin then
		return
	else
		local status = db:hget(('chat:%d:settings'):format(msg.chat.id), 'Antibot')
		if status and status == 'on' then
			local users = msg.new_chat_members
			local n = 0 --bots banned
			for i = 1, #users do
				if users[i].is_bot == true then
					api.banUser(msg.chat.id, users[i].id)
					n = n + 1
				end
			end
			if n == #users then
				local text = ('🔻 تعداد <b>%s</b> ربات که توسط کاربر %s اضافه شده بود، حذف شد.'):format(n, u.getname_final(msg.from))
				local keyboard
				local AntiButton = db:hget('chat:'..msg.chat.id..':settings', 'Antibotbutton') or config.chat_settings['settings']['Antibotbutton']
				if AntiButton and AntiButton == 'on' then
					keyboard = {inline_keyboard = {{{text = '⛔️ مسدود کردن کاربر', callback_data = 'welcome:ban_user:'..msg.from.id}}}}
				end
				api.sendMessage(msg.chat.id, text, 'html', keyboard)
				return true
			end
		end
	end
end

local function get_welcome(msg)
	if not is_on(msg.chat.id, 'Welcome') then
		return false
	end

	local hash = 'chat:'..msg.chat.id..':welcome'
	local type = (db:hget(hash, 'type')) or config.chat_settings['welcome']['type']
	local content = (db:hget(hash, 'content')) or config.chat_settings['welcome']['content']
	if type == 'media' then
		local file_id = content
		local caption = db:hget(hash, 'caption')
		local caption_replace = nil
		if caption then
			caption_replace = caption:replaceholders(msg)
		end
		local rules_button = db:hget('chat:'..msg.chat.id..':settings', 'Welbut') or config.chat_settings['settings']['Welbut']
		local reply_markup
		if rules_button == 'on' then
			reply_markup = {inline_keyboard={{{text = ('خواندن قوانین 📒'), url = u.deeplink_constructor(msg.chat.id, 'rules')}}}}
		end

		local res = api.sendDocumentId(msg.chat.id, file_id, nil, caption_replace, reply_markup, true)
		if res and is_on(msg.chat.id, 'Weldelchain') then
			local key = ('chat:%d:lastwelcome'):format(msg.chat.id) -- get the id of the last sent welcome message
			local message_id = db:get(key)
			if message_id then
				api.deleteMessage(msg.chat.id, message_id)
			end
			db:setex(key, 259200, res.result.message_id) --set the new message id to delete
		end
		return false
	elseif type == 'custom' then
		local reply_markup, new_text = u.reply_markup_from_text(content)
		return new_text:replaceholders(msg), reply_markup
	else
		return ("سلام %s خوش اومدی..."):format(msg.new_chat_member.first_name:escape())
	end
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'welcome' or blocks[1] == 'خوشامد' then

		if msg.chat.type == 'private' or not msg.from.admin then return end

		local input = blocks[2]

		if not input and not msg.reply then
			api.sendReply(msg, ("لطفا بعد از دستور welcome/، متن خودتان را بنویسید.\n*/welcome سلام خیلی خوش اومدی*")) return
		end

		local hash = 'chat:'..msg.chat.id..':welcome'

		if not input and msg.reply then
			local replied_to = u.get_media_type(msg.reply)
			if replied_to == 'sticker' or replied_to == 'gif' then
				local file_id
				if replied_to == 'sticker' then
					replied_to = 'استیکر'
					file_id = msg.reply.sticker.file_id
				else
					replied_to = 'گیف'
					file_id = msg.reply.document.file_id
				end
				db:hset(hash, 'type', 'media')
				db:hset(hash, 'content', file_id)
				if msg.reply.caption then
					db:hset(hash, 'caption', msg.reply.caption)
				else
					db:hdel(hash, 'caption') --remove the caption key if the new media doesn't have a caption
				end
				-- turn on the welcome message in the group settings
				db:hset(('chat:%d:settings'):format(msg.chat.id), 'Welcome', 'on')
				api.sendReply(msg, ("رسانه `%s` با موفقیت انتخاب شد. از این پس هرکس وارد گروه شود، این رسانه به اون نشان داده می شود."):format(replied_to), true)
			else
				api.sendReply(msg, ("لطفا برای تنظیم پیام خوش آمدگویی، فقط روی استیکر یا گیف ریپلای کنید."), true)
			end
		else
			db:hset(hash, 'type', 'custom')
			db:hset(hash, 'content', input)

			local reply_markup, new_text = u.reply_markup_from_text(input)

			local res, code = api.sendReply(msg, new_text:gsub('$rules', u.deeplink_constructor(msg.chat.id, 'rules')), true, reply_markup)
			if not res then
				db:hset(hash, 'type', 'no') --if wrong markdown, remove 'custom' again
				db:hset(hash, 'content', 'no')
				api.sendMessage(msg.chat.id, u.get_sm_error_string(code), true)
			else
				-- turn on the welcome message in the group settings
				db:hset(('chat:%d:settings'):format(msg.chat.id), 'Welcome', 'on')
				local id = res.result.message_id
				api.editMessageText(msg.chat.id, id, ("پیام خوش آمدگویی شما با موفقیت ذخیره شد."), true)
			end
		end
	end

	if blocks[1]:lower() == 'setaddnumber' or blocks[1] == 'تنظیم اجباری' then
		if not msg.from.admin then return end
		if not u.is_vip_group(msg.chat.id) then
			api.sendReply(msg, "این قابلیت تنها برای حساب های ویژه فعال می باشد!\nاطلاعات بیشتر با ارسال دستور /panel")
			return
		end
		local number = blocks[2]
		if not number then
			api.sendReply(msg, "لطفا تعداد افرادی که باید توسط عضو جدید اضافه شوند را جلوی دستور وارد کنید.\nمثال:\n`/setaddnumber 10`", true)
			return
		end
		if tonumber(blocks[2]) < 1 and tonumber(blocks[2]) > 100 then
			api.sendReply(msg, "عدد باید بین 1 تا 100 باشد.")
			return
		end
		db:hset('chat:'..msg.chat.id..':force', 'forceNumber', number)
		api.sendReply(msg, ('از این پس کاربران باید %s عضو به گروه اضافه کنند تا دسترسی چت کردن را دریافت کنند.'):format(number))
	end

	if blocks[1]:lower() == 'setadd' or blocks[1] == 'اد اجباری' then
		if not msg.from.admin then return end
		if not u.is_vip_group(msg.chat.id) then
			api.sendReply(msg, "این قابلیت تنها برای حساب های ویژه فعال می باشد!\nاطلاعات بیشتر با ارسال دستور /panel")
			return
		end
		local status = blocks[2]
		if not status then
			api.sendReply(msg, "لطفا وضعیت اد اجباری را جلوی دستور وارد کنید.\nمثال:\n`/setadd on`\n\nدر صورتی که نیاز به راهنمای بیشتری دارید، به پیوی ربات مراجعه کنید و دستور /help را ارسال کنید.", true)
			return
		end
		local text
		if blocks[2] == 'on'  or blocks[2] == 'روشن' then
			db:hset('chat:'..msg.chat.id..':force', 'status', 'on')
			text = "قفل اد اجباری با موفقیت فعال شد.\nلطفا با دستور setaddnumber/ تنظیم کنید هر کاربر چه مقدار عضو اضافه کند؟\nمثال:\n`/setaddnumber 5`"
		elseif blocks[2] == 'off' or blocks[2] == 'خاموش' then
			db:hset('chat:'..msg.chat.id..':force', 'status', 'off')
			text = "قفل اد اجباری غیر فعال شد."
		else
			text = "دستور مورد نظر صحیح نمی باشد...\nدر صورتی که به راهنما نیاز دارید، دستور /help را بفرستید و بخش اد اجباری را مطالئه کنید."
		end
		api.sendReply(msg, text, true)
	end


	if blocks[1] == 'new_chat_member' then
		if not msg.service then return end

		if db:hget('chat:'..msg.chat.id..':ads', 'tgservice') == "on" then
			api.deleteMessage(msg.chat.id, msg.message_id)
		end

		local extra
		if msg.from.id ~= msg.new_chat_member.id then -- if user added to group
			extra = msg.from
		end
		u.logEvent(blocks[1], msg, extra)

		local stop = ban_bots(msg)
		if stop then return end

		local chat_id = msg.chat.id
		if u.is_vip_group(chat_id) then
			local forceStatus = db:hget('chat:'..chat_id..':force', 'status') or 'off'
			local forceNum = db:hget('chat:'..chat_id..':force', 'forceNumber') or 0
			if forceStatus ~= 'off' and tonumber(forceNum) > 0 then
				local newUsers = msg.new_chat_members
				local hash = 'chat:'..chat_id..':forceUsers'
				if msg.from.id == msg.new_chat_member.id then -- if user joined via link
					print("User joined and muted :)")
					db:hset(hash, msg.from.id, true)
				else -- if added someone else
					print("User added "..#newUsers.." new users")
					for i = 1, #newUsers do
						db:hset(hash, newUsers[i].id, true) -- mute new user
						db:sadd("chat:"..chat_id..":forceUser:"..msg.from.id, newUsers[i].id) -- add new user to list
					end
				end
				if tonumber(db:scard("chat:"..chat_id..":forceUser:"..msg.from.id)) >= tonumber(forceNum) then
					db:hdel(hash, msg.from.id)
					print("User is free as a bird 2")
				end
			end
		end

		

		local text, reply_markup = get_welcome(msg)
		if text then --if not text: welcome is locked or is a gif/sticker
			local attach_button = (db:hget('chat:'..chat_id..':settings', 'Welbut')) or config.chat_settings['settings']['Welbut']
			if attach_button == 'on' then
				if not reply_markup then reply_markup = {inline_keyboard={}} end
				local line = {{text = ('خواندن قوانین 📒'), url = u.deeplink_constructor(chat_id, 'rules')}}
				table.insert(reply_markup.inline_keyboard, line)
			end
			local link_preview = text:find('telegra%.ph/') ~= nil
			local res, code = api.sendMessage(chat_id, text, true, reply_markup, nil, link_preview)
			if not res and code == 160 then
				u.remGroup(chat_id, true)
				api.leaveChat(chat_id)
				return
			end
			if res and is_on(chat_id, 'Weldelchain') then
				local key = ('chat:%d:lastwelcome'):format(chat_id) -- get the id of the last sent welcome message
				local message_id = db:get(key)
				if message_id then
					api.deleteMessage(chat_id, message_id)
				end
				db:setex(key, 259200, res.result.message_id) --set the new message id to delete
			end
		end

		local send_rules_private = db:hget('user:'..msg.new_chat_member.id..':settings', 'rules_on_join')
		if send_rules_private and send_rules_private == 'on' then
			local rules = db:hget('chat:'..chat_id..':info', 'rules')
			if rules then
				api.sendMessage(msg.new_chat_member.id, rules, true)
			end
		end
	end

	if blocks[1] == 'left_chat_member' then
		if not msg.service then return end

		local status = db:hget('chat:'..msg.chat.id..':vip', 'Tgservice')
		if status and status == 'on' then
			api.deleteMessage(msg.chat.id, msg.message_id)
			return
		end

	end

end

function plugin.onCallbackQuery(msg, blocks)
	if u.can(msg.chat.id, msg.from.id, 'can_restrict_members') then
		if blocks[1] == 'ban_user' then
			local get_user = api.getChatMember(msg.chat.id, blocks[2])
			if get_user then
				get_user = get_user.result
			end
			local res = api.banUser(msg.chat.id, blocks[2])
			if not res then
				api.answerCallbackQuery(msg.cb_id, '⭕️ من نمیتوانم این کاربر رو اخراج کنم!\nاحتمالا من ادمین نیستم یا این کاربر از گروه خارج شده است.', true)
				return
			else
				local name, admin = u.getname_final(get_user.user), u.getname_final(msg.from)
				api.answerCallbackQuery(msg.cb_id, '✅ کاربر مورد نظر با موفقیت اخراج شد!')
				api.editMessageText(msg.chat.id, msg.message_id, ('کاربر %s توسط ادمین %s اخراج شد.\nدلیل اخراج: اضافه کردن ربات'):format(name, admin), 'html')
				u.logEvent('ban', msg, {motivation = 'اضافه کردن ربات', admin = admin, user = name, user_id = blocks[2]})
			end
		end
	else
		api.answerCallbackQuery(msg.cb_id, 'شما دسترسی انجام این کار را ندارید!', true, 1000)
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(welcome)$',
		config.cmd..'set(welcome)$',
		config.cmd..'(welcome) (.*)$',
		config.cmd..'set(welcome) (.*)$',
		config.cmd..'(setadd)$',
		config.cmd..'(setadd) (.*)$',
		config.cmd..'(setaddnumber)$',
		config.cmd..'(setaddnumber) (%d+)$',
		------------------------
		'^([Ww]elcome)$',
		'^[Ss]et(welcome)$',
		'^([Ww]elcome) (.*)$',
		'^[Ss]et(welcome) (.*)$',
		'^([Ss]etadd)$',
		'^([Ss]etadd) (.*)$',
		'^([Ss]etaddnumber)$',
		'^([Ss]etaddnumber) (%d+)$',
		-------------------------
		'^تنظیم (خوشامد)$',
		'^تنظیم (خوشامد) (.*)$',
		'^(خوشامد)$',
		'^(خوشامد) (.*)$',
		'^(اد اجباری)$',
		'^(اد اجباری) (.*)$',
		'^(تنظیم اجباری)$',
		'^(تنظیم اجباری) (.*)$',
		-------------------------
		'^###(new_chat_member)$',
		'^###(left_chat_member)$'
	},
	onCallbackQuery = {
		'^###cb:welcome:(ban_user):(%d+)$'
	}
}

return plugin
