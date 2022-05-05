local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function is_locked(chat_id)
  local hash = 'chat:'..chat_id..':settings'
  local current = db:hget(hash, 'Extra')
	if current == 'off' then
  	return true
  else
  	return false
  end
end

function plugin.onTextMessage(msg, blocks)

  if msg.chat.type == 'private' and not(blocks[1] == 'start') then return end

	if blocks[1]:lower() == 'addword' or blocks[1] == 'دستور' then
    if not msg.from.admin then return end
    if not blocks[2] then return end
    if not blocks[3] and not msg.reply then return end
    if string.len(blocks[2]) < 2 then return end

    if msg.reply and not blocks[3] then
      local file_id, media_with_special_method = u.get_media_id(msg.reply)
	   	if not file_id then
	   		return
	   	else
	   		local to_save
	    	if media_with_special_method then --photo, voices, video need their method to be sent by file_id
	    		to_save = '###file_id!'..media_with_special_method..'###:'..file_id
	    	else
	    		to_save = '###file_id###:'..file_id
	    	end
	   		db:hset('chat:'..msg.chat.id..':extra', blocks[2], to_save)
	    	api.sendReply(msg, ("رسانه مورد نظر برای دستور %s در نظر گرفته شد."):format(blocks[2]))
	    end
    else
	   	local hash = 'chat:'..msg.chat.id..':extra'
	   	local new_extra = blocks[3]
	   	local reply_markup, test_text = u.reply_markup_from_text(new_extra)
	   	test_text = test_text:gsub('\n', '')

	   	local res, code = api.sendReply(msg, test_text:replaceholders(msg), true, reply_markup)
	   	if not res then
	   		api.sendMessage(msg.chat.id, u.get_sm_error_string(code), true)
    	else
	    	db:hset(hash, blocks[2]:lower(), new_extra)
	   		local msg_id = res.result.message_id
				api.editMessageText(msg.chat.id, msg_id, ("دستور %s ذخیره شد."):format(blocks[2]))
    	end
    end
  elseif blocks[1]:lower() == 'wordslist' or blocks[1]:lower() == 'wordlist' or blocks[1] == 'لیست دستورات' then
    local text = u.getExtraList(msg.chat.id)
    if not msg.from.admin and not is_locked(msg.chat.id) then
      api.sendMessage(msg.from.id, text)
    else
      api.sendReply(msg, text)
    end
  elseif blocks[1]:lower() == 'delword' or blocks[1] == 'حذف دستور' then
    if not msg.from.admin then return end
    local hash = 'chat:'..msg.chat.id..':extra'
    if blocks[2]:match('^(#)$') then
      db:hdel(hash, '#')
      api.sendReply(msg, 'دستور "#" حذف شد.')
      return
    end
    local deleted, not_found, found = {}, {}, nil
    local text
	  for extra in blocks[2]:gmatch('(#[%S_]+)') do
      found = db:hdel(hash, extra)
      if found == 1 then
        deleted[#deleted + 1] = extra
      else
        not_found[#not_found + 1] = extra
      end
    end
    if next(deleted) then
      text = 'دستورات حذف شده: '
      for i = 1, #deleted do
        text = text..(' - `'..deleted[i]..'`')
      end
    else
      text = 'دستوری یافت نشد!'
    end
    if next(not_found) then
      text = text..('\nدستوراتی که یافت نشد: ')
      for i = 1, #not_found do
        text = text..(' - `'..not_found[i]..'`')
      end
    end
    api.sendReply(msg, text, true)
  else
    local chat_id = msg.chat.id
    local extra = blocks[1]
    local hash = 'chat:'..chat_id..':extra'
    local text = db:hget(hash, extra:lower()) or db:hget(hash, extra)

    if not text then return true end --continue to match plugins

    local file_id = text:match('^###.+###:(.*)')
    local special_method = text:match('^###file_id!(.*)###') --photo, voices, video need their method to be sent by file_id
    local link_preview = text:find('telegra%.ph/') ~= nil
    local res = true
    local code
    if msg.chat.id > 0 or (is_locked(msg.chat.id) and not msg.from.admin) then --send it in private
      if not file_id then
        local reply_markup, clean_text = u.reply_markup_from_text(text)
        res, code = api.sendMessage(msg.from.id, clean_text:replaceholders(msg.reply or msg), true, reply_markup, nil, link_preview)
      else
        if special_method then
          res, code = api.sendMediaId(msg.from.id, file_id, special_method) --photo, voices, video need their method to be sent by file_id
        else
          res, code = api.sendDocumentId(msg.from.id, file_id)
        end
      end
    else
      local msg_to_reply
      if msg.reply then
        msg_to_reply = msg.reply.message_id
      else
        msg_to_reply = msg.message_id
      end
      if file_id then
        if special_method then
          api.sendMediaId(msg.chat.id, file_id, special_method, msg_to_reply) --photo, voices, video need their method to be sent by file_id
        else
          api.sendDocumentId(msg.chat.id, file_id, msg_to_reply)
        end
      else
        local reply_markup, clean_text = u.reply_markup_from_text(text)
        api.sendMessage(msg.chat.id, clean_text:replaceholders(msg.reply or msg), true, reply_markup, msg_to_reply, link_preview) --if the mod replies to an user, the bot will reply to the user too
      end
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(addword)$',
		config.cmd..'(addword) (#[%w_]*) (.*)$',
		config.cmd..'(addword) (#[%w_]*)',
		config.cmd..'(delword) (.+)$',
		config.cmd..'(wordslist)$',
    config.cmd..'(wordlist)$',
    ----------------------------
    '^([Aa]ddword)$',
		'^([Aa]ddword) (#[%w_]*) (.*)$',
		'^([Aa]ddword) (#[%w_]*)',
		'^([Dd]elword) (.+)$',
		'^([Ww]ordslist)$',
    '^([Ww]ordlist)$',
    ----------------------------
    '^(دستور)$',
    '^(دستور) (#[%S_]*) (.*)$',
    '^(دستور) (#[%S_]*)$',
    '^(حذف دستور) (.+)$',
    '^(لیست دستورات)$',
    ----------------------------
		'^/(start) (-?%d+)([%w_]+)$',
    '^(#[%w_]*)$',
		'^(#[%S_]*)$'
	}
}

return plugin
