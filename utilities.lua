local serpent = require 'serpent'
local config = require 'config'
local api = require 'methods'
local ltn12 = require 'ltn12'
local HTTPS = require 'ssl.https'

-- utilities.lua
-- Functions shared among plugins.

local utilities = {}

-- Escape markdown for Telegram. This function makes non-clickable usernames,
-- hashtags, commands, links and emails, if only_markup flag isn't setted.
function string:escape(only_markup)
	if not only_markup then
		-- insert word joiner
		self = self:gsub('([@#/.])(%w)', '%1\xE2\x81\xA0%2')
	end
	return self:gsub('[*_`[]', '\\%0')
end

function string:escape_html()
	self = self:gsub('&', '&amp;')
	self = self:gsub('"', '&quot;')
	self = self:gsub('<', '&lt;'):gsub('>', '&gt;')
	return self
end

-- Remove specified formating or all markdown. This function useful for put
-- names into message. It seems not possible send arbitrary text via markdown.
function string:escape_hard(ft)
	if ft == 'bold' then
		return self:gsub('%*', '')
	elseif ft == 'italic' then
		return self:gsub('_', '')
	elseif ft == 'fixed' then
		return self:gsub('`', '')
	elseif ft == 'link' then
		return self:gsub(']', '')
	else
		return self:gsub('[*_`[%]]', '')
	end
end

function utilities.version_info()
	local version = '5.3.2'
	local lastupdateEn = 'Sunday, March 22, 2020 (1:07)'
	local lastupdateFa = 'یک شنبه، 3 فروردین، 1399 (1:07)'
	return version, lastupdateEn, lastupdateFa
end

function utilities.split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function utilities.startCron()
	local plugins = {}
	for i, v in ipairs(config.plugins) do
		local p = require('plugins.'..v)
		package.loaded['plugins.'..v] = nil
		table.insert(plugins, p)
	end
	for i = 1, #plugins do
		if plugins[i].cron then
			local res, err = pcall(plugins[i].cron)
			print(clr.green..'Cron started...'..clr.reset)
			if not res then
				api.sendLog('An #error occurred (cron).\n'..err)
				return
			end
		end
	end
end

function utilities.saveFile(file_path, data)
	local s = JSON.encode(data)
	local f = io.open(file_path, 'w')
	f:write(s)
	f:close()
end

function utilities.loadFile(file_path)
	local file = io.open(file_path)
	local data_ = file:read('*all')
	file:close()
	local data = JSON.decode(data_)
	return data
end

function utilities.saveLog(file_path, text)
	if text == 'del' then
		local file = io.open(file_path, 'w')
		file:close()
		return
	end
	local file = io.open(file_path, 'w')
	file:write(text)
	file:close()
end

function utilities.loadLog(file_path)
	local file = io.open(file_path)
	if not file then
		utilities.saveLog(file_path, '')
		return ''
	end
	local text = file:read('*all')
	file:close()
	return text
end

function utilities.is_support(msg)
	--local data = utilities.loadFile(config.info_path)
	--if data['support_info'] and data['support_info']['id'] == msg.chat.id then
		return true
	--end
end

function utilities.wrongFormat()
	local text = ([[
کاربر گرامی؛
متن وارد شده به اشتباه مارک شده است!
شما می توانید طرز صحیح مارک کردن متن را در [این پست](https://t.me/LFHelp/3) بخوانید.
	]])
	return text
end

function utilities.can(chat_id, user_id, permission)
	if utilities.is_superadmin(user_id) then
		return true
	end

	local set = ("cache:chat:%s:%s:permissions"):format(chat_id, user_id)

	local set_admins = 'cache:chat:'..chat_id..':admins'
	if not db:exists(set_admins) then
		utilities.cache_adminlist(chat_id, res)
	end

	return db:sismember(set, permission)
end

function utilities.user_is_bot(user_id)
	if user_id.is_bot == true then
		return true
	else
		return false
	end
end

function utilities.bot_is_admin(chat_id)
	local info = api.getChatMember(chat_id, bot.id)
	if info then
		if info.result.status == "administrator" then
			return true
		end
	end
	return false
end

function utilities.is_vip_group(chat_id)
	return true
end

function utilities.is_free_user(chat_id, user_id)
	if db:hget('chat:'..chat_id..':deny', user_id) then
		return true
	end
end

function utilities.getShamsiTime(unix_time)
	local res = api.performRequest('phpapi.ir/time/unixtojalili.php?ts='..unix_time)
	if not res then return 'موردی جهت نمایش وجود ندارد' end
	local a = JSON.decode(res)
	if not a then return 'موردی جهت نمایش وجود ندارد' end
	local min, hour = a.minutes, a.hours
	if tonumber(min) < 10 then
		min = '0'..min
	end
	if tonumber(hour) < 10 then
		hour = '0'..hour
	end
	return string.format('%s %s %s (%s:%s)', a.monthday, a.monthname, a.year, hour, min)
end

function utilities.is_superadmin(user_id)
	for i=1, #config.superadmins do
		if tonumber(user_id) == config.superadmins[i] then
			return true
		end
	end
	return db:sismember("legendary:superAdmins", user_id)
end

function utilities.is_admin_request(msg)
	local res = api.getChatMember(msg.chat.id, msg.from.id)
	if not res then
		return false, false
	end
	local status = res.result.status
	if status == 'creator' or status == 'administrator' then
		return true, true
	else
		return false, true
	end
end

function utilities.join_channel(user_id, callback)
	--[[local res = api.getChatMember(config.channel_id, user_id)
	if not res or (res.result.status == 'kicked' or res.result.status == 'left') then
		local text = 
⛔️ کاربر گرامی!
شما برای استفاده از سرویس ربات لجندری، باید در کانال رسمی لجندری عضو باشید.
لطفا از طریق دکمه "عضویت"، اقدام به عضو شدن در کانال کنید و سپس توسط دکمه "ادامه"، ادامه مراحل را طی کنید!

با احترام؛ تیم لجندری
		
		local keyboard = {inline_keyboard = {
			{{text = 'عضویت', url = 'https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q'}},
			{{text = 'ادامه', callback_data = callback}}
		}}
		return text, keyboard
	end]]
	return false
end

-- Returns the admin status of the user. The first argument can be the message,
-- then the function checks the rights of the sender in the incoming chat.
function utilities.is_admin(chat_id, user_id)
	if type(chat_id) == 'table' then
		local msg = chat_id
		chat_id = msg.chat.id
		user_id = msg.from.id
	end

	if utilities.is_superadmin(user_id) then
		return true
	end

	local set = 'cache:chat:'..chat_id..':admins'
	if not db:exists(set) then
		utilities.cache_adminlist(chat_id, res)
	end
	return db:sismember(set, user_id)
end

function utilities.is_owner_request(msg)
	local status = api.getChatMember(msg.chat.id, msg.from.id).result.status
	if status == 'creator' then
		return true
	else
		return false
	end
end

function utilities.is_owner(chat_id, user_id)
	if type(chat_id) == 'table' then
		local msg = chat_id
		chat_id = msg.chat.id
		user_id = msg.from.id
	end

	local hash = 'cache:chat:'..chat_id..':owner'
	local owner_id, res = nil, true
	repeat
		owner_id = db:get(hash)
		if not owner_id then
			res = utilities.cache_adminlist(chat_id)
		end
	until owner_id or not res

	if owner_id then
		if tonumber(owner_id) == tonumber(user_id) then
			return true
		end
	end

	return false
end

function utilities.add_role(chat_id, user_obj)
	user_obj.admin = utilities.is_admin(chat_id, user_obj.id)

	return user_obj
end

local admins_permissions = {
	can_change_info = true,
	can_delete_messages = true,
	can_invite_users = true,
	can_restrict_members = true,
	can_pin_messages = true,
	can_promote_member = true
}

local function set_creator_permissions(chat_id, user_id)
	local set = ("cache:chat:%s:%s:permissions"):format(chat_id, user_id)
	for k, _ in pairs(admins_permissions) do
		db:sadd(set, k)
	end
end

function utilities.vipText()
	return 'استفاده از این قابلیت نیاز به داشتن اشتراک ویژه می باشد.\n'
	..'برای خرید حساب ویژه، دستور /panel را در گروه بزنید.'
end

function utilities.cache_adminlist(chat_id)
	print(clr.red..'['..os.date('%X')..']'..clr.green..'Cache adminlist of '..clr.magenta..chat_id..clr.green..' supergroup '..clr.reset)
	--local status, user_id = utilities.getAdditive(chat_id)
	local res = api.getChatAdministrators(chat_id)
	local res_bot = api.getChatMember(chat_id, bot.id)
	if not res then
		utilities.remGroup(chat_id)
		return false
	end
	
	local set = 'cache:chat:'..chat_id..':admins'
	local cache_time = config.bot_settings.cache_time.adminlist
	local set_permissions
	db:del(set)
	for _, admin in pairs(res.result) do
		if admin.status == 'creator' then
			db:set('cache:chat:'..chat_id..':owner', admin.user.id)
			set_creator_permissions(chat_id, admin.user.id)
		else
			set_permissions = 'cache:chat:'..chat_id..':'..admin.user.id..':permissions'
			db:del(set_permissions)
			for k, v in pairs(admin) do
				if v and admins_permissions[k] then
					db:sadd(set_permissions, k)
				end
			end
			db:expire(set_permissions, cache_time)
		end
		db:sadd(set, admin.user.id)
	end
	db:expire(set, cache_time)
	return true, #res.result or 0
end

function utilities.get_cached_admins_list(chat_id, second_try)
	local hash = 'cache:chat:'..chat_id..':admins'
	local list = db:smembers(hash)
	if not list or not next(list) then
		utilities.cache_adminlist(chat_id)
		if not second_try then
			return utilities.get_cached_admins_list(chat_id, true)
		else
			return false
		end
	else
		return list
	end
end

function utilities.is_blocked_global(id)
	--[[local data = utilities.loadFile(config.info_path) or {}
	if db:sismember('legendary:blockedUsers', id) then
		return true
	end
	if next(data['block_users']) then
		if data['block_users'][tostring(id)] then
			db:sadd('legendary:blockedUsers', id)
			return true
		end
	end]]
	return false
end

function string:trim() -- Trims whitespace from a string.
	local s = self:gsub('^%s*(.-)%s*$', '%1')
	return s
end

function utilities.dump(...)
	for _, value in pairs{...} do
		print(serpent.block(value, {comment=false}))
	end
end

function utilities.vtext(...)
	local lines = {}
	for _, value in pairs{...} do
		table.insert(lines, serpent.block(value, {comment=false}))
	end
	return table.concat(lines, '\n')
end

function utilities.download_to_file(url, file_path)
	print("url to download: "..url)
	local respbody = {}
	local options = {
		url = url,
		sink = ltn12.sink.table(respbody),
		redirect = true
	}
	-- nil, code, headers, status
	local response = nil
	options.redirect = false
	response = {HTTPS.request(options)}
	local code = response[2]
	local headers = response[3]
	local status = response[4]
	if code ~= 200 then return false, code end
	print("Saved to: "..file_path)
	file = io.open(file_path, "w+")
	file:write(table.concat(respbody))
	file:close()
	return file_path, code
end

function utilities.telegram_file_link(res)
	--res = table returned by getFile()
	return "https://api.telegram.org/file/bot"..config.api_token.."/"..res.result.file_path
end

function utilities.deeplink_constructor(chat_id, what)
	return 'https://telegram.me/'..bot.username..'?start='..chat_id..'_'..what
end

function table.clone(t)
  local new_t = {}
  local i, v = next(t, nil)
  while i do
	new_t[i] = v
	i, v = next(t, i)
  end
  return new_t
end

function utilities.get_date(timestamp)
	if not timestamp then
		timestamp = os.time()
	end
	return os.date('%d/%m/%y', timestamp)
end

-- Resolves username. Returns ID of user if it was early stored in date base.
-- Argument username must begin with symbol @ (commercial 'at')
function utilities.resolve_user(username)
	assert(username:byte(1) == string.byte('@'))
	username = username:lower()

	local stored_id = tonumber(db:hget('bot:usernames', username))
	if not stored_id then
		return false, "کاربر مورد نظر پیدا نشد.\nلطفا یک پیام از این کاربر فوروارد کنید تا بتونم پیداش کنم :)"
	else
		local user_obj = api.getChat(stored_id)
		if not user_obj then
			return stored_id
		else
			if not user_obj.result.username then
				return stored_id
			else
				if username ~= '@'..user_obj.result.username:lower() then
					db:hset('bot:usernames', '@'..user_obj.result.username:lower(), user_obj.result.id)
					return false, 'نام کاربری وارد شده اشتباه می باشد!'
				end
			end
		end
		assert(stored_id == user_obj.result.id)
		return user_obj.result.id
	end
end

function utilities.get_sm_error_string(code)
	local descriptions = {
		--[112] = ("این متن به اشتباه مارک شده است!.\n"
					--.. "ممکن هست در متن از *Underline* یا خط فاصله بزرگ استفاده شده باشد.\n"),
		[118] = ('این متن خیلی طولانی می باشد. حداکثر کاراکتر مجاز *4000* می باشد.'),
		[146] = ('یکی از لینک هایی که می خواهید درون دکمه شیشه ای قرار بدهید، اشتباه می باشد! لطفا لینک را چک کنید.'),
		[137] = ("یکی از دکمه های شیشه ای مشکلی دارد! احتمالا متن آن را ننوشته اید یا لینک آن اشتباه می باشد."),
		[149] = ("یکی از دکمه های شیشه ای مشکلی دارد! احتمالا متن آن را ننوشته اید یا لینک آن اشتباه می باشد."),
		[115] = ("لطفا یک متنی را وارد کنید.")
	}

	return descriptions[code] or ("فرمت متن اشتباه است.")
end

function string:escape_magic()
	self = self:gsub('%%', '%%%%')
	self = self:gsub('%-', '%%-')
	self = self:gsub('%?', '%%?')

	return self
end

function utilities.reply_markup_from_text(text)
	local clean_text = text
	local n = 0
	local reply_markup = {inline_keyboard={}}
	for label, url in text:gmatch("{{(.-)}{(.-)}}") do
		clean_text = clean_text:gsub('{{'..label:escape_magic()..'}{'..url:escape_magic()..'}}', '')
		if label and url and n <= 10 then
			local line = {{text = label, url = url}}
			table.insert(reply_markup.inline_keyboard, line)
		end
		n = n + 1
	end
	if not next(reply_markup.inline_keyboard) then reply_markup = nil end

	return reply_markup, clean_text
end

function utilities.get_media_type(msg)
	if msg.photo then
		return 'photo'
	elseif msg.video then
		return 'video'
	elseif msg.video_note then
		return 'video_note'
	elseif msg.audio then
		return 'audio'
	elseif msg.voice then
		return 'voice'
	elseif msg.document then
		if msg.document.mime_type == 'video/mp4' then
			return 'gif'
		else
			return 'document'
		end
	elseif msg.sticker then
		return 'sticker'
	elseif msg.contact then
		return 'contact'
	elseif msg.location then
		return 'location'
	elseif msg.game then
		return 'game'
	elseif msg.venue then
		return 'venue'
	else
		return false
	end
end

function utilities.get_media_id(msg)
	if msg.photo then
		return msg.photo[#msg.photo].file_id, 'photo'
	elseif msg.document then
		return msg.document.file_id
	elseif msg.video then
		return msg.video.file_id, 'video'
	elseif msg.audio then
		return msg.audio.file_id
	elseif msg.voice then
		return msg.voice.file_id, 'voice'
	elseif msg.sticker then
		return msg.sticker.file_id
	else
		return false, 'The message has not a media file_id'
	end
end

function utilities.migrate_chat_info(old, new, on_request)
	if not old or not new then
		return false
	end

	for hash_name, hash_content in pairs(config.chat_settings) do
		local old_t = db:hgetall('chat:'..old..':'..hash_name)
		if next(old_t) then
			for key, val in pairs(old_t) do
				db:hset('chat:'..new..':'..hash_name, key, val)
			end
		end
	end

	for _, hash_name in pairs(config.chat_hashes) do
		local old_t = db:hgetall('chat:'..old..':'..hash_name)
		if next(old_t) then
			for key, val in pairs(old_t) do
				db:hset('chat:'..new..':'..hash_name, key, val)
			end
		end
	end

	for i=1, #config.chat_sets do
		local old_t = db:smembers('chat:'..old..':'..config.chat_sets[i])
		if next(old_t) then
			db:sadd('chat:'..new..':'..config.chat_sets[i], table.unpack(old_t))
		end
	end

	if on_request then
		api.sendReply(msg, 'Should be done')
	end
end

-- Perform substitution of placeholders in the text according given the message.
-- The second argument can be the flag to avoid the escape, if it's set, the
-- markdown escape isn't performed. In any case the following arguments are
-- considered as the sequence of strings - names of placeholders. If
-- placeholders to replacing are specified, this function processes only them,
-- otherwise it processes all available placeholders.
function string:replaceholders(msg, ...)
	if msg.new_chat_member then
		msg.from = msg.new_chat_member
	end

	msg.chat.title = msg.chat.title and msg.chat.title or '-'

	local tail_arguments = {...}
	-- check that the second argument is a boolean and true
	local non_escapable = tail_arguments[1] == true

	local replace_map
	if non_escapable then
		replace_map = {
			name = ('[%s](tg://user?id=%s)'):format(msg.from.first_name, msg.from.id),
			surname = msg.from.last_name and msg.from.last_name or '',
			username = msg.from.username and '@'..msg.from.username or '-',
			id = msg.from.id,
			title = msg.chat.title,
			rules = utilities.deeplink_constructor(msg.chat.id, 'rules'),
			force = db:hget('chat:'..msg.chat.id..':force', 'forceNumber') or 0
		}
		-- remove flag about escaping
		table.remove(tail_arguments, 1)
	else
		replace_map = {
			name = ('[%s](tg://user?id=%s)'):format(msg.from.first_name:escape(), msg.from.id),
			surname = msg.from.last_name and msg.from.last_name:escape() or '',
			username = msg.from.username and '@'..msg.from.username:escape() or '-',
			id = msg.from.id,
			title = msg.chat.title:escape(),
			rules = utilities.deeplink_constructor(msg.chat.id, 'rules'),
			force = db:hget('chat:'..msg.chat.id..':force', 'forceNumber') or 0
		}
	end

	local substitutions = next(tail_arguments) and {} or replace_map
	for _, placeholder in pairs(tail_arguments) do
		substitutions[placeholder] = replace_map[placeholder]
	end

	return self:gsub('$(%w+)', substitutions)
end

function utilities.to_supergroup(msg)
	local old = msg.chat.id
	local new = msg.migrate_to_chat_id
	local done = utilities.migrate_chat_info(old, new, false)
	if done then
		utilities.remGroup(old)
		api.sendMessage(new, ':|', true)
	end
end

-- Return user mention for output a text
function utilities.getname_final(user)
	--return utilities.getname_link(user.first_name, user.username) or '<code>'..user.first_name:escape_html()..'</code>'
	return string.format('<a href="tg://user?id=%s">%s</a>', user.id, user.first_name:escape_html())
end

-- Return link to user profile or false, if he doesn't have login
function utilities.getname_link(name, username)
	if not name or not username then return nil end
	username = username:gsub('@', '')
	return ('<a href="%s">%s</a>'):format('https://telegram.me/'..username, name:escape_html())
end

function utilities.bash(str)
	local cmd = io.popen(str)
	local result = cmd:read('*all')
	cmd:close()
	return result
end

function utilities.telegram_file_link(res)
	--res = table returned by getFile()
	return "https://api.telegram.org/file/bot"..config.telegram.token.."/"..res.result.file_path
end

function utilities.getRules(chat_id)
	local hash = 'chat:'..chat_id..':info'
	local rules = db:hget(hash, 'rules')
	if not rules then
		return ("قوانینی موجود نمی باشد.")
	else
		return rules
	end
end

function utilities.getAdminlist(chat_id)
	local list, code = api.getChatAdministrators(chat_id)
	if not list then
		return false, code
	end
	local creator = ''
	local adminlist = ''
	local count = 1
	for i,admin in pairs(list.result) do
		local name
		local s = ' ├ '
		if admin.status == 'administrator' or admin.status == 'moderator' then
			name = admin.user.first_name
			if admin.user.username then
				name = ('<a href="telegram.me/%s">%s</a>'):format(admin.user.username, name:escape_html())
			else
				name = name:escape_html()
			end
			if count + 1 == #list.result then s = ' └ ' end
			adminlist = adminlist..s..name..'\n'
			count = count + 1
		elseif admin.status == 'creator' then
			creator = admin.user.first_name
			if admin.user.username then
				creator = ('<a href="telegram.me/%s">%s</a>'):format(admin.user.username, creator:escape_html())
			else
				creator = creator:escape_html()
			end
		end
	end
	if adminlist == '' then adminlist = '-' end
	if creator == '' then creator = '-' end

	return ("<b>👤 Creator</b>\n└ %s\n\n<b>👥 Admins</b> (%d)\n%s"):format(creator, #list.result - 1, adminlist)
end

local function sort_funct(a, b)
	return a:gsub('#', '') < b:gsub('#', '')
end

function utilities.getExtraList(chat_id)
	local hash = 'chat:'..chat_id..':extra'
	local commands = db:hkeys(hash)
	local text = 'لیست دستورات ذخیره شده:\n\n'
	if not next(commands) then
		return 'هیچ دستوری ذخیره نشده است!'
	else
		for i = 1, #commands do
			text = text..'• '..commands[i]..'\n'
		end
		return text
	end
end

function utilities.sendStartMe(msg)
	local keyboard = {inline_keyboard = {{{text = ("START"), url = 'https://telegram.me/'..bot.username}}}}
	api.sendMessage(msg.chat.id, ("لطفا اول ربات را استارت کنید :)"), true, keyboard)
end

function utilities.initGroup(chat_id)
	for set, setting in pairs(config.chat_settings) do
		local hash = 'chat:'..chat_id..':'..set
		for field, value in pairs(setting) do
			db:hset(hash, field, value)
		end
	end
	-- save adminlist
	utilities.cache_adminlist(chat_id, api.getChatAdministrators(chat_id))
	-- set id of group in database
	db:sadd('legendary:groups', chat_id)
end

function utilities.remGroup(chat_id)
	db:srem('legendary:groups', chat_id)

	local admins = db:smembers('cache:chat:'..chat_id..':admins')
	for i = 1, #admins do
		db:del('cache:chat:'..chat_id..':'..admins[i]..':permissions')
	end

	db:del('cache:chat:'..chat_id..':owner')
	db:del('cache:chat:'..chat_id..':admins')

	for set, field in pairs(config.chat_settings) do
		db:del('chat:'..chat_id..':'..set)
	end

	local users = db:smembers('chat:'..chat_id..':members')
	for i = 1, #users do
		db:del('user:nickname:'..users[i])
		db:del('user:nickname:archived:'..users[i])
		db:del('user:username:'..users[i])
        db:del('user:username:archived:'..users[i])
		db:del('chat:'..chat_id..':forceUser:'..users[i])
	end

	db:del('cache:chat:'..chat_id..':admins') --delete the cache
	db:hdel('bot:logchats', chat_id) --delete the associated log chat
	db:del('chat:'..chat_id..':userlast')
	db:del('chat:'..chat_id..':usermsgs')
	db:del('chat:'..chat_id..':members')
	db:hdel('bot:chats:latsmsg', chat_id)
	db:hdel('bot:chatlogs', chat_id) --log channel

	db:del('chat:'..chat_id..':lock_media')
	db:del('chat:'..chat_id..':lock_group')
	db:del('chat:'..chat_id..':lock_time')
	db:get('chat:'..chat_id..':autolock_true')
	db:hdel('autolock_time', chat_id)
	db:del('chat:'..chat_id..':lock_handly')

	db:del('chat:'..chat_id..':extra')
	db:del('chat:'..chat_id..':info')
	db:del('chat:'..chat_id..':whitelist')
	
	db:del('chat:'..chat_id..':filter')
	db:del('chat:'..chat_id..':filter_list')

	db:del('chat:'..chat_id..':silent')
	
	db:del('chat:'..chat_id..':warns')

	db:del('chat:'..chat_id..':porno')

	db:del('chat:'..chat_id..':force')
	db:del('chat:'..chat_id..':forceUsers')

end

function utilities.getnames_complete(msg, blocks)
	local admin, kicked

	admin = utilities.getname_link(msg.from.first_name, msg.from.username) or ("<code>%s</code>"):format(msg.from.first_name:escape_html())

	if msg.reply then
		kicked = utilities.getname_link(msg.reply.from.first_name, msg.reply.from.username) or ("<code>%s</code>"):format(msg.reply.from.first_name:escape_html())
	elseif msg.text:match(config.cmd..'%w%w%w%w?%w?%s(@[%w_]+)%s?') then
		local username = msg.text:match('%s(@[%w_]+)')
		kicked = username
	elseif msg.mention_id then
		for _, entity in pairs(msg.entities) do
			if entity.user then
				kicked = '<code>'..entity.user.first_name:escape_html()..'</code>'
			end
		end
	elseif msg.text:match(config.cmd..'%w%w%w%w?%w?%s(%d+)') then
		local id = msg.text:match(config.cmd..'%w%w%w%w?%w?%s(%d+)')
		kicked = '<code>'..id..'</code>'
	end

	return admin, kicked
end

function utilities.get_user_id(msg, blocks)
	--if no user id: returns false and the msg id of the translation for the problem
	if not msg.reply and not blocks[2] then
		return false, ("لطفا اول روی یک کاربر ریپلای کنید یا از نام کاربر، منشن، یا شناسه آیدی آن استفاده کنید.")
	else
		if msg.reply then
			if msg.reply.new_chat_member then
				msg.reply.from = msg.reply.new_chat_member
			end
			return msg.reply.from.id
		elseif msg.text:match('%w%w%w%w?%w?%w?%w?%s(@[%w_]+)%s?') then
			local username = msg.text:match('%s(@[%w_]+)')
			local id, error = utilities.resolve_user(username)
			if not id then
				return false, error
			else
				return id
			end
		elseif msg.mention_id then
			return msg.mention_id
		elseif msg.text:match('%w%w%w%w?%w?%w?%w?%s(%d+)') then
			local id = msg.text:match('%w%w%w?%w%w?%w?%w?%s(%d+)')
			return id
		else
			return false, ("لطفا از نام کاربری، شناسه عددی یا منشن اون کاربر استفاده کنید!\nدر غیر این صورت، من نمی توانم کمکی به شما کنم!")
		end
	end
end

function utilities.get_user_id_2(msg, blocks)
	if not msg.reply or not blocks[2] then
		return false, 'لطفا روی یک کاربر ریپلای کنید یا از یوزرنیم او استفاده کنید.'
	else
		if msg.reply then
			if msg.reply.new_chat_member then
				msg.reply.from = msg.reply.new_chat_member
			end
			return msg.reply.from.id
		elseif blocks[2] then
			if blocks[2]:match('@[%w_]+$') then --by username
				local user_id, error = utilities.resolve_user(blocks[2])
				if not user_id then
					print('username (not found)')
					return false, error
				else
					print('username (found)')
					return user_id
				end
			elseif blocks[2]:match('^%d+$') then --by id
				print('id')
				return blocks[2]
			elseif msg.mention_id then --by text mention
				print('text mention')
				return msg.mention_id
			else
				return false, 'شما فقط مجاز هستید از یوزرنیم، آیدی عددی یا منشن استفاده کنید.'
			end
		end
	end
end

function utilities.logEvent(event, msg, extra)
	local log_id = db:hget('bot:chatlogs', msg.chat.id)
	--print(clr.green.."")
	--utilities.dump(extra)
	--print(clr.cyan.."")
	--utilities.dump(msg)
	--print(clr.magenta.."")
	--utilities.dump(event)
	--print(clr.reset.."")

	if not log_id then return end
	local is_loggable = db:hget('chat:'..msg.chat.id..':tolog', event)
	if not is_loggable or is_loggable == 'no' then return end

	local text, reply_markup

	local chat_info = ("<b>مشخصات گروه</b>:\n• نام گروه: %s\n• شناسه گروه: [#chat%d]\n"):format(msg.chat.title:escape_html(), msg.chat.id * -1)

	local member = ("\n• نام: %s\n• نام کاربری: [@%s]\n• شناسه کاربری: [#id%d]\n"):format(msg.from.first_name:escape_html(), msg.from.username or '-', msg.from.id)

	if event == 'flood' then
		text = ('#حساسیت_پیام\n%s\n<b>مشخصات کاربر</b>: %s'):format(chat_info, member)
		if extra.hammered then
			local hammer_to_text
			if extra.hammered == 'mute' then
				hammer_to_text = 'کاربر سایلنت شد.'
				reply_markup = {inline_keyboard={{{text = ("حذف از لیست سایلنت"), callback_data = ("logcb:unsilent:%d:%d"):format(extra.user_id, msg.chat.id)}}}}
			elseif extra.hammered == 'kick' then
				hammer_to_text = 'کاربر اخراج شد.'
			elseif extra.hammered == 'ban' then
				hammer_to_text = 'کاربر مسدود شد.'
				reply_markup = {inline_keyboard={{{text = ("حذف از لیست مسدود ها"), callback_data = ("logcb:unban:%d:%d"):format(extra.user_id, msg.chat.id)}}}}
			end
			text = text..('\nواکنش ربات: %s'):format(hammer_to_text)
		end
	elseif event == 'silent' then
		local get_time
		if extra.time ~= nil then
			get_time = extra.time
		else
			get_time = 'برای همیشه'
		end
		text = ('#سایلنت\n%s\n<b>توسط ادمین</b>:\n• نام: %s \n• شناسه کاربری: [#id%d]\n\n<b>مشخصات کاربر</b>:\n• نام: %s\n• شناسه کاربری: [#id%d]\n\nمدت زمان سایلنت: <b>%s</b>')
		:format(chat_info, extra.admin, msg.from.id, extra.user, extra.user_id, get_time)
	elseif event == 'unsilent' then
		text = ('#آن_سایلنت\n%s\n<b>توسط ادمین</b>:\n• نام: %s \n• شناسه کاربری: [#id%d]\n\n<b>مشخصات کاربر</b>:\n• نام: %s\n• شناسه کاربری: [#id%d]')
		:format(chat_info, extra.admin, msg.from.id, extra.user, extra.user_id)
	elseif event == 'new_chat_photo' then
		text = ('#عکس_جدید_گروه\n%s\n<b>توسط</b>: %s'):format(chat_info, member)
		reply_markup = {inline_keyboard={{{text = ("مشاهده عکس"), url = ("telegram.me/%s?start=photo_%s"):format(bot.username, extra.file_id)}}}}
	elseif event == 'delete_chat_photo' then
		text = ('#حذف_عکس_گروه\n%s\n<b>توسط</b>: %s'):format(chat_info, member)
	elseif event == 'new_chat_title' then
		text = ('#نام_جدید_گروه\n%s\n<b>توسط</b>: %s'):format(chat_info, member)
	elseif event == 'pinned_message' then
		text = ('#پیام_سنجاق_شده\n%s\n<b>توسط</b>: %s'):format(chat_info, member)
	elseif event == 'report' then
		text = ('#گزارش\n%s\n<b>توسط</b>: %s\n<i>گزارش به دست %d ادمین رسید.</i>'):format(chat_info, member, extra.n_admins)
	elseif event == 'new_chat_member' then
		local member = ("\n• نام: %s\n• نام کاربری: [@%s]\n• شناسه کاربری: [#id%d]\n")
		:format(msg.new_chat_member.first_name:escape_html(), msg.new_chat_member.username or '-', msg.new_chat_member.id)
		text = ('#عضو_جدید\n%s\n<b>مشخصات</b>: %s'):format(chat_info, member)
		if extra then
			text = text..("\n<b>اضافه شده توسط</b>: %s [#id%d]"):format(utilities.getname_final(extra), extra.id)
		end
	else
		if event == 'warn' then
			text = ('#اخطار\n<b>توسط ادمین</b>:\n• نام: %s \n• شناسه کاربری: [#id%d]\n%s\n<b>مشخصات کاربر</b>:\n• نام: %s\n• شناسه کاربری: [#id%d]\n<b>تعداد اخطارها</b>: <code>%d/%d</code>')
			:format(extra.admin, msg.from.id, chat_info, extra.user, extra.user_id, extra.warns, extra.warnmax)
			if extra.hammered then
				text = text..('\n<b>واکنش ربات</b>: %s'):format(extra.hammered)
			end
		elseif event == 'nowarn' then
			text = ('#حذف_اخطار\n<b>توسط ادمین</b>:\n• نام: %s \n• شناسه کاربری: [#id%d]\n\n%s\n<b>مشخصات کاربر</b>:\n• نام: %s\n• شناسه کاربری: [#id%d]')
				:format(extra.admin, msg.from.id, chat_info, extra.user, tostring(extra.user_id))
		elseif event == 'tempban' then
			text = ('#حذف_موقت\n<b>توسط ادمین</b>:\n• نام: %s \n• شناسه کاربری: [#id%d]\n\n%s\n<b>مشخصات کاربر</b>:\n• نام: %s\n• شناسه کاربری: [#id%d]\n<b>مدت زمان</b>: %d روز, %d ساعت')
			:format(extra.admin, msg.from.id, chat_info, extra.user, tostring(extra.user_id), extra.d, extra.h)
		else --ban or kick or unban
			local event_text
			if event == 'ban' then
				event_text = 'مسدود'
			elseif event == 'kick' then
				event_text = 'اخراج'
			else
				event_text = 'حذف_از_لیست_مسدود'
			end
			text = ('#%s\n<b>مشخصات ادمین</b>:\n• نام: %s\n• شناسه کاربری: [#id%s]\n\n%s\n<b>مشخصات کاربر</b>:\n• نام: %s\n• شناسه کاربری: [#id%s]'):format(event_text, extra.admin, msg.from.id, chat_info, extra.user, tostring(extra.user_id))
		end
		if event == 'ban' or event == 'tempban' then
			--logcb:unban:user_id:chat_id for ban, logcb:untempban:user_id:chat_id for tempban
			reply_markup = {inline_keyboard={{{text = ("حذف از لیست مسدود ها"), callback_data = ("logcb:un%s:%d:%d"):format(event, extra.user_id, msg.chat.id)}}}}
		end
		if extra.motivation then
			text = text..('\n<b>دلیل</b>: %s'):format(extra.motivation:escape_html())
		end
	end

	if text then
		local res, code = api.sendMessage(log_id, text, 'html', reply_markup)
		if not res and code == 117 then
			db:hdel('bot:chatlogs', msg.chat.id)
		end
	end
end

function utilities.is_info_message_key(key)
	if key == 'Extra' or key == 'Rules' then
		return true
	else
		return false
	end
end

function utilities.table2keyboard(t)
	local keyboard = {inline_keyboard = {}}
	for i, line in pairs(t) do
		if type(line) ~= 'table' then return false, 'Wrong structure (each line need to be a table, not a single value)' end
		local new_line ={}
		for k,v in pairs(line) do
			if type(k) ~= 'string' then return false, 'Wrong structure (table of arrays)' end
			local button = {}
			button.text = k
			button.callback_data = v
			table.insert(new_line, button)
		end
		table.insert(keyboard.inline_keyboard, new_line)
	end

	return keyboard
end

return utilities
