local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local triggers2 = {
	'^%$(init)$',
	'^%$(admin)$',
	'^%$(stats)$',
	'^%$(addsuperadmin) (%d+)$',
	'^%$(remsuperadmin) (%d+)$',
	'^%$(superadminlist)$',
	'^%$(broadcast)$',
	'^%$(fwdbroadcast)$',
	'^%$(vip) (-%d+)$',
	'^%$(getlink) (.*)$',
	'^%$(lua) (.*)$',
	'^%$(run) (.*)$',
	'^%$(block)$',
	'^%$(block) (%d+)$',
	'^%$(unblock)$',
	'^%$(unblock) (%d+)$',
	'^%$(blockgp) (-%d+)$',
	'^%$(unblockgp) (-%d+)$',
	'^%$(leave) (-%d+)$',
	'^%$(leave)$',
	'^%$(api errors)$',
	'^%$(sendfile) (.*)$',
	'^%$(getusername) (%d+)$',
	'^%$(getid)',
	'^%$(getid) (@%a[%w_]+)',
	'^%$(tban) (get)$',
	'^%$(tban) (flush)$',
	'^%$(initgroup) (-%d+)$',
	'^%$(remgroup) (-%d+)$',
	'^%$(remgroup) (true) (-%d+)$',
	'^%$(cache) (.*)$',
	'^%$(initcache) (.*)$',
	'^%$(active) (%d%d?)$',
	'^%$(active)$',
	'^%$(permission)s?'
}

function plugin.cron()
	db:bgsave()
end

plugin.cron = nil

local function load_lua(code, msg)
	local output = loadstring('local msg = '..u.vtext(msg)..'\n'..code)()
	if not output then
		output = '`Done! (no output)`'
	else
		if type(output) == 'table' then
			output = u.vtext(output)
		end
		output = '```\n' .. output .. '\n```'
	end
	return output
end

local function match_pattern(pattern, text)
  if text then
		text = text:gsub('@'..bot.username, '')
		local matches = {}
		matches = { string.match(text, pattern) }
		if next(matches) then
			return matches
		end
  end
end

local function get_chat_id(msg)
	if msg.text:find('$chat') then
		return msg.chat.id
	elseif msg.text:find('-%d+') then
		return msg.text:match('(-%d+)')
	elseif msg.reply then
		if msg.reply.text:find('-%d+') then
			return msg.reply.text:match('(-%d+)')
		end
	else
		return false
	end
end

function plugin.onTextMessage(msg, blocks)

	if not u.is_superadmin(msg.from.id) then return end

	blocks = {}

	for i=1, #triggers2 do
		blocks = match_pattern(triggers2[i], msg.text)
		if blocks then break end
	end

	if not blocks or not next(blocks) then return true end --leave this plugin and continue to match the others

	if blocks[1] == 'admin' then
		api.sendMessage(msg.from.id, u.vtext(triggers2))
	end

	if blocks[1] == 'init' then
		local n_plugins = bot_init(true) or 0
		api.sendReply(msg, '*ربات بارگذاری شد*\n_ تعداد '..n_plugins..' پلاگین فعال می باشد._', true)
	end

	if blocks[1] == 'stats' then
		local text = '#مشخصات\n'
		local hash = 'bot:general'
		local names = db:hkeys(hash)
		local num = db:hvals(hash)
		for i = 1, #names do
			text = text..'> تعداد پیام دریافت شده: `'..num[i]..'`\n'
		end
		local usernames = db:hkeys('bot:usernames')
		local real_users = db:scard('legendary:users') or 0
		local real_groups = db:scard('legendary:groups') or 0
		local block_users = db:scard('legendary:blockedUsers') or 0
		local a_groups = db:hgetall('bot:chats:latsmsg')
		local active_groups = 0
		for chat_id, timestamp in pairs(a_groups) do
			if tonumber(timestamp) > (os.time() - (86400 * 7)) then
				active_groups = active_groups + 1
			end
		end
		text = text..'> یوزرنیم های ذخیره شده: `'..#usernames..'`\n'
		text = text..'> کاربران: `'..real_users..'`\n'
		text = text..'> گروه ها: `'..real_groups..'`\n'
		text = text..'> گروه های فعال 7 روز گذشته: `'..active_groups..'`\n'
		text = text..'> کاربران بلاک شده: `'..block_users..'`\n'
		--db info
		text = text.. '\n#دیتابیس\n'
		local dbinfo = db:info()
		text = text..'> مدت زمان فعالیت: `'..dbinfo.server.uptime_in_days..' روز ('..dbinfo.server.uptime_in_seconds..' ثانیه)`\n'
		text = text..'> درخواست ها:\n'
		for dbase, info in pairs(dbinfo.keyspace) do
			for real, num in pairs(info) do
				local keys = real:match('keys=(%d+),.*')
				if keys then
					text = text..'  '..dbase..': `'..keys..'`\n'
				end
			end
		end
		api.sendMessage(msg.chat.id, text, true)
	end

	if tonumber(msg.chat.id) == tonumber(config.log.chat) then
		if blocks[1] == 'addsuperadmin' then
			local user_id = blocks[2]
			if db:sismember("legendary:superAdmins", user_id) then
				api.sendReply(msg, "کاربر مورد نظر شما هم اکنون سوپر ادمین می باشد.")
				return
			end
			db:sadd("legendary:superAdmins", user_id)
			api.sendReply(msg, "کاربر مورد نظر شما با موفقیت به لیست اضافه شد :)")
		end

		if blocks[1] == 'remsuperadmin' then
			local user_id = blocks[2]
			if not db:sismember("legendary:superAdmins", user_id) then
				api.sendReply(msg, "کاربر مورد نظر در لیست سوپرادمین نمی باشد.")
				return
			end
			db:srem("legendary:superAdmins", user_id)
			api.sendReply(msg, "این کاربر از لیست سوپرادمین حذف شد.")
		end

		if blocks[1] == 'superadminlist' then
			local list = db:smembers("legendary:superAdmins")
			local text = "لیست سوپرادمین ها:\n\n"
			if next(list) then
				for i = 1, #list do
					text = text..i..'. `'..list[i]..'`\n'
				end
			else
				text = "لیست سوپر ادمین ها خالی می باشد :("
			end
			api.sendReply(msg, text, true)
		end
	end

	if blocks[1] == 'broadcast' or blocks[1] == 'fwdbroadcast' then
		if not msg.reply then
			api.sendReply(msg, "لطفا روی پیام مورد نظر ریپلای کنید.")
			return
		end
		api.sendReply(msg, "در حال ارسال... این روند ممکن است چند دقیقه طول بکشد.")
		local groups = db:smembers('legendary:groups')
		local n = 0
		if blocks[1] == 'broadcast' then
			for i = 1, #groups do
				if not db:sismember('legendary:vipGroups', chat_id) then
					local res = api.sendMessage(groups[i], msg.reply.text)
					if res then
						n = n + 1
					end
				end
			end
		elseif blocks[1] == 'fwdbroadcast' then
			for i = 1, #groups do
				if not db:sismember('legendary:vipGroups', chat_id) then
					local res = api.forwardMessage(groups[i], msg.chat.id, msg.reply.message_id)
					if res then
						n = n + 1
					end
				end
			end
		end
		api.sendReply(msg, "پیام شما به "..n.." گروه ارسال شد.")
	end

	if blocks[1] == 'vip' then
		local data = u.loadFile(config.json_path)
		local id = blocks[2]
		if id:match('(-%d+)') then
			if data[tostring(id)] then
				local expire = u.getShamsiTime(data[tostring(id)]['expire_day'])
				api.sendReply(msg, 'شارژ گروه مورد نظر در تاریخ "'..expire..'" به اتمام می رسد.')
			else
				api.sendReply(msg, 'گروه مورد نظر وی آی پی نمی باشد.')
			end
		end
	end

	if blocks[1] == 'getlink' then
		local res = api.exportChatInviteLink(blocks[2])
		local text
		if res then
			text = res.result
		else
			text = 'Access denied'
		end
		api.sendReply(msg, text)
	end

	if blocks[1] == 'lua' then
		local output = load_lua(blocks[2], msg)
		api.sendMessage(msg.chat.id, output, true)
	end

	if blocks[1] == 'run' then
		--read the output
		local output = io.popen(blocks[2]):read('*all')
		--check if the output has a text
		if output:len() == 0 then
			output = 'Done!'
		else
			output = '```\n'..output..'\n```'
		end
		api.sendMessage(msg.chat.id, output, true, nil, msg.message_id)
	end

	if blocks[1] == 'block' then
		local id
		if msg.reply then
			if msg.reply.forward_from then
				id = msg.reply.forward_from.id
			end
		else
			id = blocks[2]
		end

		local data = u.loadFile(config.info_path)
		if not data['block_users'] then
			data['block_users'] = {}
			u.saveFile(config.info_path, data)
		end
		if data['block_users'][tostring(id)] then
			api.sendReply(msg, 'کاربر مورد نظر از قبل بلاک بوده است.')
		else
			db:sadd('legendary:blockedUsers', id)
			data['block_users'][tostring(id)] = {
				by = msg.from.first_name
			}
			u.saveFile(config.info_path, data)
			api.kickChatMember(config.channel_id, id)
			api.sendReply(msg, 'کاربر مورد نظر برای همیشه از ربات بلاک شد.')
			api.sendMessage(id, 'شما از تمامی ربات های لجندری بلاک شدید ❌')
		end
	end

	if blocks[1] == 'unblock' then
		local id
		if msg.reply then
			if msg.reply.forward_from then
				id = msg.reply.forward_from.id
			end
		else
			id = blocks[2]
		end
		local data = u.loadFile(config.info_path)
		if not data['block_users'][tostring(id)] then
			api.sendReply(msg, 'کاربر مورد نظر هیچوقت بلاک نبوده است.')
		else
			db:srem('legendary:blockedUsers', id)
			data['block_users'][tostring(id)] = nil
			u.saveFile(config.info_path, data)
			api.unbanChatMember(config.channel_id, id)
			api.sendReply(msg, 'کاربر مورد نظر با موفقیت آنبلاک شد.')
			api.sendMessage(id, 'شما از لیست بلاک خارج شدید ✅')
		end
	end

	if blocks[1] == 'blockgp' then
		local chat_id = blocks[2]
		local data = u.loadFile(config.info_path)
		if not data['block_groups'] then
			data['block_groups'] = {}
			u.saveFile(config.info_path, data)
		end
		if data['block_groups'][tostring(chat_id)] then
			api.sendReply(msg, 'گروه مورد نظر از قبل بلاک بوده است!')
		else
			data['block_groups'][tostring(chat_id)] = {by = msg.from.first_name}
			u.saveFile(config.info_path, data)
			db:sadd('legendary:blockedGroups', chat_id)
			u.remGroup(chat_id)
			api.leaveChat(chat_id)
			api.sendReply(msg, 'گروه مورد نظر شما با موفقیت بلاک شد.')
		end
	end

	if blocks[1] == 'unblockgp' then
		local chat_id = blocks[2]
		local data = u.loadFile(config.info_path)
		if not data['block_groups'][tostring(chat_id)] then
			api.sendReply(msg, 'این گروه هیچوقت بلاک نبوده است.')
		else
			data['block_groups'][tostring(chat_id)] = nil
			db:srem('legendary:blockedGroups', chat_id)
			u.saveFile(config.info_path, data)
			api.sendReply(msg, 'گروه مورد نظر شما آن بلاک شد.')
		end
	end

	if blocks[1] == 'sendpm' then
		local id = blocks[2]
		local text = blocks[3]
		local send = api.sendMessage(id, text, true)
		if not send then
			api.sendReply(msg, ("پیام شما ارسال نشد! ممکنه کاربر ربات رو بلاک کرده باشه یا اصلا استارت نکرده باشه!"), true)
		else
			api.sendReply(msg, ("پیام شما ارسال شد."), true)
		end
	end

	if blocks[1] == 'leave' then
		local chat_id = blocks[2]
		u.remGroup(chat_id)
		api.leaveChat(chat_id)
		api.sendReply(msg, "ربات با موفقیت از گروه مورد نظر خارج شد.")
	end

	if blocks[1] == 'api errors' then
		local t = db:hgetall('bot:errors')
		api.sendMessage(msg.chat.id, u.vtext(t))
	end

	if blocks[1] == 'sendfile' then
		local path = blocks[2]
		api.sendDocument(msg.from.id, path)
	end

	if blocks[1] == 'getid' then
		if msg.reply then
			if msg.reply.forward_from then
				api.sendMessage(msg.chat.id, '`'..msg.reply.forward_from.id..'`', true)
				return
			end
			if msg.reply.forward_from_chat then
				if msg.reply.forward_from_chat.type == 'channel' then
					api.sendMessage(msg.chat.id, '`'..msg.reply.forward_from_chat.id..'`', true)
					return
				end
			end
		end
		local user_id = u.resolve_user(blocks[2])
		api.sendMessage(msg.chat.id, '`'..user_id..'`')
	end

	if blocks[1] == 'getusername' then
		local user_id = blocks[2]
		local all = db:hgetall('bot:usernames')
		for username, id in pairs(all) do
			if tostring(id) == user_id then
				api.sendReply(msg, username)
				return
			end
		end
		api.sendReply(msg, 'Not found')
	end

	if blocks[1] == 'tban' then
		if blocks[2] == 'flush' then
			db:del('tempbanned')
			api.sendReply(msg, 'Flushed!')
		end
		if blocks[2] == 'get' then
			api.sendMessage(msg.chat.id, u.vtext(db:hgetall('tempbanned')))
		end
	end

	if blocks[1] == 'initgroup' then
		u.initGroup(blocks[2])
		api.sendMessage(msg.chat.id, 'Done')
	end

	if blocks[1] == 'remgroup' then
		local full = false
		local chat_id = blocks[2]
		if blocks[2] == 'true' then
			full = true
			chat_id = blocks[3]
		end
		u.remGroup(chat_id, full)
		api.sendMessage(msg.chat.id, 'Removed (heavy: '..tostring(full)..')')
	end

	if blocks[1] == 'cache' then
		local chat_id = get_chat_id(msg)
		local members = db:smembers('cache:chat:'..chat_id..':admins')
		for i=1, #members do
			local permissions = db:smembers("cache:chat:"..chat_id..":"..members[i]..":permissions")
			members[members[i]] = permissions
		end
		api.sendMessage(msg.chat.id, chat_id..' ➤ '..tostring(#members)..'\n'..u.vtext(members))
	end

	if blocks[1] == 'initcache' then
		local chat_id, text
		chat_id = get_chat_id(msg)
		local res, code = u.cache_adminlist(chat_id)
		if res then
			text = 'Cached ➤ '..code..' admins stored'
		else
			text = 'Failed: '..tostring(code)
		end
		api.sendMessage(msg.chat.id, text)
	end

	if blocks[1] == 'active' then
		local days = tonumber(blocks[2]) or 7
		local now = os.time()
		local seconds_per_day = 60*60*24
		local groups = db:hgetall('bot:chats:latsmsg')
		local n = 0
		for chat_id, timestamp in pairs(groups) do
			if tonumber(timestamp) > (now - (seconds_per_day * days)) then
				n = n + 1
			end
		end
		api.sendMessage(msg.chat.id, 'Active groups in the last '..days..' days: '..n)
	end

	if blocks[1] == 'permission' then
		local chat_id = get_chat_id(msg)
		if not chat_id then
			api.sendMessage(msg, "Can't find a chat_id")
		else
			local res = api.getChatMember(chat_id, bot.id)
			api.sendMessage(msg.chat.id, ('%s\n%s'):format(chat_id, u.vtext(res)))
		end
	end
end

plugin.triggers = {
	onTextMessage = {'^%$'}
}

return plugin
