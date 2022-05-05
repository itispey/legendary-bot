local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function doKeyboard_warn(user_id)
	local keyboard = {}
	keyboard.inline_keyboard = {{{text = ("حذف اخطار ❌"), callback_data = 'removewarn:'..user_id}}}

	return keyboard
end

local function forget_user_warns(chat_id, user_id)
	local removed = db:hdel('chat:'..chat_id..':warns', user_id)
	return removed
end

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type == 'private' then return end

	if not msg.from.admin then return end

	if blocks[1]:lower() == 'cleanwarn' or blocks[1] == 'پاکسازی اخطار ها' then
		local reply_markup = {inline_keyboard = {{{text = ('بله'), callback_data = 'cleanwarns:yes'}, {text = ('خیر'), callback_data = 'cleanwarns:no'}}}}
		api.sendMessage(msg.chat.id, ('آیا از این بابت اطمینان دارید که می خواهید تمامی اخطار های کاربران گروه را حذف کنید؟!'), true, reply_markup)
		return
	end

	--do not reply when...
	if not msg.reply or msg.reply.from.id == bot.id then return end
	--do not warn to admins
	if u.is_admin(msg.chat.id, msg.reply.from.id) then return end

	if blocks[1]:lower() == 'nowarn' or blocks[1] == 'حذف اخطار' then
		forget_user_warns(msg.chat.id, msg.reply.from.id)
		local admin = u.getname_final(msg.from)
		local user = u.getname_final(msg.reply.from)
		local text = ('اخطار های کاربر %s توسط ادمین %s حذف شد.'):format(user, admin)
		api.sendReply(msg, text, 'html')
		u.logEvent('nowarn', msg, {admin = admin, user = user, user_id = msg.reply.from.id})
	end

	if blocks[1]:lower() == 'warn' or blocks[1]:lower() == 'dwarn' or blocks[1] == 'اخطار' then

		if blocks[1]:lower() == 'dwarn' then
			api.deleteMessage(msg.chat.id, msg.reply.message_id)
		end

		local name = u.getname_final(msg.reply.from)
		local hash = 'chat:'..msg.chat.id..':warns'
		local num = db:hincrby(hash, msg.reply.from.id, 1) --add one warn
		local nmax = (db:hget('chat:'..msg.chat.id..':warnsettings', 'max')) or 3 --get the max num of warnings
		local text, res, motivation, hammer_log
		num, nmax = tonumber(num), tonumber(nmax)

		if num >= nmax then
			local type = (db:hget('chat:'..msg.chat.id..':warnsettings', 'type')) or 'kick'
			-- try to kick/ban
			local text = ("🔻 کاربر %s <code>%s</code> شد.\n⁉️ دلیل: رسیدن اخطار ها به <b>(%d/%d)</b>.")
			if type == 'ban' then
				hammer_log = ('مسدود')
				text = text:format(name, hammer_log, num, nmax)
				res, code, motivation = api.banUser(msg.chat.id, msg.reply.from.id)
			elseif type == 'kick' then --kick
				hammer_log = ('اخراج')
				text = text:format(name, hammer_log, num, nmax)
				res, code, motivation = api.kickUser(msg.chat.id, msg.reply.from.id)
			elseif type == 'mute' then --kick
				hammer_log = ('سایلنت')
				text = text:format(name, hammer_log, num, nmax)
				res, code, motivation = api.muteUser(msg.chat.id, msg.reply.from.id)
			end
			--if kick/ban fails, send the motivation
			if not res then
				if not motivation then
					motivation = ("من نمیتونم این کاربر رو اخراج کنم!\nاحتمال زیاد این کاربر ادمین هست یا من ادمین نیستم.")
				end
				if num > nmax then db:hset(hash, msg.reply.from.id, nmax) end --avoid to have a number of warnings bigger than the max
				text = motivation
			else
				forget_user_warns(msg.chat.id, msg.reply.from.id)
			end
			--if the user reached the max num of warns, kick and send message
			api.sendReply(msg, text, 'html')
			u.logEvent('warn', msg, {
				motivation = blocks[2],
				admin = u.getname_final(msg.from),
				user = u.getname_final(msg.reply.from),
				user_id = msg.reply.from.id,
				hammered = hammer_log,
				warns = num,
				warnmax = nmax
			})
		else
			local diff = nmax - num
			if blocks[2] then
				text = ("🔺 کاربر %s به دلیل <code>%s</code> اخطار دریافت کرد!\n⁉️ تعداد اخطار ها: <b>(%d/%d)</b>"):format(name, blocks[2], num, nmax)
			else
				text = ("🔺 کاربر %s اخطار دریافت کرد!\n⁉️ تعداد اخطار ها: <b>(%d/%d)</b>"):format(name, num, nmax)
			end
			local keyboard = doKeyboard_warn(msg.reply.from.id)
			if blocks[1] ~= 'sw' then api.sendMessage(msg.chat.id, text, 'html', keyboard) end
			u.logEvent('warn', msg, {
				motivation = blocks[2],
				warns = num,
				warnmax = nmax,
				admin = u.getname_final(msg.from),
				user = u.getname_final(msg.reply.from),
				user_id = msg.reply.from.id,
				warns = num,
				warnmax = nmax
			})
		end
	end
end

function plugin.onCallbackQuery(msg, blocks)
	if not msg.from.admin then
		api.answerCallbackQuery(msg.cb_id, ("شما مجاز به این کار نمی باشید."), true, (60 * 20)) return
	end

	if blocks[1] == 'removewarn' then
		local user_id = blocks[2]
		local num = db:hincrby('chat:'..msg.chat.id..':warns', user_id, -1) --add one warn
		local text, nmax, diff
		if tonumber(num) < 0 then
			text = ("🔺 تعداد اخطار های دریافتی این شخص صفر می باشد.")
			db:hincrby('chat:'..msg.chat.id..':warns', user_id, 1) --restore the previouvs number
		else
			nmax = (db:hget('chat:'..msg.chat.id..':warnsettings', 'max')) or 3 --get the max num of warnings
			diff = nmax - num
			text = ("🔺 اخطار با موفقیت حذف شد.\n<b>(%d/%d)</b>"):format(tonumber(num), tonumber(nmax))
		end

		text = text .. ("\n(توسط ادمین: %s)"):format(u.getname_final(msg.from))
		api.editMessageText(msg.chat.id, msg.message_id, text, 'html')
	end
	if blocks[1] == 'cleanwarns' then
		if blocks[2] == 'yes' then
			db:del('chat:'..msg.chat.id..':warns')
			api.editMessageText(msg.chat.id, msg.message_id, ('✅ تمامی اخطار های کاربران توسط ادمین %s حذف شد.'):format(u.getname_final(msg.from)), 'html')
		else
			api.editMessageText(msg.chat.id, msg.message_id, ('❌ حذف اخطار ها لغو شد.'), true)
		end
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(warn)$',
		config.cmd..'(dwarn)$',
		config.cmd..'(nowarn)s?$',
		config.cmd..'(warn) (.*)$',
		config.cmd..'(dwarn) (.*)$',
		config.cmd..'(cleanwarn)s?$',
		-----------------------------
		'^([Ww]arn)$',
		'^([Dd]warn)$',
		'^([Nn]owarn)s?$',
		'^([Ww]arn) (.*)$',
		'^([Dd]warn) (.*)$',
		'^([Cc]leanwarn)s?$',
		-----------------------------
		'^(اخطار)$',
		'^(حذف اخطار)$',
		'^(اخطار) (.*)$',
		'^(پاکسازی اخطار ها)$'
	},
	onCallbackQuery = {
		'^###cb:(resetwarns):(%d+)$',
		'^###cb:(removewarn):(%d+)$',
		'^###cb:(cleanwarns):(%a%a%a?)$'
	}
}

return plugin
