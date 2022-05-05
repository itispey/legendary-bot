local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function backKeyboard(chat_id)
  local keyboard = {inline_keyboard = {
    {{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}}
  }}
  return keyboard
end

function plugin.onTextMessage(msg, blocks)
  local chat_id = msg.chat.id
  local user_id = msg.from.id
  -------------------------------------- [Private CMD] --------------------------------------
  if msg.chat.type == 'private' then
    if user_id == config.cli or u.is_superadmin(user_id) then
      -------------------------- [Link and Join] --------------------------
      if blocks[1] == 'link_is_invalid' then
        local chat_id = blocks[2]
        local user_id = blocks[3]
        local msg_id = db:get('clean:save_msg_id:'..user_id)
        api.editMessageText(user_id, msg_id, '🚫 ربات به گروه اضافه نشد!\n'
        ..'احتمالا قبلا از گروه اخراج شده است یا مشکل از لینک می باشد. لطفا چند دقیقه دیگر مجدد امتحان کنید یا به پشتیبانی اطلاع دهید.', true, backKeyboard(chat_id))
        api.sendAdmin(('#%s\n<code>%s</code>\n<code>%s</code>'):format(blocks[1], chat_id, user_id), 'html')
        db:del('clean:save_msg_id:'..user_id)
      end
      if blocks[1] == 'join_successfully' then
        local chat_id = blocks[2]
        local user_id = blocks[3]
        local msg_id = db:get('clean:save_msg_id:'..user_id)
        local permissions = {
          can_change_info = true,
          can_delete_messages = true,
          can_invite_users = true,
          can_restrict_members = true,
          can_pin_messages = true
        }
        local res = api.promoteChatMember(chat_id, config.cli, permissions)
        if not res then
          local new_key = {inline_keyboard = {
            {{text = 'تلاش مجدد 🎈', callback_data = 'clean:addbot:'..chat_id}},
            {{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}}
          }}
          api.editMessageText(user_id, msg_id, '🚫 من دسترسی ادمین کردن ربات رو ندارم!\n'
          ..'لطفا دسترسی کامل به من بدید و سپس مجدد تلاش کنید.', true, new_key)
          api.sendMessage(config.cli, '#left\nchat_id='..chat_id)
        else
          local text = [[
✅ ربات پاکسازی به گروه اضافه و ادمین شد! شما از این پس می توانید از دستورات پاکسازی استفاده کنید.

• در صورتی که دستورات را نمی دانید، از /help کمک بگیرید.
          ]]
          api.editMessageText(user_id, msg_id, text, true, backKeyboard(chat_id))
          api.sendAdmin(('#%s\n<code>%s</code>\n<code>%s</code>'):format(blocks[1], chat_id, user_id), 'html')
        end
        db:del('clean:save_msg_id:'..user_id)
      end
      if blocks[1] == 'unknown_problem' then
        local chat_id = blocks[2]
        local user_id = blocks[3]
        local msg_id = db:get('clean:save_msg_id:'..user_id)
        api.editMessageText(user_id, msg_id, '🚫 مشکلی به وجود آمده است!!!\n'
        ..'لطفا با پشتیبانی ارتباط بر قرار کنید', true, backKeyboard(chat_id))
        db:del('clean:save_msg_id:'..user_id)
        api.sendAdmin(('#%s\n<code>%s</code>\n<code>%s</code>'):format(blocks[1], chat_id, user_id), 'html')
      end
      ----------------------------------------------------------------------
      if blocks[1] == 'message_cleaned' then
        local res = api.getChat(blocks[3])
        api.sendMessage(blocks[2], ('پیام های گروه توسط ادمین %s پاکسازی شدند.'):format(u.getname_final(res.result)), 'html')
      end
    end
  end
  -------------------------------------- [Group CMD] --------------------------------------
  if blocks[1]:lower() == 'clean' and msg.from.admin then
    if u.is_vip_group(chat_id) then
      if u.can(chat_id, user_id, 'can_delete_messages') then
        if not blocks[2] then
          local text = [[
لطفا برای پاکسازی بخش زیادی از پیام ها از دستور
• `/clean chat`
و برای حذف تعداد مشخصی پیام از دستور
• `/clean عدد`
استفاده کنید.
          ]]
          api.sendReply(msg, text, true)
          return
        end
        if blocks[2] == 'chat' then
          api.sendMessage(config.cli, ('#clean\nchat_id=%s&user_id=%s'):format(chat_id, user_id))
        elseif blocks[2]:match('(%d+)') then
          api.sendMessage(config.cli, ('#del\nchat_id=%s&user_id=%s&value=%s'):format(chat_id, user_id, blocks[2]))
        end
      else
        api.sendReply(msg, 'شما دسترسی حذف پیام ها را ندارید.')
      end
    else
      api.sendReply(msg, u.vipText())
    end
  end

end

function plugin.onCallbackQuery(msg, blocks)
  local chat_id = msg.target_id
  local user_id = msg.from.id
  if chat_id and not msg.from.admin then
		api.answerCallbackQuery(msg.cb_id, ("متاسفیم!\nشما دیگر مدیر گروه نمی باشید."))
	else
    local t, k = u.join_channel(msg.from.id, 'config:clean:'..chat_id)
    if t and k then
      api.editMessageText(msg.chat.id, msg.message_id, t, true, k)
      return
    end
    if blocks[1] == 'config' then
      if u.is_vip_group(chat_id) then
        local check_bot = api.getChatMember(chat_id, config.cli)
        if not check_bot or (check_bot.result.status == 'left' or check_bot.result.status == 'kicked') then
          local text = [[
  🙅🏻 بخش پاکسازی:

  🔸 قابلیت پاکسازی یکی دیگر از قابلیت های ضروری برای هر گروه می باشد و ربات لجندری هم این امکان رو به شما ادمین های گرامی می دهد.

  • در قدم اول شما باید ربات پاکسازی را به گروه اضافه کنید. اما قبل از اون، لطفا تمام دسترسی های مدیریتی را به من بدید تا بتونم ربات پاکسازی رو اضافه کنم.
  • سپس روی دکمه "اضافه کردن ربات 👤" بزنید.

  [Legendary Ch](https://telegram.me/joinchat/D3BUeT7pRqNEt0X3oUeE7A)
          ]]
          local keyboard = {inline_keyboard={
            {{text = 'اضافه کردن ربات 👤', callback_data = 'clean:addbot:'..chat_id}},
            {{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}}
          }}
          api.editMessageText(user_id, msg.message_id, text, true, keyboard)
        else
          api.answerCallbackQuery(msg.cb_id, 'ربات پاکسازی هم اکنون در گروه شما می باشد!\n'
          ..'در صورتی که نمی توانید از این قابلیت استفاده کنید، از دستور help/ استفاده کنید و "پاکسازی" را انتخاب کنید.', true)
        end
      else
        api.answerCallbackQuery(msg.cb_id, u.vipText(), true)
      end
    end
    if blocks[1] == 'addbot' then
      local res = api.getChatMember(chat_id, bot.id)
      if not res or (res.result.status ~= 'administrator') then
        api.answerCallbackQuery(msg.cb_id, 'من در گروه ادمین نیستم! لطفا تمام دسترسی ها رو به من بدید و مجدد تلاش کنید.', true)
      else
        if (res.result.can_promote_members == false) or (res.result.can_invite_users == false) then
          api.answerCallbackQuery(msg.cb_id, 'من دسترسی های لازم رو برای انجام این کار ندارم! لطفا تمام دسترسی های مدیریتی را به من بدید.', true)
        else
          local link = api.exportChatInviteLink(chat_id)
          if link then
            link = link.result:gsub('t.me', 'telegram.me')
          else
            api.answerCallbackQuery(msg.cb_id, 'مشکلی به وجود آمده است! لطفا به پشتیبانی اطلاع دهید.')
            return
          end
          api.sendMessage(config.cli, ('#join\nchat_id=%s&user_id=%s&chat_link=%s'):format(chat_id, user_id, link))
          api.editMessageText(user_id, msg.message_id, 'لطفا صبر کنید...\nدر حال چک کردن لینک...')
          db:setex('clean:save_msg_id:'..user_id, 3600, msg.message_id)
        end
      end
    end
  end
end

plugin.triggers = {
  onTextMessage = {
    config.cmd..'(clean)$',
    config.cmd..'(clean) (.*)$',
    ----------------------------
    '^([Cc]lean)$',
    '^([Cc]lean) (.*)$',
    ----------------------------
    '^(.*)\nchat_id=(.*)&user_id=(.*)$',
    '^(message_cleaned)\nchat_id=(.*)&user_id=(.*)$'
  },
  onCallbackQuery = {
    '^###cb:(config):clean:(-?%d+)$',
    '^###cb:clean:(.*):(-?%d+)$'
  }
}

return plugin
