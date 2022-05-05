local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function autolockKeyboard(chat_id)
  local keyboard = {}
  keyboard.inline_keyboard = {}
  local status_text
  local status = db:hget('chat:'..chat_id..':lock_group', 'status') or 'off'
  if status == 'off' then
    status_text = 'غیر فعال | ❌'
  else
    status_text = 'فعال | ✅'
  end
  local one = {
    {text = status_text, callback_data = 'lock_group:change_status:'..chat_id},
    {text = '• وضعیت قفل:', callback_data = 'lock_group:alert:status:'..chat_id}
  }
  table.insert(keyboard.inline_keyboard, one)
  ----------------------
  if status == 'on' then
    local getLockTime = db:get('chat:'..chat_id..':lock_time')
    if getLockTime then
      local key_time = {{text = 'گروه هم اکنون بسته می باشد!', callback_data = 'lock_group:alert:already_locked:'..chat_id}}
      local change_stats = {{text = '⚙️ تغییر تنظیمات', callback_data = 'lock_group:change_autolock_status:'..chat_id}}
      table.insert(keyboard.inline_keyboard, key_time)
      table.insert(keyboard.inline_keyboard, change_stats)
      table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})
      return keyboard
    end
    ------------------------------------------------------------
    local getStatus = db:get('chat:'..chat_id..':autolock_true')
    if getStatus then
      local start_time = db:hget('autolock_time', chat_id)
      local times = db:hget('chat:'..chat_id..':lock_group', 'after_lock')
      local showStatus
      if start_time and times then
        showStatus = 'فعال ✅ (مشاهده جزئیات)'
      else
        showStatus = 'مشکلی وجود دارد ⛔️'
      end
      local key_status = {
        {text = showStatus, callback_data = 'lock_group:showStatus:'..chat_id},
        {text = '• وضعیت قفل اتوماتیک:', callback_data = 'lock_group:alert:showStatus:'..chat_id}
      }
      local change_stat = {{text = '⚙️ تغییر تنظیمات', callback_data = 'lock_group:change_settings:'..chat_id}}
      table.insert(keyboard.inline_keyboard, key_status)
      table.insert(keyboard.inline_keyboard, change_stat)
      table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})
      return keyboard
    end
    -------------------------------------------------------------
    local getHandlyLock = db:get('chat:'..chat_id..':lock_handly')
    local getStringTime, calc_time
    if getHandlyLock then
      local getIntTime = db:ttl('chat:'..chat_id..':lock_handly')
      if getHandlyLock == 'min' then
        getStringTime = 'دقیقه'
        if tonumber(getIntTime) < 60 then
          calc_time = 1
        else
          calc_time = math.floor(getIntTime/60) + 1
        end
      elseif getHandlyLock == 'hour' then
        getStringTime = 'ساعت'
        if tonumber(getIntTime) < 3600 then
          calc_time = 1
        else
          calc_time = math.floor(getIntTime/3600) + 1
        end
      elseif getHandlyLock == 'day' then
        getStringTime = 'روز'
        if tonumber(getIntTime) < 86400 then
          calc_time = 1
        else
          calc_time = math.floor(getIntTime/86400) + 1
        end
      end
      local handly_key = {
        {text = string.format('فعال ✅ | %s %s دیگر', calc_time, getStringTime), callback_data = 'lock_group:getHandlyLock:'..chat_id},
        {text = '• وضعیت قفل دستی:', callback_data = 'lock_group:alert:showHandlyLock:'..chat_id}
      }
      local change_stats = {{text = '⚙️ تغییر تنظیمات', callback_data = 'lock_group:change_settings_handly:'..chat_id}}
      table.insert(keyboard.inline_keyboard, handly_key)
      table.insert(keyboard.inline_keyboard, change_stats)
      table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})
      return keyboard
    end
    -------------------------------------------------------------
    local check_stat = db:hget('chat:'..chat_id..':lock_group', 'status_of_lock') or 'off'
    local str_handly, str_auto = 'دستی', 'اتوماتیک'
    if check_stat == 'one_night' then
      str_handly = str_handly..' ✓'
      str_auto = str_auto..' ✗'
    elseif check_stat == 'every_night' then
      str_auto = str_auto..' ✓'
      str_handly = str_handly..' ✗'
    end
    local tow = {
      {text = str_auto, callback_data = 'lock_group:change_to_auto:'..chat_id},
      {text = str_handly, callback_data = 'lock_group:change_to_handly:'..chat_id},
      {text = '• نوع قفل:', callback_data = 'lock_group:alert:type:'..chat_id}
    }
    table.insert(keyboard.inline_keyboard, tow)
    ---------------------------------
    if check_stat == 'one_night' then
      table.insert(keyboard.inline_keyboard, {{text = '▾ گروه چه مدتی بسته باشد؟ ▾', callback_data = 'lock_group:alert:help_key:'..chat_id}})
      local number = tonumber(db:hget('chat:'..chat_id..':lock_group', 'get_time')) or 10
      local three = {
        {text = '«', callback_data = 'lock_group:change_time:negative_time:'..chat_id},
        {text = string.format('(%s) ⏱', number), callback_data = 'lock_group:alert:get_time:'..chat_id},
        {text = '»', callback_data = 'lock_group:change_time:positive_time:'..chat_id}
      }
      table.insert(keyboard.inline_keyboard, three)
      local four = {
        {text = ('• %s دقیقه'):format(number), callback_data = 'lock_group:set_time:minutes:'..chat_id},
        {text = ('• %s ساعت'):format(number), callback_data = 'lock_group:set_time:hours:'..chat_id},
        {text = ('• %s روز'):format(number), callback_data = 'lock_group:set_time:days:'..chat_id}
      }
      table.insert(keyboard.inline_keyboard, four)
    end
    -----------------------------------
    if check_stat == 'every_night' then
      table.insert(keyboard.inline_keyboard, {{text = '▾ زمان بسته شدن گروه ▾', callback_data = 'lock_group:alert:help1:'..chat_id}})
      local time = tonumber(db:hget('autolock_time', chat_id)) or 22
      local answer
      if time >= 0 and time <= 5 then
        answer = 'بامداد'
      elseif time >= 6 and time <= 11 then
        answer = 'صبح'
      elseif time >= 12 and time <= 16 then
        answer = 'ظهر'
      elseif time >= 17 and time <= 19 then
        answer = 'عصر'
      elseif time >= 20 and time <= 23 then
        answer = 'شب'
      end
      if time >= 0 and time <= 9 then
        time = '0'..time
      end
      local five = {
        {text = '«', callback_data = 'lock_group:change_value:negative:'..chat_id},
        {text = string.format('(%s) %s ⏰', time, answer), callback_data = 'lock_group:alert:show_time:'..chat_id},
        {text = '»', callback_data = 'lock_group:change_value:positive:'..chat_id}
      }
      table.insert(keyboard.inline_keyboard, five)
      table.insert(keyboard.inline_keyboard, {{text = '▾ زمان باز شدن گروه ▾', callback_data = 'lock_group:alert:help2:'..chat_id}})
      local time_ = tonumber(db:hget('chat:'..chat_id..':lock_group', 'after_lock')) or 8
      local answer_
      if time_ >= 0 and time_ <= 5 then
        answer_ = 'بامداد'
      elseif time_ >= 6 and time_ <= 11 then
        answer_ = 'صبح'
      elseif time_ >= 12 and time_ <= 16 then
        answer_ = 'ظهر'
      elseif time_ >= 17 and time_ <= 19 then
        answer_ = 'عصر'
      elseif time_ >= 20 and time_ <= 23 then
        answer_ = 'شب'
      end
      if time_ >= 0 and time_ <= 9 then
        time_ = '0'..time_
      end
      local six = {
        {text = '«', callback_data = 'lock_group:change_after:negative:'..chat_id},
        {text = string.format('(%s) %s ⏰', time_, answer_), callback_data = 'lock_group:alert:show_clock:'..chat_id},
        {text = '»', callback_data = 'lock_group:change_after:positive:'..chat_id}
      }
      table.insert(keyboard.inline_keyboard, six)
      table.insert(keyboard.inline_keyboard, {{text = 'ذخیره اطلاعات 💾', callback_data = 'lock_group:save_info:'..chat_id}})
    end
  end
  table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})
  return keyboard
end
---------------------- [Set lock time] -------------------------
local function changeTimeOneNight(chat_id, action)
  local hash = 'chat:'..chat_id..':lock_group'
  local number = tonumber(db:hget(hash, 'get_time')) or 10
  if not db:hget(hash, 'get_time') then
    db:hincrby(hash, 'get_time', 10)
  end
  local new
  if action == 1 then
    if number > 50 then
      return '💘 شما نمی توانید این عدد را از 50 بزرگ تر کنید.', true
    else
      new = db:hincrby(hash, 'get_time', 1)
      return string.format('♻️ عدد از %d به %d تغییر کرد.', number, new)
    end
  elseif action == -1 then
    if number < 2 then
      return '💘 شما نمی توانید این عدد را از 1 کوچکتر کنید.', true
    else
      new = db:hincrby(hash, 'get_time', -1)
      return string.format('♻️ عدد از %d به %d تغییر کرد.', number, new)
    end
  end
end
---------------------- [Change start time] --------------------------
local function changeTimeEveryNight1(chat_id, action)
  local answer
  local number = tonumber(db:hget('autolock_time', chat_id)) or 20
  if not db:hget('autolock_time', chat_id) then
    db:hincrby('autolock_time', chat_id, 20)
  end
  if number >= 0 and number <= 4 then
    answer = 'بامداد'
  elseif number >= 5 and number <= 10 then
    answer = 'صبح'
  elseif number >= 11 and number <= 15 then
    answer = 'ظهر'
  elseif number >= 16 and number <= 18 then
    answer = 'عصر'
  elseif number >= 19 and number <= 23 then
    answer = 'شب'
  end
  local new
  if action == 1 then
    if number > 22 then
      db:hincrby('autolock_time', chat_id, -23)
      return '⏰ ساعت بسته شدن گروه به ساعت 12 شب تغییر کرد.'
    else
      new = db:hincrby('autolock_time', chat_id, 1)
      return string.format('زمان بسته شدن از %d %s به %d %s تغییر کرد.', number, answer, new, answer)
    end
  elseif action == -1 then
    if number < 1 then
      db:hincrby('autolock_time', chat_id, 23)
      return '⏰ ساعت بسته شدن گروه به ساعت 23 شب، تغییر کرد.'
    else
      new = db:hincrby('autolock_time', chat_id, -1)
      return string.format('زمان بسته شدن از %d %s به %d %s تغییر کرد.', number, answer, new, answer)
    end
  end
end
-------------------- [Chenge time to finish] ----------------------
local function changeTimeEveryNight2(chat_id, action)
  local answer
  local hash = 'chat:'..chat_id..':lock_group'
  local number = tonumber(db:hget(hash, 'after_lock')) or 5
  if not db:hget(hash, 'after_lock') then
    db:hincrby(hash, 'after_lock', 5)
  end
  -----------------------------------
  if number >= 0 and number <= 4 then
    answer = 'بامداد'
  elseif number >= 5 and number <= 10 then
    answer = 'صبح'
  elseif number >= 11 and number <= 15 then
    answer = 'ظهر'
  elseif number >= 16 and number <= 18 then
    answer = 'عصر'
  elseif number >= 19 and number <= 23 then
    answer = 'شب'
  end
  -----------------------------------
  local new
  if action == 1 then
    if number > 22 then
      db:hincrby(hash, 'after_lock', -23)
      return '⏰ ساعت باز شدن گروه به ساعت 12 شب تغییر کرد.'
    else
      new = db:hincrby(hash, 'after_lock', 1)
      return string.format('⏰ زمان بسته شدن از %d %s به %d %s تغییر کرد.', number, answer, new, answer)
    end
  elseif action == -1 then
    if number < 1 then
      db:hincrby(hash, 'after_lock', 23)
      return '⏰ ساعت باز شدن گروه به ساعت 23 شب تغییر کرد.'
    else
      new = db:hincrby(hash, 'after_lock', -1)
      return string.format('⏰ زمان بسته شدن از %d %s به %d %s تغییر کرد.', number, answer, new, answer)
    end
  end
end
------------------- [Run cron job] ----------------------
function plugin.cron()
  local all = db:hgetall('autolock_time')
  for chat, time_lock in pairs(all) do
    local chat_id = chat:match('(-%d+)')
    local res = api.getChat(chat_id)
    if res then
      if db:get('chat:'..chat_id..':autolock_true') then
        if u.is_vip_group(chat_id) then
          if tonumber(os.date('%H')) == tonumber(time_lock) then
            if db:get('chat:'..chat_id..':lock_time') then
              return
            end
            local end_time = tonumber(db:hget('chat:'..chat_id..':lock_group', 'after_lock'))
            local get_final_time -- time_lock: 0 ====> end_time: 5
            if tonumber(time_lock) > 12 and end_time < 12 then
              get_final_time = (24 - tonumber(time_lock)) + end_time
            else
              get_final_time = (end_time - tonumber(time_lock))
            end
            api.sendMessage(chat_id, ('🔸 گروه بسته شد!'
            ..'\n🔹 گروه به مدت <b>[%s]</b> ساعت بسته شد و تا ساعت <b>(%s)</b> هیچ کاربری توانایی چت کردن نخواهد داشت.'):format(get_final_time, end_time), 'html')
            db:setex('chat:'..chat_id..':lock_time', (get_final_time * 3600), true)
          end
        end
      end
    else
      db:hdel('autolock_time', chat_id)
      --api.sendAdmin(('Can\'t getchat for %s (Autolock)'):format(chat_id))
    end
  end
end
------------------- [On keyboard] ----------------------
function plugin.onCallbackQuery(msg, blocks)
  local chat_id = msg.target_id
  if not chat_id and not msg.from.admin then
    api.answerCallbackQuery(msg.cb_id, '🚷 شما دیگر ادمین این گروه نمی باشید', true)
  else
    local t, k = u.join_channel(msg.from.id, 'config:lock_group:'..chat_id)
		if t and k then
			api.editMessageText(msg.chat.id, msg.message_id, t, true, k)
			return
		end
    local answer, text, keyboard
    local hash = 'chat:'..chat_id..':lock_group'
    local text_ = [[
✨ قفل گروه:

❄️ به راحتی گروه خود را ببندید و به کار هایتان برسید!

🔹 قفل گروه به 2 صورت انجام می شود:
1. قفل دستی
2. قفل اتوماتیک

برای دیدن این 2 ویژگی، کافیست "وضعیت قفل" را فعال کنید.

🔸 اگر از قابلیت اول استفاده می کنید، می توانید گروه خودتان را هر مدتی که بخواهید ببندید.
🔹 در صورتی که از قابلیت قفل اتوماتیک استفاده می کنید، می توانید ساعت شروع و پایان قفل را تعیین کنید و این عمل هرشب به صورت اتوماتیک تکرار خواهد شد.

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
    ]]
    if blocks[1] == 'config' then
      keyboard = autolockKeyboard(chat_id)
      api.answerCallbackQuery(msg.cb_id, '💛 به بخش تنظیمات قفل گروه خوش آمدید.\n'
      ..'در این بخش می توانید به صورت کاملا حرفه ای گروه خودتان را ببندید :)\nاطلاعات بیشتر در متن راهنما...', true)
      api.editMessageText(msg.chat.id, msg.message_id, text_, true, keyboard)
    else
      ------------------- [Alerts] -------------------------
      if blocks[2] == 'alert' then
        if blocks[3] == 'status' then
          answer = 'این گزینه مربوط به فعال/غیر فعال بودن تنظیمات قفل همگانی می باشد.'
        elseif blocks[3] == 'showStatus' then
          answer = 'توسط دکمه رو به رو می توانید جزئیات قفل اتوماتیک گروه خودتان را ببینید.'
        elseif blocks[3] == 'showHandlyLock' then
          answer = 'گروه شما تا چه مدت بسته می باشد؟ توسط دکمه رو به رو آن را مشاهده کنید.'
        elseif blocks[3] == 'type' then
          answer = 'نوع قفل را انتخاب کنید: دستی - اتوماتیک'
        elseif blocks[3] == 'help_key' then
          answer = 'توسط عدد زیر، تعیین کنید گروه شما به مدت چند ساعت/روز/دقیقه بسته باشد؟!'
        elseif blocks[3] == 'get_time' then
          answer = 'این عدد نشان می دهد گروه شما چه مدت بسته می باشد.'
        elseif blocks[3] == 'help1' then
          answer = 'در این بخش تعیین کنید گروه چه ساعتی بسته شود؟'
        elseif blocks[3] == 'show_time' then
          answer = 'گروه شما ساعت چند بسته شود؟ این عدد، ساعت بسته شدن را نشان می دهد.\nنکته: عدد 0 به معنی ساعت 12 شب می باشد.'
        elseif blocks[3] == 'help2' then
          answer = 'گروه شما چه ساعتی باز شود؟'
        elseif blocks[3] == 'show_clock' then
          answer = 'این عدد نشان می دهد گروه شما ساعت چند باز می شود.'
        elseif blocks[3] == 'already_locked' then
          answer = 'گروه شما هم اکنون بسته می باشد!'
        end
        api.answerCallbackQuery(msg.cb_id, answer, true, (72 * 3600))
      end
      ------------------- [Swith of or on] --------------------
      if blocks[2] == 'change_status' then
        local status = db:hget(hash, 'status') or 'off'
        if status == 'off' then
          db:hset(hash, 'status', 'on')
          answer = 'تنظیمات قفل گروه فعال شد ✅'
        else
          db:hset(hash, 'status', 'off')
          answer = 'تنظیمات قفل گروه به صورت کامل بسته شد و گروه بسته نمی باشد. ❌'
          db:del('chat:'..chat_id..':autolock_true')
          db:del('chat:'..chat_id..':lock_handly')
        end
        api.answerCallbackQuery(msg.cb_id, answer)
      end
      -------------------- [Change status of lock] ------------------------
      if blocks[2] == 'change_to_auto' or blocks[2] == 'change_to_handly' then
        if blocks[2] == 'change_to_auto' then
          if not u.is_vip_group(chat_id) then
            api.answerCallbackQuery(msg.cb_id, "استفاده از قفل اتوماتیک تنها برای گروه های ویژه امکان پذیر می باشد! اطلاعات بیشتر با ارسال دستور /panel در گروه خود :)", true)
            return
          end
          db:hset(hash, 'status_of_lock', 'every_night')
          answer = 'نوع قفل به قفل اتوماتیک تغییر کرد!'
        elseif blocks[2] == 'change_to_handly' then
          db:hset(hash, 'status_of_lock', 'one_night')
          answer = 'نوع قفل به قفل دستی تغییر کرد!'
        end
        api.answerCallbackQuery(msg.cb_id, answer)
      end
      ----------------- [If status was one_night] --------------------
      if blocks[2] == 'change_time' then
        if blocks[3] == 'negative_time' or blocks[3] == 'positive_time' then
          if blocks[3] == 'negative_time' then
            answer, text = changeTimeOneNight(chat_id, -1)
          elseif blocks[3] == 'positive_time' then
            answer, text = changeTimeOneNight(chat_id, 1)
          end
        end
        api.answerCallbackQuery(msg.cb_id, answer, text)
      end
      ----------------- [Set time lock] -------------------
      if blocks[2] == 'set_time' then
        if blocks[3] == 'minutes' or blocks[3] == 'hours' or blocks[3] == 'days' then
          local name = u.getname_final(msg.from)
          local number = tonumber(db:hget(hash, 'get_time')) or 10
          local get_time, get_time_
          if blocks[3] == 'minutes' then
            text = ('🔸 گروه به مدت <b>[%d]</b> دقیقه بسته شد.\n🔸 توسط ادمین (%s)'):format(number, name)
            answer = ('🔶 گروه شما با موفقیت به مدت %d دقیقه بسته شد.'):format(number)
            db:setex('chat:'..chat_id..':lock_handly', (number * 60), 'min')
          elseif blocks[3] == 'hours' then
            get_time = u.getShamsiTime((os.time() + number * 3600), 'time')
            text = ('🔸 گروه به مدت <b>[%d]</b> ساعت بسته شد.\n🔻 زمان باز شدن گروه: <b>%s</b>\n🔸 توسط ادمین (%s)'):format(number, get_time, name)
            answer = ('🔶 گروه شما با موفقیت به مدت %d ساعت بسته شد.'):format(number)
            db:setex('chat:'..chat_id..':lock_handly', (number * 3600), 'hour')
          elseif blocks[3] == 'days' then
            get_time = u.getShamsiTime((os.time() + number * 86400), 'date')
            get_time_ = u.getShamsiTime((os.time() + number * 86400), 'time')
            text = ('🔸 گروه به مدت <b>[%d]</b> روز بسته شد.\n🔻 زمان باز شدن گروه: <code>%s (%s)</code>\n🔸 توسط ادمین (%s)'):format(number, get_time, get_time_, name)
            answer = ('🔶 گروه شما با موفقیت به مدت %d روز بسته شد.'):format(number)
            db:setex('chat:'..chat_id..':lock_handly', (number * 86400), 'day')
          end
        end
        api.answerCallbackQuery(msg.cb_id, answer, true)
        api.sendMessage(chat_id, text, 'html')
      end
      ---------------- [If status was every_night] -------------------
      if blocks[2] == 'change_value' then
        if blocks[3] == 'negative' or blocks[3] == 'positive' then
          if blocks[3] == 'negative' then
            answer = changeTimeEveryNight1(chat_id, -1)
          elseif blocks[3] == 'positive' then
            answer = changeTimeEveryNight1(chat_id, 1)
          end
        end
        api.answerCallbackQuery(msg.cb_id, answer)
      end
      ---------------- [Set time] -------------------
      if blocks[2] == 'change_after' then
        if blocks[3] == 'negative' or blocks[3] == 'positive' then
          if blocks[3] == 'negative' then
            answer, text = changeTimeEveryNight2(chat_id, -1)
          elseif blocks[3] == 'positive' then
            answer, text = changeTimeEveryNight2(chat_id, 1)
          end
        end
        api.answerCallbackQuery(msg.cb_id, answer, text)
      end
      ---------------- [Save information about autolock] ----------------
      if blocks[2] == 'save_info' then
        local s_time = tonumber(db:hget('autolock_time', chat_id))
        local f_time = tonumber(db:hget(hash, 'after_lock'))
        local text
        if s_time == f_time then
          api.answerCallbackQuery(msg.cb_id, 'زمان شروع قفل با زمان پایان قفل نمی تواند هم زمان باشد!', true)
          return
        end
        if s_time and f_time then
          if s_time >= 19 or s_time <= 4 then
            text = 'شب'
          elseif s_time >= 5 or s_time <= 18 then
            text = 'روز'
          end
          answer = ('✅ تنظیمات با موفقیت اعمال شد.\nاز این پس هر%s گروه شما ساعت %s قفل و ساعت %s باز می شود.'):format(text, s_time, f_time)
          db:set('chat:'..chat_id..':autolock_true', true)
          u.startCron()
        else
          answer = '⭕️ لطفا زمان بسته و باز شدن گروه را تعیین کنید!'
        end
        api.answerCallbackQuery(msg.cb_id, answer, true)
      end
      ----------------- [Change settings] --------------------
      if blocks[2] == 'change_settings' then
        db:del('chat:'..chat_id..':autolock_true')
        api.answerCallbackQuery(msg.cb_id, 'گروه باز شد 😼')
      end
      ----------------- [Change settings handly] -----------------
      if blocks[2] == 'change_settings_handly' then
        db:del('chat:'..chat_id..':lock_handly')
        api.sendMessage(chat_id, ('🔹 گروه توسط ادمین (%s) باز شد!'):format(u.getname_final(msg.from)), 'html')
        api.answerCallbackQuery(msg.cb_id, '⚙️ تنظیمات حذف شدند و گروه باز شد')
      end
      ----------------- [Change autolock settings] -----------------
      if blocks[2] == 'change_autolock_status' then
        db:del('chat:'..chat_id..':lock_time')
        api.sendMessage(chat_id, ('🔹 گروه توسط ادمین (%s) باز شد!'):format(u.getname_final(msg.from)), 'html')
        api.answerCallbackQuery(msg.cb_id, '⚙️ تنظیمات به حالت اولیه برگشت.')
      end
      ----------------- [Show status] -----------------------
      if blocks[2] == 'showStatus' then
        local s_time = tonumber(db:hget('autolock_time', chat_id))
        local f_time = tonumber(db:hget('chat:'..chat_id..':lock_group', 'after_lock'))
        local text
        if s_time and f_time then
          if s_time >= 19 or s_time <= 4 then
            text = 'شب'
          elseif s_time >= 5 or s_time <= 18 then
            text = 'روز'
          end
          answer = ('قفل اتوماتیک هر%s ساعت %s فعال می شود و ساعت %s غیر فعال می شود.'):format(text, s_time, f_time)
        else
          answer = 'مشکلی وجود دارد! با پشتیبانی تماس بگیرید.'
        end
        api.answerCallbackQuery(msg.cb_id, answer, true)
      end
      ----------------- [Edit message and keyboard] ----------------
      keyboard = autolockKeyboard(chat_id)
      api.editMessageReplyMarkup(msg.chat.id, msg.message_id, keyboard)
    end
  end
end
--------------------- [End of autolock :)] ---------------------
plugin.triggers = {
  onCallbackQuery = {
    '^###cb:(config):lock_group:(-?%d+)$',
    '^###cb:(lock_group):(.*):(.*):(-?%d+)$',
    '^###cb:(lock_group):(.*):(-?%d+)$'
  }
}
return plugin
