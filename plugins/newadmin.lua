local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function infoKeyboard(key)
  if key == 'can_change_info' then
    return ('🔸 در صورت فعال بودن این دسترسی، ادمین می تواند نام، عکس و توضیحات گروه را تغییر دهد.')
  elseif key == 'can_delete_messages' then
    return ('🔸 با فعال بودن این دسترسی، ادمین می تواند پیام های کاربر های دیگه را حذف کند.')
  elseif key == 'can_invite_users' then
    return ('🔸 در صورت فعال بودن این دسترسی، ادمین می تواند کاربران را با لینک شخصیِ مخصوص خودش به گروه اضافه کند.')
  elseif key == 'can_pin_messages' then
    return ('🔸 با فعال کردن این دسترسی، ادمین می تواند هر پیامی را سنجاق کند و همچنین می تواند پیام های سنجاق شده را از حالت سنجاق خارج کند.')
  elseif key == 'can_promote_members' then
    return ('🔸 با فعال کردن این دسترسی، ادمین مورد نظر می تواند یک ادمین جدید به دلخواه اضافه کند! همچنین می تواند دسترسیِ ادمین هایی که فقط خودش اضافه کرده است را تغییر دهد!')
  elseif key == 'can_restrict_members' then
    return ('🔸 این دسترسی باعث می شود تا ادمین بتواند شخصی را مسدود کند یا اون را محدود کند (مثلا نتواند استیکر بفرستد) !')
  end
end

local function promoteKeyboard(chat_id, user_id)
  local per = {
    ['can_change_info'] = 'تغییر مشخصات ℹ️',
    ['can_delete_messages'] = 'حذف پیام ها 🗑',
    ['can_invite_users'] = 'دعوت عضو 🙋🏻‍♂️',
    ['can_pin_messages'] = 'سنجاق کردن (پین) 📌',
    ['can_promote_members'] = 'اضافه کردن ادمین 👑',
    ['can_restrict_members'] = 'محدود کردن اعضا 🚫'
  }
  local keyboard = {inline_keyboard = {}}
  table.insert(keyboard.inline_keyboard, {
    {text = 'لغو انتخاب همه ☑️', callback_data = 'newadmin:unmarkall:'..user_id}, {text = 'انتخاب همه ✅', callback_data = 'newadmin:markall:'..user_id}
  })
  table.insert(keyboard.inline_keyboard, {{text = '-----------------------------------------', callback_data = 'nothing'}})
  for permission, status in pairs(config.chat_settings['change_per']) do
    local status_ = db:get('user_permission:'..permission..':'..user_id) or status
    local icon
    if status_ == 'true' then
      icon = '✅'
    elseif status_ == 'false' then
      icon = '❌'
    end
    table.insert(keyboard.inline_keyboard, {
      {text = icon, callback_data = 'newadmin:promote:'..permission..':'..user_id}, {text = per[permission], callback_data = 'newadmin:alert:'..permission}
    })
  end
  table.insert(keyboard.inline_keyboard, {{text = 'ذخیره 💾', callback_data = 'newadmin:save_per:'..user_id}})
  table.insert(keyboard.inline_keyboard, {{text = 'لغو عملیات ⭕️', callback_data = 'newadmin:cancel:'..user_id}})
  return keyboard
end

local function deleteRD(chat_id, user_id)
  db:del('user_permission:can_change_info:'..user_id)
  db:del('user_permission:can_delete_messages:'..user_id)
  db:del('user_permission:can_invite_users:'..user_id)
  db:del('user_permission:can_restrict_members:'..user_id)
  db:del('user_permission:can_pin_messages:'..user_id)
  db:del('user_permission:can_promote_members:'..user_id)
  db:del('save_admin:'..chat_id)
end

function plugin.onTextMessage(msg, blocks)
  local chat_id, user_id = msg.chat.id, msg.from.id
  local text, keyboard
  if msg.chat.type ~= 'private' then

    if not msg.from.admin then return end

    if blocks[1]:lower() == 'addadmin' then  
      local get = api.getChatMember(chat_id, user_id).result
      if not u.is_superadmin(msg.from.id) then
        if not (get.status == 'administrator' and get.can_promote_members == true) or not get.status == 'creator' or u.is_superadmin(msg.from.id) then
          api.sendReply(msg, 'شما دسترسی اضافه کردن ادمین جدید را ندارید!\n'
          ..'تنها ادمین هایی که دسترسی اضافه کردن ادمین را دارند، می توانند از این دستور استفاده کنند.')
          return
        end
      end
        
      local new_user_id, error = u.get_user_id(msg, blocks)
      if not new_user_id then
        api.sendReply(msg, error)
        return
      end

      local res = api.getChatMember(chat_id, new_user_id)
      if res.result.user.id == user_id then
        api.sendReply(msg, 'شما نمی توانید دسترسی های خودتان را تغییر دهید!')
        return
      end

      if res.result.user.id == bot.id then
        api.sendReply(msg, 'شما نمی توانید دسترسی های ربات را تغییر دهید!')
        return
      end

      if res.result.status ~= 'administrator' and res.result.status == 'member' or res.result.status == 'restricted' then
        keyboard = promoteKeyboard(chat_id, new_user_id)
        text = ([[
💎 دسترسی های ادمین جدید:

🔸 نام کاربر: %s

🔻 برای ادمین کردن این کاربر، ابتدا دسترسی های آن را تعیین کنید. (اگر نیازی به راهنما دارید، روی دکمه های سمت راست بزنید تا راهنما را مشاهده کنید)

@Legendary_Ch
        ]]):format(u.getname_final(res.result.user))
        api.sendMessage(chat_id, text, 'html', keyboard)
        db:setex('save_admin:'..chat_id, 3600, user_id)
      else
        api.sendReply(msg, 'کاربر باید عضو عادی باشد!\nاگر می خواهید دسترسی های ادمین را تغییر دهید، از دستور editadmin/ استفاده کنید.')
      end
    end
    --------------------------------
    if blocks[1]:lower() == 'editadmin' then
      local get = api.getChatMember(chat_id, user_id).result
      if not u.is_superadmin(msg.from.id) then
        if not (get.status == 'administrator' and get.can_promote_members == true) or not get.status == 'creator' or u.is_superadmin(msg.from.id) then
          api.sendReply(msg, 'شما دسترسی اضافه کردن ادمین جدید را ندارید!\n'
          ..'تنها ادمین هایی که دسترسی اضافه کردن ادمین را دارند، می توانند از این دستور استفاده کنند.')
          return
        end
      end

      local new_user_id, error = u.get_user_id(msg, blocks)
      if not new_user_id then
        api.sendReply(msg, error)
        return
      end

      local res = api.getChatMember(chat_id, new_user_id)
      if res.result.user.id == user_id then
        api.sendReply(msg, 'شما نمی توانید دسترسی های خودتان را تغییر دهید!')
        return
      end

      if res.result.user.id == bot.id then
        api.sendReply(msg, 'شما نمی توانید دسترسی های ربات را تغییر دهید!')
        return
      end

      if res.result.status == 'administrator' then
        for per, status in pairs(res.result) do
          if per:match('(can_(.*))') and not per:match('(can_be_edited)') then
            db:setex('user_permission:'..per..':'..new_user_id, 3600, tostring(status))
          end
        end
        keyboard = promoteKeyboard(chat_id, new_user_id)
        text = ([[
💖 تغییر دسترسی های ادمین:

🔸 نام ادمین: %s

🔻 برای تغییر دسترسی های ادمین مورد نظر، کافی هست روی دکمه های سمت چپ بزنید.
همچنین در صورتی که نیاز به راهنما دارید، از دکمه های ستون سمت راست استفاده کنید.

🔹 <i>توجه: در صورتی که کاربر مورد نظر توسط من ادمین نشده باشد، من نمی توانم دسترسی های آن کاربر را تغییر بدم!</i>

@Legendary_Ch
        ]]):format(u.getname_final(res.result.user))
        api.sendMessage(chat_id, text, 'html', keyboard)
        db:setex('save_admin:'..chat_id, 3600, user_id)
      else
        api.sendReply(msg, 'کاربر مورد نظر حتما باید ادمین باشد!\nدر صورتی که می خواهید کاربری را ادمین کنید، از دستور addadmin/ استفاده کنید.')
      end
    end
    ------------------------------------------------- [Set Deny] -------------------------------------------------
    if blocks[1]:lower() == 'setfree' then
      local chat_id = msg.chat.id

      local new_user_id, error = u.get_user_id(msg, blocks)
      if not new_user_id then
        api.sendReply(msg, error)
        return
      end

      if u.is_admin(chat_id, new_user_id) then
        api.sendReply(msg, "کاربر مورد نظر شما هم اکنون ادمین می باشد.")
        return
      end

      local user = api.getChatMember(chat_id, new_user_id).result.user
      local name = u.getname_final(user)
      local admin = u.getname_final(msg.from)
      local hash = 'chat:'..chat_id..':deny'
      if db:hget(hash, new_user_id) then
        api.sendReply(msg, ("⁉️ کاربر %s در حال حاضر در لیست کاربر های آزاد می باشد."):format(name), 'html')
        return
      end
      db:hset(hash, new_user_id, user.first_name)
      api.sendReply(msg, ("⁉️ کاربر %s به لیست کاربر های آزاد اضافه شد. از این پس پیام های این کاربر حذف نخواهد شد.\n\n"
      .."• توسط ادمین: (%s)"):format(name, admin), 'html')
    end

    if blocks[1]:lower() == 'remfree' then
      local new_user_id, error = u.get_user_id(msg, blocks)
      if not new_user_id then
        api.sendReply(msg, error)
        return
      end
      local user = api.getChatMember(chat_id, new_user_id).result.user
      local name = u.getname_final(user)
      local admin = u.getname_final(msg.from)
      local chat_id = msg.chat.id
      local hash = 'chat:'..chat_id..':deny'
      if not db:hget(hash, new_user_id) then
        api.sendReply(msg, ("⁉️ کاربر %s در لیست کاربر های آزاد نمی باشد."):format(name), 'html')
        return
      end
      db:hdel(hash, new_user_id)
      api.sendReply(msg, ("⁉️ کاربر %s از لیست کاربر های آزاد حذف شد.\n\n"
      .."• توسط ادمین: (%s)"):format(name, admin), 'html')
    end

    if blocks[1]:lower() == 'freelist' then
      local users = db:hgetall('chat:'..chat_id..':deny')
      local n = 1
      if not next(users) then
        api.sendReply(msg, "این لیست خالی می باشد.")
        return
      end
      local text = "🕊 لیست کاربران آزاد : \n\n"
      for user_id, names in pairs(users) do
        text = text..n..'. '..names..' [<code>'..user_id..'</code>]\n'
        n = n + 1
      end
      api.sendReply(msg, text, 'html')
    end

  end
end

function plugin.onCallbackQuery(msg, blocks)
  local chat_id, user_id = msg.chat.id, msg.from.id
  local text, keyboard
  if msg.from.admin then
    -------------------------------
    if blocks[1] == 'promote' then
      if (user_id == tonumber(db:get('save_admin:'..chat_id))) then
        local per = blocks[2]
        local new_user_id = blocks[3]
        local status = db:get('user_permission:'..per..':'..new_user_id) or config.chat_settings['change_per'][per]
        if status == 'true' then
          db:setex('user_permission:'..per..':'..new_user_id, 3600, 'false')
          api.answerCallbackQuery(msg.cb_id, 'دسترسی مورد نظر گرفته شد. ❌')
        elseif status == 'false' then
          db:setex('user_permission:'..per..':'..new_user_id, 3600, 'true')
          api.answerCallbackQuery(msg.cb_id, 'دسترسی مورد نظر داده شد. ✅')
        end
        api.editMessageReplyMarkup(chat_id, msg.message_id, promoteKeyboard(chat_id, new_user_id))
      end
    end
    -------------------------------
    if blocks[1] == 'save_per' then
      if (user_id == tonumber(db:get('save_admin:'..chat_id))) then
        local new_user_id = blocks[2]
        local answer
    		local per = {
    			can_change_info = db:get('user_permission:can_change_info:'..new_user_id) or config.chat_settings['change_per']['can_change_info'],
    			can_delete_messages = db:get('user_permission:can_delete_messages:'..new_user_id) or config.chat_settings['change_per']['can_delete_messages'],
    			can_invite_users = db:get('user_permission:can_invite_users:'..new_user_id) or config.chat_settings['change_per']['can_invite_users'],
    			can_restrict_members = db:get('user_permission:can_restrict_members:'..new_user_id) or config.chat_settings['change_per']['can_restrict_members'],
    			can_pin_messages = db:get('user_permission:can_pin_messages:'..new_user_id) or config.chat_settings['change_per']['can_pin_messages'],
    			can_promote_members = db:get('user_permission:can_promote_members:'..new_user_id) or config.chat_settings['change_per']['can_promote_members']
    		}

        local res = api.promoteChatMember(chat_id, new_user_id, per)
        local req = api.getChatMember(chat_id, new_user_id)
        if not res then
          text = 'من قادر به انجام این کار نیستم!\nاحتمالا این کاربر قبلا ادمین شده است و من نمی توانم دسترسی این کاربر را تغییر بدم.'
          api.answerCallbackQuery(msg.cb_id, text, true)
          api.editMessageText(chat_id, msg.message_id, text)
          deleteRD(chat_id, new_user_id)
          return
        end
        if per.can_change_info == 'false' and per.can_delete_messages == 'false' and per.can_invite_users == 'false'
        and per.can_restrict_members == 'false' and per.can_pin_messages == 'false' and per.can_promote_members == 'false' then
          answer = '🔸 ادمین مورد نظر برکنار شد.'
          text = ('🔸 ادمین %s برکنار شد.\nتوسط ادمین (%s)'):format(u.getname_final(req.result.user), u.getname_final(msg.from))
          api.editMessageText(chat_id, msg.message_id, text, 'html')
          api.answerCallbackQuery(msg.cb_id, answer, true)
          deleteRD(chat_id, new_user_id)
          return
        end

        local new_text = '🔸 دسترسی های جدید:\n'
        if per.can_change_info == 'true' then
          new_text = new_text..'• دسترسی تغییر محتویات گروه\n'
        end
        if per.can_delete_messages == 'true' then
          new_text = new_text..'• دسترسی حذف پیام ها\n'
        end
        if per.can_invite_users == 'true' then
          new_text = new_text..'• دسترسی اضافه کردن عضو جدید\n'
        end
        if per.can_restrict_members == 'true' then
          new_text = new_text..'• دسترسی محدود کردن اعضا\n'
        end
        if per.can_pin_messages == 'true' then
          new_text = new_text..'• دسترسی پین کردن پیام\n'
        end
        if per.can_promote_members == 'true' then
          new_text = new_text..'• دسترسی اضافه کردن ادمین جدید\n'
        end

        text = ([[
🔹 کاربر %s با موفقیت ادمین شد. تبریک ☺️🌹
👨🏻‍💻 توسط ادمین: (%s)

%s
        ]]):format(u.getname_final(req.result.user),u.getname_final(msg.from), new_text)
        api.editMessageText(chat_id, msg.message_id, text, 'html')
        api.answerCallbackQuery(msg.cb_id, 'دسترسی ها با موفقیت اعمال شدند!', true)
        deleteRD(chat_id, new_user_id)
      end
    end
    -------------------------------
    if blocks[1] == 'markall' then
      if (user_id == tonumber(db:get('save_admin:'..chat_id))) then
        local new_user_id = blocks[2]
        for permission, _ in pairs(config.chat_settings['change_per']) do
          db:setex('user_permission:'..permission..':'..new_user_id, 3600, 'true')
        end
        api.answerCallbackQuery(msg.cb_id, 'تمام دسترسی ها فعال شد! ✅')
        api.editMessageReplyMarkup(chat_id, msg.message_id, promoteKeyboard(chat_id, new_user_id))
      end
    end
    -------------------------------
    if blocks[1] == 'unmarkall' then
      if (user_id == tonumber(db:get('save_admin:'..chat_id))) then
        local new_user_id = blocks[2]
        for permission, _ in pairs(config.chat_settings['change_per']) do
          db:setex('user_permission:'..permission..':'..new_user_id, 3600, 'false')
        end
        api.answerCallbackQuery(msg.cb_id, 'تمام دسترسی ها غیر فعال شد ❌')
        api.editMessageReplyMarkup(chat_id, msg.message_id, promoteKeyboard(chat_id, new_user_id))
      end
    end
    -------------------------------
    if blocks[1] == 'alert' then
      local answer = infoKeyboard(blocks[2])
      api.answerCallbackQuery(msg.cb_id, answer, true, config.bot_settings.cache_time.alert_help)
    end
    -------------------------------
    if blocks[1] == 'cancel' then
      if (user_id == tonumber(db:get('save_admin:'..chat_id))) then
        local new_user_id = blocks[2]
        deleteRD(chat_id, new_user_id)
        api.editMessageText(msg.chat.id, msg.message_id, '🐛 عملیات لغو شد.')
      end
    end
  end
end

plugin.triggers = {
  onTextMessage = {
    config.cmd..'(addadmin)$',
    config.cmd..'(addadmin) (.*)$',
    config.cmd..'(editadmin)$',
    config.cmd..'(editadmin) (.*)$',
    config.cmd..'(setfree)$',
    config.cmd..'(setfree) (.*)$',
    config.cmd..'(remfree)$',
    config.cmd..'(remfree) (.*)$',
    config.cmd..'(freelist)',
    --------------------------------
    '^([Aa]ddadmin)$',
    '^([Aa]ddadmin) (.*)$',
    '^([Ee]ditadmin)$',
    '^([Ee]ditadmin) (.*)$',
    '^([Ss]etfree)$',
    '^([Ss]etfree) (.*)$',
    '^([Rr]emfree)$',
    '^([Rr]emfree) (.*)$',
    '^([Ff]reelist)$'
  },
  onCallbackQuery = {
    '^###cb:newadmin:(promote):([%w_]+):(%d+)$',
    '^###cb:newadmin:([%w_]+):(%d+)$',
    '^###cb:newadmin:([%w_]+):([%w_]+)$'
  }
}

return plugin
