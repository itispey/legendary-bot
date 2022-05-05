local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function string.random(length)
  math.randomseed(os.time())

  if length > 0 then
    return string.random(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

function plugin.cron()
  local all = db:hgetall('legendary:vipGroups')
  if next(all) then
    for chat_id, info in pairs(all) do
      local expire_time, user_id = info:match('(%d+):(%d+)')
      if tonumber(expire_time) < os.time() then
        local res = api.getChat(chat_id)
        if res then
          local text = ([[
⁉️ با سلام خدمت شما مشتری گرامی؛
اشتراک ویژه گروه %s به پایان رسیده است!
چنانچه در 10 روز آینده اقدام به تمدید اشتراک نفرمایید، تنظیمات انجام شده و اطلاعات ذخیره شده گروه شما در بانک اطلاعاتی ربات حذف خواهد شد.

با تشکر، مدیریت لجندری
          ]]):format(res.result.title)
          api.sendMessage(user_id, text)
        end
        local data = u.loadFile(config.json_path)
        data[tostring(chat_id)] = nil
        u.saveFile(config.json_path, data)
        api.sendAdmin('#پایان_اشتراک\nاشتراک ویژه گروه '..chat_id..' به پایان رسید.')
        db:hdel('legendary:vipGroups', chat_id)
        db:hset('legendary:vipArchived', chat_id, (os.time() + 864000))
      end
    end
  end

  local archives = db:hgetall('legendary:vipArchived')
  if next(archives) then
    for chats_id, expire_time in pairs(archives) do
      if tonumber(expire_time) < os.time() then
        api.sendMessage(config.cli, '#left\nchat_id='..chats_id)
        db:hdel('legendary:vipArchived', chats_id)
        api.sendAdmin("#آرشیو\nگروه "..chat_id.." از آرشیو خارج شد.")
      end
    end
  end
  
end

local function texts(key, value)
  if key == 'menu_text' then
    return ([[
🍡 بخش پنل مدیریت گروه %s

در این بخش شما می توانید به سادگی حساب ویژه گروه خود را مدیریت کنید.
توجه داشته باشید تنها تراکنش هایی که بعد از اضافه شدن این قابلیت به ثبت رسیده اند در لیست تراکنش ها موجود می باشند.

• خرید/تمدید سرویس: خرید یا تمدید سرویس حساب ویژه.
• حساب ویژه رایگان: در این بخش می توانید توسط دو روش موجود، از حساب ویژه رایگان استفاده کنید.
• مشخصات حساب من: مشاهده مدت زمان باقی مانده، زمان خرید سرویس و اطلاعات دیگر درباره حساب ویژه.
    ]]):format(value ~= nil and value or "")
  elseif key == 'rules' then
    local data = u.loadFile(config.info_path) or {}
    local link = data['support_info']['chat_link'] or "https://google.com"
    return ([[
✍🏻 قوانین و شرایط استفاده از حساب ویژه ربات لجندری (خواندن این قوانین اجباری می باشد):
• آپدیت شده در 28 فروردین 98

شما می توانید در زیر، قوانین و شرایط استفاده از ربات لجندری را ببینید. در صورتی که مایل به خرید نسخه کامل ربات هستید، باید این قوانین را بپذیرید.

1- استفاده از ربات برای گروه های توهین به ادیان، امامان و ... کاملا ممنوع می باشد و برای همیشه از ربات محروم می شوید و مبلغ خریده شده به حساب شما باز نخواهد گشت.
2- استفاده از ربات برای گروه هایی با مطالب غیراخلاقی (پورنوگرافی) کاملا ممنوع بوده و در صورت خرید، مبلغ خریده شده به خریدار باز نخواهد گشت و همچنین ربات از گروه آن کاربر خارج می شود.
3- در صورتی که از حساب ویژه ربات راضی نبودید، 3 روز فرصت دارید تا برای پس گرفتن هزینه اقدام کنید (هزینه حداکثر تا 3 روز بعد واریز می شود).
4- ربات ها بر روی سرور هستند و این امکان وجود دارد که سرور ها بعضی مواقع دچار مشکل شوند.

♨️ نکته مهم:
• حساب ویژه پس از پرداخت موفق به صورت اتوماتیک فعال می شود.
• در صورت وجود هرگونه مشکلی در پرداخت و یا عدم فعال شدن حساب ویژه، لطفا به [گروه پشتیبانی](%s) مراجعه کنید.

شما با زدن بر روی دکمه زیر، قبول می کنید که این قوانین را پذیرفتید.
[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
    ]]):format(link)
  elseif key == 'price' then
    return ([[
🔶 بخش پرداخت:

🔥 تخفیف 30 درصدری نوروزی تنها تا پایان 13 فروردین!

در اینجا 3 نوع سرویس متفاوت وجود دارد که شما بستگی به نیاز خود، هرکدام از آن ها را میتوانید بخرید.

🔷 سرویس ها:
1- سرویس 1 ماهه با تمام قابلیت های حساب ویژه!
• مبلغ: 8,000 تومان

2- سرویس 2 ماهه با تمام قابلیت های حساب ویژه!
• مبلغ: 14,000 تومان

3- سرویس 3 ماهه با تمام قابلیت های حساب ویژه!
• مبلغ: 19,000 تومان

برای پرداخت سرویس مورد نظر، روی دکمه مربوط به آن بزنید.

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
    ]])
  end
end

local function vipKeyboard(chat_id)
  local keyboard = {}
  keyboard.inline_keyboard = {
    {{text = 'خرید/تمدید سرویس 💶', callback_data = 'panel:buy_new_service:'..chat_id}, {text = 'حساب ویژه رایگان 💛', callback_data = 'panel:freevip:'..chat_id}},
    {{text = 'مشخصات حساب من 👤', callback_data = 'panel:status:'..chat_id}}
  }
  return keyboard
end

function plugin.onTextMessage(msg, blocks)
  if blocks[1]:lower() == 'panel' then
    local chat_id, title
    if msg.chat.type == 'private' then
      if not u.is_superadmin(msg.from.id) then
        api.sendReply(msg, 'لطفا از این دستور داخل گروه خود استفاده کنید!')
      else
        if blocks[2] and blocks[2]:match("(-%d+)") then
          chat_id = blocks[2]
          title = api.getChat(chat_id)
          if not title then
            api.sendReply(msg, 'دسترسی به این گروه امکان پذیر نمی باشد!')
          else
            api.sendMessage(msg.from.id, texts('menu_text', title.result.title), 'html', vipKeyboard(chat_id))
          end
        end
      end
    else
      if msg.from.admin then
        local key = {inline_keyboard = {{{text = 'مشاهده پنل 🍬', url = 'https://t.me/'..bot.username}}}}
        chat_id = msg.chat.id
        title = api.getChat(chat_id).result.title
        api.sendReply(msg, 'پنل مدیریت حساب ویژه به خصوصی شما ارسال شد.', true, key)
        api.sendMessage(msg.from.id, texts('menu_text', title), 'html', vipKeyboard(chat_id))
      end
    end
  end
  if msg.chat.type ~= 'private' then
    if blocks[1]:lower() == 'getvip' then
      if msg.from.admin then
        local chat_id = msg.chat.id
        local text
        if db:sismember('legendary:vipTrial', chat_id) then
          api.sendReply(msg, "متاسفانه تنها یک بار قابلیت استفاده از این دستور وجود دارد :(")
          return
        end
        if db:hget('legendary:vipGroups', chat_id) then
          api.sendReply(msg, "گروه شما هم اکنون ویژه می باشد")
          return
        end
        local groups = db:smembers('legendary:addedUser:'..msg.from.id) or 0
        if #groups == 0 then
          text = "شما تاکنون ربات را به هیچ گروهی اضافه نکرده اید!"
        end
        if #groups > 0 and #groups < 10 then
          text = "شما تاکنون ربات را به "..#groups.." اضافه کرده اید!\nتنها "..(10 - #groups).." گروه دیگر باقی مانده است."
        end
        if #groups >= 10 then
          local data = u.loadFile(config.json_path) or {}
          local expireDay = (20 * 86400 + os.time())
          local now = u.getShamsiTime(os.time())
          local expireDate = u.getShamsiTime(expireDay)
          local chatInfo = api.getChat(chat_id).result
          data[tostring(chat_id)] = {
            user_id = msg.from.id,
            buy_day = os.time(),
            expire_day = expireDay,
            title = chatInfo.title,
            plan = 1,
            bot_id = bot.id
          }
          u.saveFile(config.json_path, data)
          db:hset('legendary:vipGroups', chat_id, expireDay..':'..msg.from.id)
          db:sadd('legendary:vipTrial', chat_id)
          db:del('legendary:addedUser:'..msg.from.id)
          text = ([[
💯 حساب ویژه شما با موفقیت فعال شد!
شما ربات را به حداقل 10 گروه اضافه کردید و حساب ویژه رایگان شما فعال شد :)

• تاریخ فعال شدن: <b>%s</b>
• تاریخ اتمام: <b>%s</b>
• تعداد روز: <b>%s</b>

دریافت اطلاعات بیشتر با ارسال دستور /panel
          ]]):format(now, expireDate, 20)
        end
        api.sendReply(msg, text, 'html')
      end
    end
    ----------------------------------------------------------------------------------------------------
    if blocks[1]:lower() == 'code' then
      if not msg.from.admin then return end

      local code = blocks[2]
      if not code then
        api.sendReply(msg, "لطفا کد را مقابل دستور بنویسید.\n`/code hudshu`", true)
        return
      end
      if not db:get("legendary:vipCode") then
        api.sendReply(msg, "کد مورد نظر یافت نشد، احتمالا این کد وجود ندارد یا از این کد قبلا استفاده شده است!")
        return
      end

      if blocks[2] == db:get("legendary:vipCode") then
        local chat_id = msg.chat.id
        local now = u.getShamsiTime(os.time())
        local data = u.loadFile(config.json_path) or {}
        local days = (30 * 86400)

        if data[tostring(chat_id)] then -- If already is vip
          local lastPurchase
          if tonumber(data[tostring(chat_id)]['expire_day']) > os.time() then
            lastPurchase = data[tostring(chat_id)]['expire_day']
          else
            lastPurchase = os.time()
          end
          local finishDay = math.floor(((lastPurchase + days) - os.time()) / 86400) + 1
          data[tostring(chat_id)] = {
            user_id = msg.from.id,
            buy_day = os.time(),
            expire_day = (lastPurchase + days),
            title = msg.chat.title,
            plan = 1,
            bot_id = bot.id
          }
          u.saveFile(config.json_path, data)

          expireDay = u.getShamsiTime((lastPurchase + days))
          db:hset('legendary:vipGroups', chat_id, (lastPurchase + days)..':'..msg.from.id)
          text = ([[
💯 حساب ویژه شما با موفقیت فعال شد!
شما با وارد کردن کد حساب ویژه، 30 روز حساب ویژه رایگان دریافت کردید :)

• تاریخ فعال شدن: <b>%s</b>
• تاریخ اتمام: <b>%s</b>
• تعداد روز: <b>%s</b>

دریافت اطلاعات بیشتر با ارسال دستور /panel
          ]]):format(now, expireDay, finishDay)
          api.sendMessage(msg.chat.id, text, 'html')
          return
        end

        local expireDay = (30 * 86400) + os.time()
        local expireDate = u.getShamsiTime(expireDay)
        local chatInfo = api.getChat(chat_id).result
        data[tostring(chat_id)] = {
          user_id = msg.from.id,
          buy_day = os.time(),
          expire_day = expireDay,
          title = chatInfo.title,
          plan = 1,
          bot_id = bot.id
        }
        u.saveFile(config.json_path, data)
        db:hset('legendary:vipGroups', chat_id, expireDay..':'..msg.from.id)
        db:del("legendary:vipCode")
        local text = ([[
💯 حساب ویژه شما با موفقیت فعال شد!
شما با وارد کردن کد حساب ویژه، 30 روز حساب ویژه رایگان دریافت کردید :)

• تاریخ فعال شدن: <b>%s</b>
• تاریخ اتمام: <b>%s</b>
• تعداد روز: <b>%s</b>

دریافت اطلاعات بیشتر با ارسال دستور /panel
        ]]):format(now, expireDate, 30)
        api.sendReply(msg, text, 'html')
        api.sendAdmin(("گروه %s برنده خوش شانس ما بود 😃"):format(chatInfo.title))
      end
    end
  end
  ------------------------------ [Check order] ----------------------------------
  if msg.from.id == tonumber(config.forwarder) or u.is_superadmin(msg.from.id) then
    local text, ch_text, keyboard
    if blocks[1] == '0' then
      local error_text = blocks[2]
      local chat_id = blocks[3]
      local new_user_id = blocks[4]
      local plan = blocks[5]
      local bot_id = blocks[6]
      if tonumber(bot_id) == bot.id then
        local keyboard = {inline_keyboard = {
          {{text = "تلاش مجدد 💵", url = string.format("https://atunsign.ir/pay/req.php?chat_id=%s&user_id=%s&plan=%s&bot_id=%s", chat_id, new_user_id, plan, bot_id)}}
        }}
        api.sendMessage(new_user_id, "⚠️ "..error_text, 'html', keyboard)
      end
    end
    --------------------------------------------
    if blocks[1] == '1' then
      local new_user_id = blocks[4]
      local chat_id = '-'..blocks[3]
      local plan = blocks[5]
      local bot_id = blocks[6]
      if tonumber(bot_id) == bot.id then
        local expireTime, dayToSec, planString, planID
        ---------------------------
        if tonumber(plan) == 1 then
          planID = 'plan1'
          planString = 'سرویس 30 روزه (یک ماهه)'
          dayToSec = (86400 * 30)
          expireTime = os.time() + dayToSec -- 30 days
        elseif tonumber(plan) == 2 then
          planID = 'plan2'
          planString = 'سرویس 60 روزه (دو ماهه)'
          dayToSec = (86400 * 60)
          expireTime = os.time() + dayToSec -- 60 days
        elseif tonumber(plan) == 3 then
          planID = 'plan3'
          planString = 'سرویس 90 روزه (سه ماهه)'
          dayToSec = (86400 * 90)
          expireTime = os.time() + dayToSec -- 90 days
        end
        ---------------------------
        local text = ([[
✅ پرداخت با موفقیت انجام شد!

• وضعیت پرداخت: پرداخت شما با موفقیت انجام شد.
• نوع سرویس: %s
        ]]):format(planString)
        api.sendMessage(new_user_id, text, 'html', keyboard)

        local chat_title = api.getChat(chat_id)
        if chat_title then
          chat_title = chat_title.result.title
        else
          chat_title = 'unknown'
        end

        local ch_text = ([[
💎 پرداخت جدید ثبت شد.

• شخص پرداخت کننده: %s
• نوع سرویس: %s
• نام گروه: %s
• شناسه گروه: [<code>%s</code>]
        ]]):format('<a href="tg://user?id='..new_user_id..'">مشاهده اطلاعات</a>', planString, chat_title:escape_html(), chat_id)
        api.sendMessage(config.payment_ch, ch_text, 'html')
        -------------------------------
        local data = u.loadFile(config.json_path) or {}
        local now = u.getShamsiTime(os.time())
        local expireDay
        if data[tostring(chat_id)] then -- If already is vip
          local lastPurchase
          if tonumber(data[tostring(chat_id)]['expire_day']) > os.time() then
            lastPurchase = data[tostring(chat_id)]['expire_day']
          else
            lastPurchase = os.time()
          end
          data[tostring(chat_id)] = {
            user_id = new_user_id,
            buy_day = os.time(),
            expire_day = (lastPurchase + dayToSec),
            title = chat_title,
            plan = planID,
            bot_id = bot.id
          }
          u.saveFile(config.json_path, data)

          expireDay = u.getShamsiTime((lastPurchase + dayToSec))
          db:hset('legendary:vipGroups', chat_id, (lastPurchase + dayToSec)..':'..new_user_id)
          text = ([[
سرویس جدید شما فعال شد. ✅

💜 مشخصات سرویس شما:
• نوع سرویس: %s
• تاریخ خرید: %s
• تاریخ اتمام: %s

تشکر از خرید مجدد شما 🌹
          ]]):format(planString, now, expireDay)
          api.sendMessage(new_user_id, text, 'html')
          return
        end -- if it wasn't vip group

        data[tostring(chat_id)] = {
          user_id = new_user_id,
          buy_day = os.time(),
          expire_day = expireTime,
          title = chat_title,
          plan = planID,
          bot_id = bot.id
        }
        u.saveFile(config.json_path, data)

        db:hset('legendary:vipGroups', chat_id, expireTime..':'..new_user_id)
        expireDay = u.getShamsiTime(expireTime)
        text = ([[
%s با موفقیت فعال شد. ✅

🔹 مشخصات سرویس شما:
• تاریخ خرید: %s
• تاریخ اتمام: %s

• 2 روز قبل از اتمام حساب ویژه ربات پیامی برای یادآوری در گروه ارسال خواهد کرد.
• حساب ویژه شما با موفقیت فعال شده است و تمام قسمت های تنظیمات برای شما باز می باشد.
        ]]):format(planString, now, expireDay)
        api.sendMessage(new_user_id, text, 'html')
      end
    end
    -----------------------------------------------
    if blocks[1] == '2' then
      local error_text = blocks[2]
      local chat_id = blocks[3]
      local new_user_id = blocks[4]
      local plan = blocks[5]
      local bot_id = blocks[6]
      local error_code = blocks[7]
      if tonumber(bot_id) == bot.id then
        local text = ([[
⚠️ %s
کد خطا: <b>[%s]</b>
        ]]):format(error_text, error_code)
        local keyboard = {inline_keyboard = {
          {{text = "تلاش مجدد 💵", url = string.format("https://atunsign.ir/pay/req.php?chat_id=%s&user_id=%s&plan=%s&bot_id=%s", chat_id, new_user_id, plan, bot_id)}}
        }}
        api.sendMessage(new_user_id, text, 'html', keyboard)
      end
    end
    ---------------------------------- [Admin commands] ---------------------------
    if blocks[1] == 'setvip' then
      local chat_id = blocks[2]
      local creator = blocks[3]
      local days = tonumber(blocks[4])
      local plan_, st_plan
      local title_ = api.getChat(chat_id).result.title
      if not title_ then
        api.sendReply(msg, 'گروه مورد نظر یافت نشد!')
        return
      end
      local ex_time = (os.time() + (days * 86400))
      local data = u.loadFile(config.json_path)
      if days > 0 and days <= 30 then
        plan_ = 'plan1'
        st_plan = 'سرویس یک ماهه'
      elseif days > 30 and days <= 60 then
        plan_ = 'plan2'
        st_plan = 'سرویس دو ماهه'
      elseif days > 60 and days <= 90 then
        plan_ = 'plan3'
        st_plan = 'سرویس سه ماهه'
      else
        api.sendReply(msg, 'تعداد روز های وارد شده معتبر نمی باشد!\nتعداد روز ها باید عددی بین 1 تا 90 باشند.')
        return
      end
      ----------------------------------------------------
      data[tostring(chat_id)] = {
        user_id = creator, 
        buy_day = os.time(), 
        expire_day = ex_time, 
        title = title_, 
        plan = plan_, 
        bot_id = bot.id
      }
      u.saveFile(config.json_path, data)
      db:hset('legendary:vipGroups', chat_id, ex_time..':'..creator)
      api.sendReply(msg, ('✅ گروه "%s" به مدت "%s" روز حساب ویژه دریافت کرد (%s)'):format(title_, days, st_plan))
    end
    ------------------------------------------------------------
    if blocks[1] == 'delvip' then
      local chat_id = blocks[2]
      local data = u.loadFile(config.json_path)
      if not data[tostring(chat_id)] then
        api.sendReply(msg, "گروه مورد نظر شما ویژه نمی باشد!")
        return
      end
      data[tostring(chat_id)] = nil
      u.saveFile(config.json_path, data)
      db:hdel('legendary:vipGroups', chat_id)
      api.sendReply(msg, 'حساب ویژه این گروه با موفقیت حذف شد.')
    end
    ----------------------------------------------------
    if blocks[1] == 'gift' then
      local days = (blocks[2] * 86400)
      local data = u.loadFile(config.json_path)
      local i = 0
      for chat_id, info in pairs(data) do
        local expire_day = info.expire_day
        local buyer = info.user_id
        if data[tostring(chat_id)]['expire_day'] then
			    data[tostring(chat_id)]['expire_day'] = (expire_day + days)
          u.saveFile(config.json_path, data)
          db:hset('legendary:vipGroups', chat_id, (expire_day + days)..':'..buyer)
			    i = i + 1
		    end
      end
      api.sendReply(msg, "تعداد "..i.." گروه ویژه، "..blocks[2].." روز شارژ هدیه دریافت کردند.")
    end
    ----------------------------------------------------
    if blocks[1] == 'giftcode' then
      local randomCode = string.random(5)
      db:set("legendary:vipCode", randomCode)
      api.sendReply(msg, ("کد مورد نظر ساخته شد.\n`%s`"):format(randomCode), true)
    end
    
  end
end

function plugin.onCallbackQuery(msg, blocks)
  local chat_id = msg.target_id
  local user_id = msg.from.id
  -------------------------------
  if blocks[1] == 'open_vip' then
    api.editMessageText(user_id, msg.message_id, texts('menu_text'), true, vipKeyboard(chat_id))
  end
  -------------------------------
  if blocks[1] == 'buy_new_service' then
    api.answerCallbackQuery(msg.cb_id, 'بخش خرید فعلا غیر فعال می باشد.\nدر صورتی که قصد تهیه حساب ویژه دارید، عضو گروه پشتیبانی شوید.')
	return
  end
    --[[api.answerCallbackQuery(msg.cb_id, 'قوانین جدیدی به آخر لیست اضافه شده اند! حتما قبل از خرید سرویس جدید، آن ها را مطالئه کنید.', true)
    local key = {inline_keyboard = {
      {{text = 'قوانین را خوانده ام و پذیرفته ام ☑️', callback_data = 'panel:accept_rules:'..chat_id}},
      {{text = 'برگشت 🔙', callback_data = 'panel:open_vip:'..chat_id}}
    }}
    api.editMessageText(user_id, msg.message_id, texts('rules'), true, key)
  end]]
  -------------------------------
  if blocks[1] == 'accept_rules' then
    api.editMessageReplyMarkup(user_id, msg.message_id, {inline_keyboard = {{{text = 'قوانین پذیرفته شد ✅', callback_data = 'nothing'}}}})
    api.answerCallbackQuery(msg.cb_id, 'لیست سرویس های قابل خرید...')
    local keyboard = {inline_keyboard = {
      {{text = 'خرید سرویس دوم 💵', callback_data = 'panel:second_service:'..chat_id}, {text = 'خرید سرویس اول 💶', callback_data = 'panel:first_service:'..chat_id}},
      {{text = 'خرید سرویس سوم 💷', callback_data = 'panel:third_service:'..chat_id}},
      {{text = 'برگشت 🔙', callback_data = 'panel:open_vip:'..chat_id}}
    }}
    api.sendMessage(user_id, texts('price'), true, keyboard)
  end
  -------------------------------
  if blocks[1] == 'first_service' or blocks[1] == 'second_service' or blocks[1] == 'third_service' then
    chat_id = chat_id:gsub('-', '')
    local plan, keyboard, text
    if blocks[1] == 'first_service' then
      plan = 1
    elseif blocks[1] == 'second_service' then
      plan = 2
    elseif blocks[1] == 'third_service' then
      plan = 3
    end
    text = "🔹 سرویس مورد نظر شما انتخاب شد.\nبعد از پرداخت، حساب شما به صورت خودکار فعال خواهد شد.\n\n"
    .."⁉️ توجه: برای جلوگیری از مشکلات احتمالی، لطفا در زمان پرداخت فیلترشکن خود را خاموش کنید."
    keyboard = {inline_keyboard = {
      {{text = "پرداخت امن با زرین پال 💵", url = string.format("https://atunsign.ir/pay/req.php?chat_id=%s&user_id=%s&plan=%s&bot_id=%s", chat_id, user_id, plan, bot.id)}}
    }}
    api.editMessageText(msg.chat.id, msg.message_id, text, true, keyboard)
  end
  -----------------------------
  if blocks[1] == 'freevip' then
    local text = ([[
💛 دریافت حساب ویژه رایگان
شما می توانید به دو روش خیلی ساده بین 20 تا 30 روز حساب ویژه رایگان بگیرید!

🔸 روش اول: اضافه کردن ربات به 10 گروه
شما می توانید با اضافه کردن یک ربات به 10 گروه (توجه کنید فقط یکی از ربات ها)، حساب ویژه دریافت کنید!
پس از انجام این کار، برای دریافت حساب ویژه در گروه خود دستور getvip را ارسال کنید.

• توجه داشته باشید تنها یک بار می توانید از این ویژگی استفاده کنید.

🔹 روش دوم: استفاده از کد هدیه
از این پس در بعضی مواقع خاص در کانال رسمی لجندری یک کد هدیه قرار خواهد گرفت. با کپی کردن آن کد و نوشتن دستور code می توانید حساب ویژه 30 روز رایگان بگیرید.
مثلا اگر کد cgzSg بود، با دستور زیر می توانید حساب ویژه را دریافت کنید.

`/code cszSg`

• نکته اول: کد به حروف کوچک و بزرگ حساس می باشد، پس مراقب باشید.
• نکته دوم: اولین گروهی که این دستور را بزند برنده کد هدیه می شود و بقیه گروه ها دیگر نمی توانند از این دستور استفاده کنند.
    ]])
    local keyboard = {inline_keyboard = {{{text = 'برگشت 🔙', callback_data = 'panel:open_vip:'..chat_id}}}}
    api.editMessageText(user_id, msg.message_id, text, true, keyboard)
  end
  -----------------------------
  if blocks[1] == 'status' then
    local keyboard = {inline_keyboard = {{{text = 'برگشت 🔙', callback_data = 'panel:open_vip:'..chat_id}}}}
    local data = u.loadFile(config.json_path)
    if data[tostring(chat_id)] then
      local expireDay = u.getShamsiTime(data[tostring(chat_id)]['expire_day'])
      local purchaseDay = u.getShamsiTime(data[tostring(chat_id)]['buy_day'])
      local reverse
      if tonumber(data[tostring(chat_id)]['expire_day']) > os.time() then
        reverse = math.floor((tonumber(data[tostring(chat_id)]['expire_day']) - os.time()) / 86400) + 1
      else
        reverse = 0
      end
      local text = ([[
🍎 مشخصات حساب ویژه گروه شما:

• تاریخ خرید: *%s*
• تاریخ اتمام سرویس: *%s*
• مدت زمان باقی مانده: *%s* روز

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
      ]]):format(purchaseDay, expireDay, reverse)
      api.editMessageText(user_id, msg.message_id, text, true, keyboard)
    else
      api.answerCallbackQuery(msg.cb_id, '🚫 شما در حال حاضر از حساب ویژه استفاده نمی کنید!', true)
    end
  end
end

plugin.triggers = {
  onTextMessage = {
    config.cmd..'(panel)$',
    config.cmd..'(panel) (-%d+)$',
    config.cmd..'(getvip)$',
    config.cmd..'(giftcode)$',
    config.cmd..'(code)$',
    config.cmd..'(code) (.*)$',
    -----------------------
    '^([Pp]anel)$',
    '^([Pp]anel) (-%d+)$',
    -----------------------
    '^([Gg]etvip)$',
    '^([Cc]ode)$',
    '^([Cc]ode) (.*)$',
    -----------------------
    '(0)\n(.*)\n(%d+)-(%d+)-(%d+)-(%d+)',
    '(1)\n(.*)\n(%d+)-(%d+)-(%d+)-(%d+)',
		'(2)\n(.*)\n(%d+)-(%d+)-(%d+)-(%d+)-(-?%d+)',
    -----------------------
    '^/(setvip)$',
    '^/(setvip) (-%d+) (%d+) (%d+)$',
    '^/(delvip) (-%d+)$',
    '^/(gift) (%d+)$',
  },
  onCallbackQuery = {
    '^###cb:panel:(.*):(-?%d+)$'
  }
}

return plugin
