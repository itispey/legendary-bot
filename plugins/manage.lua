local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type ~= 'private' then
		-------------------------------------
		if blocks[1] == 'new_chat_photo' then
			u.logEvent('new_chat_photo', msg, {file_id = msg.new_chat_photo[#msg.new_chat_photo].file_id})
		end
		-------------------------------------
		if blocks[1] == 'delete_chat_photo' then
			u.logEvent('delete_chat_photo', msg)
		end
		-------------------------------------
		if blocks[1] == 'new_chat_title' then
			u.logEvent('new_chat_title', msg)
		end
		-------------------------------------
		if blocks[1] == 'pinned_message' then
			u.logEvent('pinned_message', msg)
		end
		-------------------------------------
		if not msg.from.admin then return end

		if blocks[1]:lower() == 'active' or blocks[1] == 'فعال' then
			local days = blocks[2] or 7
			if tonumber(days) > 30 then
				api.sendReply(msg, 'شما نمی توانید کاربران فعال بیشتر از 30 روز را مشاهده کنید.')
				return
			end
			local sec_day = 86400
			local users = db:hgetall('chat:'..msg.chat.id..':userlast')
			local n = 0
			for users_id, timestamp in pairs(users) do
				if tonumber(timestamp) > (os.time() - (86400 * days)) then
					n = n + 1
				end
			end
			api.sendReply(msg, ('🔻 تعداد کاربران فعال گروه شما در %s روز گذشته، <b>[%s]</b> نفر می باشد.'):format(days, n), 'html')
		end

		--[[if blocks[1]:lower() == 'poll' then
			if not blocks[2] then
				api.sendReply(msg, '⁉️ لطفا سوال نظرسنجی و سپس پاسخ های آن را بنویسید.\nمثال:\npoll فردا تعطیل هست؟\nبله\nخیر')
				return
			end
			local value = u.split(blocks[2], "\n") -- convert lines to table
			local question = value[1]
			table.remove(value, 1) -- Remove question from table
			local res = api.sendPoll(msg.chat.id, question, value)
			if res then
				db:hset('user_polls_created:'..msg.from.id, res.result.message_id, question)
			end
		end

		if blocks[1]:lower() == 'pollinfo' then
			if msg.reply and msg.reply.poll then
				if msg.reply.from.id ~= bot.id then
					api.sendMessage(msg.chat.id, "⚠️ *خطا:* من تنها به نظرسنجی هایی که خودم درست کردم دسترسی دارم!", true, nil, msg.reply.message_id)
					return
				end
				local text_ = '🍑 پاسخ ها:\n'
				for _, info in pairs(msg.reply.poll.options) do
					text_ = text_..'• '..info.text..' - '..info.voter_count..' شرکت کننده\n'
				end
				local poll_status
				if msg.reply.poll.is_closed then
					poll_status = 'بسته شده'
				else
					poll_status = 'فعال'
				end
				local text = ([[
مشخصات نظرسنجی مورد نظر:

⁉️ سوال: %s

%s

🎗 وضعیت نظرسنجی: %s
				):format(msg.reply.poll.question, text_, poll_status)
				api.sendReply(msg, text)
			end
		end

		if blocks[1]:lower() == 'stoppoll' then
			local all = db:hgetall('user_polls_created:'..msg.from.id)
			local text
			local i = 0
			if not blocks[2] then
				if next(all) then
					text = '‼️ مایل هستید کدام یک از نظرسنجی های خود را متوقف کنید؟\n'
					..'لطفا کد نظرسنجی را در مقابل دستور بنویسید تا متوقف شود.\nمثال:\n'
					..'!stoppoll 1142\n➖➖➖➖➖\nنظرسنجی های شما:\n'
					for msg_id, title in pairs(all) do
						i = i + 1
						text = text..i..'. '..title..'\nکد: '..msg_id..'\n\n'
					end
				else
					text = 'شما تاکنون نظرسنجی ایجاد نکردید.'
				end
			else
				local del = db:hdel('user_polls_created:'..msg.from.id, blocks[2])
				if del == 1 then
					text = 'نظرسنجی مورد نظر با کد '..blocks[2]..' متوقف شد.'
					api.stopPoll(msg.chat.id, blocks[2])
				else
					text = 'نظرسنجی مورد نظر پیدا نشد.'
				end
			end
			api.sendReply(msg, text)
		end]]
    	------------------------------------
		local name = u.getname_final(msg.from)
		----------------------- [If user can change info] ------------------------
		if u.can(msg.chat.id, msg.from.id, 'can_change_info') then
			---------------------------- [Set chat photo] --------------------------
			if blocks[1]:lower() == 'setphoto' or blocks[1] == 'تنظیم پروفایل' then
				if msg.reply then
					if msg.reply.photo then
						local file_id = msg.reply.photo[#msg.reply.photo].file_id
						local res = api.getFile(file_id)
						local file_path = u.telegram_file_link(res)
						local file_link = u.download_to_file(file_path, string.format('/home/api/Legend/data/photos/%s.jpg', msg.chat.id))
						api.setChatPhoto(msg.chat.id , file_link)
            			api.sendMessage(msg.chat.id, ("عکس گروه با موفقیت تغییر کرد.\nتوسط ادمین (%s)"):format(name), 'html')
					end
				else
					api.sendMessage(msg.chat.id, ("لطفا روی یک عکس ریپلای کنید."))
				end
			end
			---------------------------- [Del chat photo] --------------------------
			if blocks[1]:lower() == 'delphoto' or blocks[1] == 'حذف پروفایل' then
				api.deleteChatPhoto(msg.chat.id)
				api.sendMessage(msg.chat.id, ("عکس گروه با موفقیت حذف شد.\nتوسط ادمین (%s)"):format(name), 'html')
			end
			---------------------------- [Set chat name] ---------------------------
			if blocks[1]:lower() == 'setname' or blocks[1] == 'تنظیم نام' then
				local text
				local title = blocks[2]
				if not title then
					api.sendReply(msg, 'لطفا بعد از دستور، نام گروه را بنویسید.\n*/setname گروه دختر پسرای باحال*', true)
					return
				end
				local char = string.len(title)
				if char > 510 then
					text = ('تعداد حروف مجاز برای نام گروه، *255* کاراکتر می باشد!\nمتن شما دارای *%d* کاراکتر است.'):format(math.floor(char/2))
					api.sendReply(msg, text, true)
					return
				else
					api.setChatTitle(msg.chat.id, title)
					text = ("نام گروه با موفقیت عوض شد!\nنام جدید گروه: <b>%s</b>\nتوسط ادمین (%s)"):format(title:escape_html(), name)
					api.sendMessage(msg.chat.id, text, 'html')
					return
				end
			end
			------------------------ [Set chat description] ------------------------
			if blocks[1]:lower() == 'setdes' or blocks[1] == 'تنظیم توضیحات' then
				local text
				local des = blocks[2]
				if not des then
					api.sendReply(msg, 'لطفا بعد از دستور، توضیحات گروه را بنویسید.\n*/setdes به گروه خودتون خوش آمدید.*', true)
					return
				end
				local char = string.len(des)
				if char > 510 then
					text = ('تعداد حروف مجاز برای این بخش *255* کاراکتر برای حروف انگلیسی و *510* کاراکتر برای حروف فارسی می باشد\nمتن شما دارای *%d* کاراکتر است.'):format(char)
					api.sendReply(msg, text, true)
					return
				else
					api.setChatDescription(msg.chat.id, des)
					text = ("توضیحات گروه با موفقیت عوض شد!\nتوسط ادمین (%s)"):format(name)
					api.sendMessage(msg.chat.id, text, 'html')
					return
				end
			end
			------------------------------------------------------------------------
		end
		----------------------- [If user can pin message] ------------------------
		if u.can(msg.chat.id, msg.from.id, 'can_pin_messages') then
			---------------------------- [Pin message] -----------------------------
			if blocks[1]:lower() == 'pin' or blocks[1] == 'سنجاق' then
				if msg.reply then
					local res = api.pinChatMessage(msg.chat.id, msg.reply.message_id)
					if res then
						api.sendMessage(msg.chat.id, 'پیام مورد نظر شما سنجاق شد.')
						return
					end
				else
					api.sendMessage(msg.chat.id, 'لطفا روی یک پیام ریپلای کنید.')
					return
				end
			end
			--------------------------- [Unpin message] ----------------------------
			if blocks[1]:lower() == 'unpin' or blocks[1] == 'حذف سنجاق' then
				local res = api.unpinChatMessage(msg.chat.id)
				if res then
					api.sendReply(msg, 'پیام مورد نظر شما از حالت سنجاق خارج شد.')
				end
			end
			------------------------------------------------------------------------
		end
		----------------------------------------------------------------------------
	end
end

plugin.triggers = {
  onTextMessage = {
	config.cmd..'([Aa]ctive)$',
	config.cmd..'([Aa]ctive) (%d+)$',
	config.cmd..'([Ss]etphoto)$',
	config.cmd..'([Dd]elphoto)$',
	config.cmd..'([Ss]etname)$',
	config.cmd..'([Ss]etname) (.*)$',
	config.cmd..'([Ss]etdes)$',
	config.cmd..'([Ss]etdes) (.*)$',
	config.cmd..'([Pp]in)$',
	config.cmd..'([Uu]npin)$',
	--config.cmd..'([Pp]oll)$',
	--config.cmd..'([Pp]oll) (.*)$',
	--config.cmd..'([Pp]ollinfo)$',
	--config.cmd..'([Ss]toppoll)$',
	--config.cmd..'([Ss]toppoll) (%d+)$',
  ------------------
	'^([Aa]ctive)$',
	'^([Aa]ctive) (%d+)$',
	'^([Ss]etphoto)$',
	'^([Dd]elphoto)$',
	'^([Ss]etname)$',
	'^([Ss]etname) (.*)$',
	'^([Ss]etdes)$',
	'^([Ss]etdes) (.*)$',
	'^([Pp]in)$',
	'^([Uu]npin)$',
	--'^([Pp]oll)$',
	--'^([Pp]oll) (.*)$',
	--'^([Pp]ollinfo)$',
	--'^([Ss]toppoll)$',
	--'^([Ss]toppoll) (%d+)$',
	------------------
	'^(فعال)$',
	'^(فعال) (%d+)$',
	'^(تنظیم پروفایل)$',
	'^(حذف پروفایل)$',
	'^(تنظیم نام)$',
	'^(تنظیم نام) (.*)$',
	'^(تنظیم توضیحات)$',
	'^(تنظیم توضیحات) (.*)$',
	'^(سنجاق)$',
	'^(حذف سنجاق)$',
	------------------
	'^###(new_chat_photo)$',
	'^###(delete_chat_photo)$',
	'^###(new_chat_title)$',
	'^###(pinned_message)$'
  }
}
return plugin
