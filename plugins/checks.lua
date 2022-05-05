local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function adIsLock(chat_id, value)
  local public = db:hget('chat:'..chat_id..':ads', value)
  if public and public == 'on' then
    return true
  end
end

local function is_whitelisted(chat_id, text)
	local set = ('chat:%d:whitelist'):format(chat_id)
	local links = db:smembers(set)
	if links and next(links) then
		for i=1, #links do
			if text:match(links[i]:gsub('%-', '%%-')) then
				return true
			end
		end
	end
end

function plugin.onEveryMessage(msg)
  local chat_id = msg.chat.id
  local user_id = msg.from.id
  local message_id = msg.message_id
  local time = clr.cyan..'['..os.date('%X')..'] '..clr.reset
  if chat_id < 0 then
    local status = db:hget('chat:'..chat_id..':settings', 'Change') or 'off'
    if status == "on" then
      if u.is_vip_group(chat_id) then
        local text
        local lastname = db:get('user:nickname:'..user_id) or false
        local lastusername = db:get('user:username:'..user_id) or false
        if lastname and lastname:lower() ~= msg.from.first_name:lower() then
          text = ("💢 کاربر %s نام خود را تغییر داد!\n• نام جدید: %s"):format(lastname, u.getname_final(msg.from))
          api.sendMessage(chat_id, text, 'html')
        end
        local username = msg.from.username or "-"
        if lastusername and lastusername:lower() ~= username:lower() then
          text = ("💢 کاربر @%s نام کاربری خود را تغییر داد!\n• نام کاربری جدید: @%s"):format(lastusername, username)
          api.sendMessage(chat_id, text, 'html')
        end
        db:set('user:nickname:'..user_id, msg.from.first_name)
        db:sadd('user:nickname:archived:'..user_id, msg.from.first_name)
        if msg.from.username then
          db:set('user:username:'..user_id, msg.from.username)
          db:sadd('user:username:archived:'..user_id, msg.from.username)
        end
      end
    end

    if not msg.from.admin and not u.is_free_user(chat_id, user_id) then -- if user was not admin
      if msg.media then -- if user send media
        local media = msg.media_type
        local hash = 'chat:'..chat_id..':media'
        local status = db:hget(hash, media)
        if status == 'on' then
          api.deleteMessage(chat_id, message_id)
          print(time.."Deleted "..clr.red.."["..media.."]"..clr.green.." Successfully"..clr.reset)
          return
        end
      end
      ------------------------------------ [Force ADD] ------------------------------------
      local status = db:hget('chat:'..chat_id..':force', 'status') or 'off'
      local num = db:hget('chat:'..chat_id..':force', 'forceNumber') or 0
      local added = db:scard("chat:"..chat_id..":forceUser:"..user_id) or 0
      if status ~= 'off' then
        if u.is_vip_group(chat_id) then
          if db:hget('chat:'..chat_id..':forceUsers', user_id) then -- if user is mute
            if tonumber(added) >= tonumber(num) then
              db:hdel('chat:'..chat_id..':forceUsers', user_id)
              print("User is free as a bird :)")
              return
            end
            api.deleteMessage(chat_id, message_id)
            print(time.."User should add ["..clr.red..(tonumber(num) - tonumber(added))..clr.reset.."] users")
            return
          end
        end
      end
      ------------------------------------
      if adIsLock(chat_id, 'username') then
        if msg.entities then
          for i = 1, #msg.entities do
            if msg.entities[i].type == 'mention' and msg.text:match('@') then
              api.deleteMessage(chat_id, message_id)
              print(time.."Deleted "..clr.red.."[Username]"..clr.green.." Successfully"..clr.reset)
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
              print(time.."Deleted "..clr.red.."[Hashtag]"..clr.green.." Successfully"..clr.reset)
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
            print(time.."Deleted "..clr.red.."[FWD Channel]"..clr.green.." Successfully"..clr.reset)
            return
          end
        end
      end
      ------------------------------------
      if adIsLock(chat_id, 'webpage') then
        if not is_whitelisted(chat_id, msg.text) then
          if msg.media_type == 'link' then
            api.deleteMessage(chat_id, message_id)
            print(time.."Deleted "..clr.red.."[Webpage]"..clr.green.." Successfully"..clr.reset)
            return
          end
        end
      end
      ------------------------------------
      if adIsLock(chat_id, 'link') then
        if msg.spam == 'links' then
          if not is_whitelisted(chat_id, msg.text) then
            api.deleteMessage(chat_id, message_id)
            print(time.."Deleted "..clr.red.."[Link]"..clr.green.." Successfully"..clr.reset)
            return
          end
        end
      end
      ------------------------------------
      if adIsLock(chat_id, 'fwduser') then
        if msg.forward_from then
          api.deleteMessage(chat_id, message_id)
          print(time.."Deleted "..clr.red.."[FWD User]"..clr.green.." Successfully"..clr.reset)
          return
        end
      end
      ------------------------------------
      if adIsLock(chat_id, 'persian') then
        if msg.text:match('[\216-\219][\128-\191]') then
          api.deleteMessage(chat_id, message_id)
          print(time.."Deleted "..clr.red.."[Persian]"..clr.green.." Successfully"..clr.reset)
          return hash_key
        end
      end
      ------------------------------------
      if adIsLock(chat_id, 'english') then
        if msg.text:match('[A-Z]') or msg.text:match('[a-z]') then
          api.deleteMessage(chat_id, message_id)
          print(time.."Deleted "..clr.red.."[English]"..clr.green.." Successfully"..clr.reset)
          return
        end
      end
      ------------------------------------
      if db:get('chat:'..chat_id..':lock_time') then
        api.deleteMessage(chat_id, message_id)
        print(time..'Deleted '..clr.yellow.."[EVERYTHING (Auto lock)]"..clr.green.." Successfully"..clr.reset)
        return
      end
      ------------------------------------
      if db:get('chat:'..chat_id..':lock_handly') then
        api.deleteMessage(chat_id, message_id)
        print(time..'Deleted '..clr.yellow.."[EVERYTHING (Handly lock)]"..clr.green.." Successfully"..clr.reset)
        return
      end
    end
  end
  return true
end

return plugin
