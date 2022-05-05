local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local text_ = [[
🔶 فیلتر کردن کلمات:

شما در این بخش می توانید به سادگی، اقدام به فیلتر کردن کلمات دلخواه خودتان کنید.
کلماتی که شما فیلتر خواهید کرد، اگر در گروه ارسال شود، توسط ربات پاک خواهد شد.

• در فیلتر کردن کلمات دقت کنید! اگر کلمه ای مانند "خر" رو فیلتر کنید، اگر کسی بگوید "بریم خرید"، پیام او حذف خواهد شد.
• اگر کلمه ها را به درستی فیلتر کنید، هیچ مشکلی پیش نخواهد آمد!
• حساب های عادی می توانند تا 8 کلمه را فیلتر کنند و حساب های ویژه محدودیتی در فیلتر کردن کلمات نخواهند داشت.

🔹 برای فعال کردن فیلتر کلمات، روی گزینه فعال کردن بزنید.
🔸 سپس برای اضافه کردن کلمه مورد نظر، روی دکمه اضافه کردن بزنید.

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
]]

local function filterKeyboard(chat_id)
  local keyboard = {}
  keyboard.inline_keyboard = {}
  local status_
  local status = db:hget('chat:'..chat_id..':filter', 'status') or 'off'
  if status == 'off' then
    status_ = 'غیر فعال | ❌'
  else
    status_ = 'فعال | ✅'
  end
  local first_key = {
    {text = status_, callback_data = 'filter:change_status:'..chat_id},
    {text = '💢 وضعیت فیلتر:', callback_data = 'filter:alert:status:'..chat_id}
  }
  table.insert(keyboard.inline_keyboard, first_key)
  if status == 'on' then
    local c_words_text
    local c_words_status = db:hget('chat:'..chat_id..':filter', 'c_words') or 'off'
    if c_words_status == 'off' then
      c_words_text = 'غیر فعال | ❌'
    else
      c_words_text = 'فعال | ✅'
    end
    local c_key = {
      {text = c_words_text, callback_data = 'filter:change_cwords:'..chat_id},
      {text = '🔞 تشخیص سانسور:', callback_data = 'filter:alert:cwords:'..chat_id}
    }
    table.insert(keyboard.inline_keyboard, c_key)
    local second_key = {
      {text = 'حذف کردن کلمه ➖', callback_data = 'filter:del_word:'..chat_id},
      {text = 'اضافه کردن کلمه➕', callback_data = 'filter:add_new_word:'..chat_id}
    }
    table.insert(keyboard.inline_keyboard, second_key)
    local third_key = {
      {text = 'مشاهده لیست 💭', callback_data = 'filter:show_list:'..chat_id}
    }
    table.insert(keyboard.inline_keyboard, third_key)
  end
  table.insert(keyboard.inline_keyboard, {{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}})
  return keyboard
end

function plugin.onCallbackQuery(msg, blocks)
  local chat_id = msg.target_id
  if not chat_id and not msg.from.admin then
    api.answerCallbackQuery(msg.cb_id, '🚷 شما دیگر ادمین این گروه نمی باشید', true)
  else
    local t, k = u.join_channel(msg.from.id, 'config:filter:'..chat_id)
    if t and k then
      api.editMessageText(msg.from.id, msg.message_id, t, true, k)
      return
    end
    local text, answer, keyboard
    if blocks[1] == 'config' or blocks[2] == 'cancel_filter' then
      db:del('user:'..msg.from.id..':get_filter_list')
      db:del('user:'..msg.from.id..':get_del_list')
      api.answerCallbackQuery(msg.cb_id, '🔇 به بخش فیلتر کردن کلمات خوش آمدید.\nقبل از هرکاری، حتما متن راهنما را بخوانید.', true)
      api.editMessageText(msg.chat.id, msg.message_id, text_, true, filterKeyboard(chat_id))
    else
      ------------- [Show alert] --------------
      if blocks[2] == 'alert' then
        if blocks[3] == 'status' then
          answer = '🔸 در صورتی که گزینه وضعیت فیلتر فعال شود، اگر کلمه ای فیلتر شود و کاربری آن را ارسال کند، پیام او حذف خواهد شد.'
        elseif blocks[3] == 'cwords' then
          answer = '🔸 با فعال کردن این گزینه، کاربران دیگر نمی توانند با علامت هایی مثل * کلمات خود را سانسور کنند.'
        end
        api.answerCallbackQuery(msg.cb_id, answer, true, (3600 * 72))
      end
      --------------- [Change status] ----------------
      if blocks[2] == 'change_status' then
        local hash = 'chat:'..chat_id..':filter'
        local check_status = db:hget(hash, 'status') or 'off'
        if check_status == 'off' then
          db:hset(hash, 'status', 'on')
          answer = '✅ تنظیمات فیلتر کردن کلمات، فعال شد.'
        else
          db:hset(hash, 'status', 'off')
          answer = '❌ تنظیمات فیلتر کردن کلمات، غیر فعال شد.'
        end
        api.answerCallbackQuery(msg.cb_id, answer)
      end
      --------------- [Change cwords] ----------------
      if blocks[2] == 'change_cwords' then
        local hash = 'chat:'..chat_id..':filter'
        local check_status = db:hget(hash, 'c_words') or 'off'
        if check_status == 'off' then
          if not u.is_vip_group(chat_id) then
            return api.answerCallbackQuery(msg.cb_id, u.vipText(), true)
          end
          db:hset(hash, 'c_words', 'on')
          answer = '✅ تشخیص کلمات سانسور شده فعال شد.'
        else
          db:hset(hash, 'c_words', 'off')
          answer = '❌ تشخیص کلمات فیلتر شده غیر فعال شد.'
        end
        api.answerCallbackQuery(msg.cb_id, answer)
      end
      -------------- [Add new word] ---------------
      if blocks[2] == 'add_new_word' then
        answer = 'کلمات مورد نظر خود را به راحتی فیلتر کنید 🙂'
        text = [[
⁉️ آموزش فیلتر کردن کلمات:

برای فیلتر کلمات، کافیست آن را در همینجا ارسال کنید.
زمانی که کلمه با موفقیت فیلتر شد، می توانید کلمه جدید را ارسال کنید و همینطور به ترتیب کلمات مورد نظرتان را فیلتر کنید.

🎈 نکات مهم:
• از کلمات سانسور شده مانند اح$مق استفاده نکنید! اگر می خواهید کلمات سانسور شده هم حذف شوند، کافیست گزینه تشخیص سانسور را فعال کنید.
• حتما در فیلتر کردن کلمات دقت کنید! فکر کنید ببینید اون کلمه چقدر در جمله ها استفاده می شود؟ به صورت مثال اگر "خر" را فیلتر کنید، خیلی از کلمه ها مانند "خرید" هم حذف خواهد شد.
• گروه هایی که حساب ویژه ندارند تنها می توانند تا 8 کلمه فیلتر کنند.

♨️ لطفا کلمه خود را ارسال کنید.

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
        ]]
        keyboard = {inline_keyboard = {{{text = 'لغو عملیات فیلتر کردن 🚫', callback_data = 'filter:cancel_filter:'..chat_id}}}}
        db:setex('user:'..msg.from.id..':get_filter_list', (3600), chat_id)
        api.answerCallbackQuery(msg.cb_id, answer)
        api.editMessageText(msg.chat.id, msg.message_id, text, true, keyboard)
        return
      end
      if blocks[2] == 'del_word' then
        local check = db:smembers('chat:'..chat_id..':filter_list')
        if not next(check) then
          api.answerCallbackQuery(msg.cb_id, '💯 شما هیچ کلمه ای را فیلتر نکرده اید!', true)
          return
        else
          answer = 'کلمات فیلتر شده را به راحتی حذف کنید ;)'
          text = [[
‼️ آموزش حذف کردن کلمات فیلتر شده:

برای حذف کلمه فیلتر شده، آن را ارسال کنید.

🔶 کلمات فیلتر شده در گروه شما: ]]
          for i = 1, #check do
            if i == 1 then
              text = text..'`'..check[i]..'`'
            else
              text = text..'`، '..check[i]..'`'
            end
          end
        end
        keyboard = {inline_keyboard = {{{text = 'لغو 🚫', callback_data = 'filter:cancel_filter:'..chat_id}}}}
        db:setex('user:'..msg.from.id..':get_del_list', (3600), chat_id)
        api.answerCallbackQuery(msg.cb_id, answer)
        api.editMessageText(msg.chat.id, msg.message_id, text, true, keyboard)
        return
      end
      if blocks[2] == 'show_list' then
        local check = db:smembers('chat:'..chat_id..':filter_list')
        if not next(check) then
          api.answerCallbackQuery(msg.cb_id, '💯 شما هیچ کلمه ای را فیلتر نکرده اید!', true)
          return
        else
          answer = 'لیست کلمات فیلتر شده :)'
          text = '⛔️ لیست کلماتی که در گروه شما فیلتر شده است:\n\n'
          local n = 0
          for i = 1, #check do
            n = n + 1
            text = text..n..'. `'..check[i]..'`\n'
          end
        end
        keyboard = {inline_keyboard = {
          {{text = 'حذف لیست کلمات ❌', callback_data = 'filter:delete_list:'..chat_id}},
          {{text = 'برگشت 🔙', callback_data = 'config:filter:'..chat_id}}
        }}
        api.answerCallbackQuery(msg.cb_id, answer)
        api.editMessageText(msg.chat.id, msg.message_id, text, true, keyboard)
        return
      end
      if blocks[2] == 'delete_list' then
        local hash = 'user:'..msg.from.id..':delete_list'
        if not db:get(hash) then
          api.answerCallbackQuery(msg.cb_id, 'صبر کنید ✋🏻\n'
          ..'با این کار، تمامی کلماتی که فیلتر کرده اید حذف خواهند شد!\nاگر از این کار مطمئن هستید، دوباره روی دکمه بزنید.', true)
          db:setex(hash, 1800, true)
          return
        else
          db:del(hash)
          db:del('chat:'..chat_id..':filter_list')
          api.deleteMessage(msg.chat.id, msg.message_id)
          api.answerCallbackQuery(msg.cb_id, 'لیست کلمات فیلتر شده گروه شما، با موفقیت حذف شد ✅', true)
          api.sendMessage(msg.from.id, text_, true, filterKeyboard(chat_id))
          return
        end
      end
      keyboard = filterKeyboard(chat_id)
      api.editMessageText(msg.chat.id, msg.message_id, text_, true, keyboard)
    end
  end
end

function plugin.onEveryMessage(msg)
  if msg.chat.type == 'private' then
    local user_id = msg.from.id
    ----------------- [Add new word] ----------------
    local hash = 'user:'..user_id..':get_filter_list'
    local chat_id = db:get(hash)
    local text
    if chat_id then
      local keyboard = {inline_keyboard = {{{text = 'برگشت 🚫', callback_data = 'filter:cancel_filter:'..chat_id}}}}
      if not msg.photo and not msg.video and not msg.sticker and not msg.voice and not msg.document and not msg.audio then
        if msg.text and not msg.cb then
          if not u.is_vip_group(chat_id) then
            if db:scard('chat:'..chat_id..':filter_list') >= 8 then
              text = '♨️ شما از نسخه رایگان ربات استفاده می کنید و نمی توانید بیشتر از 8 کلمه را فیلتر کنید!\n'
              ..'در صورتی که نسخه ربات را به نسخه ویژه ارتقا دهید، دیگر محدودیتی در فیلتر کردن کلمات نخواهید داشت.'
              api.sendReply(msg, text)
              api.sendMessage(user_id, text_, true, filterKeyboard(chat_id))
              db:del('user:'..user_id..':get_filter_list')
              return
            end
          end
          if tonumber(string.len(msg.text)) <= 2 then
            text = '🚫 تعداد حروف این کلمه کم تر از حد مجاز می باشد.'
            api.sendReply(msg, text, nil, keyboard)
            return
          elseif tonumber(string.len(msg.text)) >= 30 then
            text = '🚫 تعداد حروف این کلمه بیشتر از حد مجاز می باشد.'
            api.sendReply(msg, text, nil, keyboard)
            return
          elseif string.find(msg.text, '%p') then
            text = '🚫 شما نمی توانید از کاراکتر ها در کلمه خود استفاده کنید.'
            api.sendReply(msg, text, nil, keyboard)
            return
          elseif string.find(msg.text, 'ـ') then
            text = '🚫 لطفا از حروف کشیده در فیلتر کلمات استفاده نکنید.'
            api.sendReply(msg, text, nil, keyboard)
            return
          else
            db:sadd('chat:'..chat_id..':filter_list', msg.text)
            text = ('✅ کلمه [%s] با موفقیت به لیست فیلتر اضافه شد.\n'
            ..'در صورتی که می خواهید کلمه دیگری را فیلتر کنید، آن را ارسال کنید؛ در غیر این صورت از دکمه لغو عملیات استفاده کنید.'):format(msg.text)
            api.sendReply(msg, text, nil, keyboard)
          end
        end
      else
        text = '🚫 لطفا فقط کلمه مورد نظر را ارسال کنید.'
        api.sendReply(msg, text, true, keyboard)
        return
      end
    end
    ----------------- [Remove word] ----------------
    local hash = 'user:'..user_id..':get_del_list'
    local chat_id = db:get(hash)
    local text
    if chat_id then
      local keyboard = {inline_keyboard = {{{text = 'برگشت 🚫', callback_data = 'filter:cancel_filter:'..chat_id}}}}
      if not msg.photo and not msg.video and not msg.sticker and not msg.voice and not msg.document and not msg.audio then
        if msg.text and not msg.cb then
          local words = db:smembers('chat:'..chat_id..':filter_list')
          for i = 1, #words do
            if string.match(msg.text, words[i]) then
              text = ('✅ کلمه [%s] از لیست کلمات فیلتر حذف شد.\n'
              ..'در صورتی که میخواهید کلمات دیگر هم از لیست فیلتر حذف کنید، آن را ارسال کنید؛ در غیر این صورت از دکمه برگشت استفاده کنید.'):format(msg.text)
              db:srem('chat:'..chat_id..':filter_list', words[i])
              api.sendReply(msg, text, nil, keyboard)
              return
            else
              text = ('🚫 کلمه [%s] در لیست فیلتر نمی باشد!'):format(msg.text)
            end
          end
          api.sendReply(msg, text, nil, keyboard)
        end
      end
    end
  else
    local chat_id = msg.chat.id
    local message_id = msg.message_id
    local words = db:smembers('chat:'..chat_id..':filter_list')
    local status = db:hget('chat:'..chat_id..':filter', 'status')
    local cw = db:hget('chat:'..chat_id..':filter', 'c_words')
    if status and status == 'on' then
      if next(words) and not msg.from.admin and not u.is_free_user(chat_id, msg.from.id) then
        for i = 1, #words do
          if string.match(msg.text:lower(), words[i]:lower()) then
            api.deleteMessage(chat_id, message_id)
            print("Filter MSG has been deleted.")
            return
          end
          if cw and cw == 'on' then
            local new_word = msg.text
            if string.find(msg.text, '%p') then
        			new_word = msg.text:gsub('%p', '')
        		end
        		if string.find(msg.text, 'ـ') then
        			new_word = msg.text:gsub('ـ', '')
        		end
            if string.find(msg.text, '‌') then
              new_word = msg.text:gsub('‌', '')
            end
            if string.match(new_word:lower(), words[i]:lower()) then
              api.deleteMessage(chat_id, message_id)
              print("C_Word has been deleted.")
              return
            end
          end
        end
      end
    end
  end
  return true
end

plugin.triggers = {
  onCallbackQuery = {
    '^###cb:(config):filter:(-?%d+)$',
    '^###cb:(filter):(alert):(.*):(-?%d+)$',
    '^###cb:(filter):(.*):(-?%d+)$'
  }
}
return plugin
