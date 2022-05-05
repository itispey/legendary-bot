local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function is_ignored(chat_id, msg_type)
	local hash = 'chat:'..chat_id..':floodexceptions'
	local status = (db:hget(hash, msg_type)) or 'no'
	if status == 'yes' then
		return true
	elseif status == 'no' then
		return false
	end
end

local function is_flooding_funct(msg)
	if msg.media_group_id then
		-- albums should count as one message

		local media_group_id_key = 'mediagroupidkey:'..msg.chat.id
		if msg.media_group_id == db:get(media_group_id_key) then -- msg.media_group_id is a str
			-- photo/video is from an already processed sent album
			return false
		else
			-- save the ID of the albums as last processed album,
			-- so we can ignore all the following updates containing medias from that album
			db:setex(media_group_id_key, 600, msg.media_group_id)
		end
	end

	local spamkey = 'spam:'..msg.chat.id..':'..msg.from.id

	local msgs = tonumber(db:get(spamkey)) or 1

	local max_msgs = tonumber(db:hget('chat:'..msg.chat.id..':flood', 'MaxFlood')) or 5
	if msg.cb then max_msgs = 15 end

	local max_time = 5
	db:setex(spamkey, max_time, msgs+1)

	if msgs > max_msgs then
		return true, msgs, max_msgs
	else
		return false
	end
end

local function is_whitelisted(chat_id, text)
	local set = ('chat:%d:whitelist'):format(chat_id)
	local links = db:smembers(set)
	if links and next(links) then
		for i=1, #links do
			if text:match(links[i]:gsub('%-', '%%-')) then
				--print('Whitelist:', links[i])
				return true
			end
		end
	end
end

local function adIsLock(chat_id, value)
	local public = db:hget('chat:'..chat_id..':ads', value)
	if public and public == 'on' then
	  return true
	end
  end

function plugin.onEveryMessage(msg)

	if not msg.inline then

		local msg_type = 'text'
		if msg.forward_from or msg.forward_from_chat then msg_type = 'forward' end
		if msg.media_type then msg_type = msg.media_type end
		if not is_ignored(msg.chat.id, msg_type) and not msg.edited and not msg.new_chat_members then
			if (not msg.new_chat_member and not msg.new_chat_members) then
				local is_flooding, msgs_sent, msgs_max = is_flooding_funct(msg)
				if is_flooding then
					local status = (db:hget('chat:'..msg.chat.id..':settings', 'Flood')) or config.chat_settings['settings']['Flood']
					if status == 'on' and not msg.cb and not msg.from.admin then --if the status is on, and the user is not an admin, and the message is not a callback, then:
						local action = db:hget('chat:'..msg.chat.id..':flood', 'ActionFlood')
						local name = u.getname_final(msg.from)
						local res, message
						--try to kick or ban
						if action == 'ban' then
							res = api.banUser(msg.chat.id, msg.from.id)
						elseif action == 'kick' then
							res = api.kickUser(msg.chat.id, msg.from.id)
						elseif action == 'mute' then
							res = api.muteUser(msg.chat.id, msg.from.id)
						end
						--if kicked/banned, send a message
						if res then
							local log_hammered = action
							if msgs_sent == (msgs_max + 1) then --send the message only if it's the message after the first message flood. Repeat after 5
								if action == 'ban' then
									message = ("کاربر %s به دلیل ارسال پیام رگباری، مسدود شد.\nتعداد پیام رگباری ارسال شده: <b>(%d/%d)</b>"):format(name, msgs_sent, msgs_max)
								elseif action == 'kick' then
									message = ("کاربر %s به دلیل ارسال پیام رگباری، اخراج شد.\nتعداد پیام رگباری ارسال شده: <b>(%d/%d)</b>"):format(name, msgs_sent, msgs_max)
								elseif action == 'mute' then
									message = ("کاربر %s به دلیل ارسال پیام رگباری، سایلنت شد.\nتعداد پیام رگباری ارسال شده: <b>(%d/%d)</b>"):format(name, msgs_sent, msgs_max)
								end
								api.sendMessage(msg.chat.id, message, 'html')
								u.logEvent('flood', msg, {hammered = log_hammered, user_id = msg.from.id})
							end
						end
					end
					----------------------------------------------------------------------
					local chat_id = msg.chat.id
				  	local user_id = msg.from.id
					local message_id = msg.message_id
					local time = clr.yellow..'['..os.date('%X')..'] '..clr.reset
					
					if msg.service then
						if adIsLock(chat_id, 'tgservice') then
							api.deleteMessage(chat_id, message_id)
							print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [TGService]"..clr.green.." Successfully"..clr.reset)
							return
						end
					end

					if not msg.from.admin and not u.is_free_user(chat_id, msg.from.id) then -- if user was not admin
			      		
						if msg.media then -- if user send media
							local media = msg.media_type
							local hash = 'chat:'..chat_id..':media'
							local status = db:hget(hash, media)
							if status == 'on' then
								api.deleteMessage(chat_id, message_id)
								print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." ["..media.."]"..clr.green.." Successfully"..clr.reset)
								return
							end
						end
						------------------------------------
						if adIsLock(chat_id, 'username') then
							if msg.entities then
								for i = 1, #msg.entities do
									if msg.entities[i].type == 'mention' and msg.text:match('@') then
										api.deleteMessage(chat_id, message_id)
										print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [Username]"..clr.green.." Successfully"..clr.reset)
										return
									end
								end
							end
						end
						------------------------------------
						if adIsLock(chat_id, 'hashtag') then
							if msg.entities then
								for i = 1, #msg.entities do
									if msg.entities[i].type == 'hashtag' and msg.text:match('#') then
										api.deleteMessage(chat_id, message_id)
										print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [Hashtag]"..clr.green.." Successfully"..clr.reset)
										return
									end
								end
							end
						end
						------------------------------------
						if adIsLock(chat_id, 'fwdchannel') then
							if msg.forward_from_chat then
								if msg.forward_from_chat.type == 'channel' then
									api.deleteMessage(chat_id, message_id)
									print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [FWD Channel]"..clr.green.." Successfully"..clr.reset)
									return
								end
							end
						end
						------------------------------------
						if adIsLock(chat_id, 'webpage') then
							if not is_whitelisted(chat_id, msg.text) then
								if msg.media_type == 'link' then
									api.deleteMessage(chat_id, message_id)
									print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [Webpage]"..clr.green.." Successfully"..clr.reset)
									return
								end
							end
						end
						------------------------------------
						local autolock_time = db:get('chat:'..chat_id..':lock_time')
						if autolock_time then
							api.deleteMessage(chat_id, message_id)
							api.muteUser(chat_id, user_id, (os.time() + db:ttl('chat:'..chat_id..':lock_time')))
							print(time..clr.red..'User muted because he/she spamed when group was lock.'..clr.reset)
							return
						end
						------------------------------------
						local handly_time = db:get('chat:'..chat_id..':lock_handly')
						if handly_time then
							api.deleteMessage(chat_id, message_id)
							api.muteUser(chat_id, user_id, (os.time() + db:ttl('chat:'..chat_id..':lock_handly')))
							print(time..clr.red..'User muted because he/she spamed when group was lock.'..clr.reset)
							return
						end
						------------------------------------
						if adIsLock(chat_id, 'link') then
							if msg.spam == 'links' then
								if not is_whitelisted(chat_id, msg.text) then
									api.deleteMessage(chat_id, message_id)
									print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [Link]"..clr.green.." Successfully"..clr.reset)
									return
								end
							end
						end
						------------------------------------
						if adIsLock(chat_id, 'fwduser') then
							if msg.forward_from then
								api.deleteMessage(chat_id, message_id)
								print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [FWD User]"..clr.green.." Successfully"..clr.reset)
								return
							end
						end
						------------------------------------
						if adIsLock(chat_id, 'persian') then
							if msg.text:match('[\216-\219][\128-\191]') then
								api.deleteMessage(chat_id, message_id)
								print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [Persian]"..clr.green.." Successfully"..clr.reset)
								return
							end
						end
						------------------------------------
						if adIsLock(chat_id, 'english') then
							if msg.text:match('[A-Z]') or msg.text:match('[a-z]') then
								api.deleteMessage(chat_id, message_id)
								print(time.."Deleted "..clr.red.."SPAM"..clr.blue.." [English]"..clr.green.." Successfully"..clr.reset)
								return
							end
						end
						------------------------------------
					end

					if msg.cb then
						api.answerCallbackQuery(msg.cb_id, ("‼️ لطفا با سرعت کمتری روی دکمه ها بزنید !"))
					end
					
					return false
				end
			end
		end
		------------------------------------
		if u.is_blocked_global(msg.from.id) then
			return false
		end
		------------------------------------
	end
	return true
end

return plugin
