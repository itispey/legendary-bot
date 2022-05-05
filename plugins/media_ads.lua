local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local media_strings = { 
  photo = ("• عکس"),
  audio = ("• موسیقی"),
  video = ("• فیلم"),
  video_note = ("• فیلم سلفی"),
  sticker = ("• استیکر"),
  sticker_animated = ("• استیکر انیمیشنی"),
  gif = ("• گیف"),
  voice = ("• صدا"),
  contact = ("• مخاطب"),
  document = ("• فایل"),
  game = ("• بازی"),
  location = ("• موقعیت"),
  poll = ("• نظرسنجی")
}

local ads_strings = {
  link = ("• لینک"),
  fwduser = ("• فوروارد از کاربر"),
  fwdchannel = ("• فوروارد از کانال"),
  persian = ("• متن فارسی"),
  english = ("• متن انگلیسی"),
  username = ("• نام کاربری (@)"),
  hashtag = ("• هشتگ (#)"),
  webpage = ("• لینک وبسایت"),
  tgservice = ("• پیام ورود/خروج")
}
------------------------------ SET in redis ------------------------------
function changeDatabaseOfMedia(chat_id, field)
	local hash = 'chat:'..chat_id..':media'
  local now = db:hget(hash, field)
  local media = media_strings[field:lower()]:gsub('• ', '')
	if now == 'on' then
    db:hset(hash, field, 'off')
		return "☑️ حذف کننده "..media..' غیرفعال شد.'
	else
		db:hset(hash, field, 'on')
		return "✅ حذف کننده "..media..' فعال شد.'
	end
end
------------------------------ SET in redis ------------------------------
function changeDatabaseOfAds(chat_id, field)
	local hash = 'chat:'..chat_id..':ads'
  local now = db:hget(hash, field)
  local ads = ads_strings[field:lower()]:gsub('• ', '')
	if now == 'on' then
    db:hset(hash, field, 'off')
		return "☑️ حذف کننده "..ads..' غیرفعال شد.'
	else
		db:hset(hash, field, 'on')
		return "✅ حذف کننده "..ads..' فعال شد.'
	end
end
------------------------------ Change media ------------------------------
local function changeIconMedia(settings, chat_id)
  local return_table = {}
  local icon_off, icon_on = '☑️', '✅'
  for field, default in pairs(settings) do
    local status = (db:hget('chat:'..chat_id..':media', field)) or default
    if status == 'off' then
      return_table[field] = icon_off
    elseif status == 'on' then
      return_table[field] = icon_on
    end
  end
  return return_table
end
------------------------------ Change ads ------------------------------
local function changeIconAds(settings, chat_id)
  local return_table = {}
  local icon_off, icon_on = '☑️', '✅'
  for field, default in pairs(settings) do
    local status = (db:hget('chat:'..chat_id..':ads', field)) or default
    if status == 'off' then
      return_table[field] = icon_off
    elseif status == 'on' then
      return_table[field] = icon_on
    end
  end
  return return_table
end
------------------------------ Describation_Media ------------------------------
local function mediaDescription(key)
  if key == 'photo' then
    return "اگر این گزینه را فعال کنید، هرکس در گروه عکس ارسال کند، عکس او حذف خواهد شد."
  elseif key == 'audio' then
    return "هرکس موسیقی ارسال کند، حذف خواهد شد."
  elseif key == 'video' then
    return "اگر کاربران فیلم ارسال کنند، فیلم حذف خواهد شد."
  elseif key == 'video_note' then
    return "اگر کاربران فیلم سلفی ارسال کنند، فیلم حذف خواهد شد."
  elseif key == 'sticker' then
    return "اگر کاربری استیکر ارسال کند، استیکر آن حذف خواهد شد."
  elseif key == 'animated_sticker' then
    return "اگر کاربری استیکر انیمیشنی ارسال کند، استیکر آن حذف خواهد شد."
  elseif key == 'gif' then
    return "هرکس گیف ارسال کند، حذف خواهد شد."
  elseif key == 'voice' then
    return "هرکس درگروه صدا (وویس) بفرستد، حذف خواهد شد."
  elseif key == "contact" then
    return "اگر کاربری اقدام به ارسال مخاطب (شماره تماس) کند، شماره تماس حذف خواهد شد."
  elseif key == 'document' then
    return "اگر کاربری اقدام به ارسال فایل کند، فایل آن حذف خواهد شد."
  elseif key == 'location' then
    return "اگر کاربری موقعیت مکانی خودش را ارسال کند، موقعیت مکانی او حذف خواهد شد."
  elseif key == 'game' then
    return "هرکس در گروه بازی کند (@game)، بازی او حذف خواهد شد."
  elseif key == 'poll' then
     return "هر عضوی نظرسنجی ارسال کند (به غیر از ادمین) نظرسنجی او حذف خواهد شد."
  end
end
------------------------------ Describation_Public ------------------------------
local function adsDescription(key)
  if key == 'link' then
    return "هرکس در پیام ارسالی خود از لینک استفاده کند، پیام او حذف خواهد شد."
  elseif key == 'fwduser' then
    return "هرکس که پیامی را از یک فرد عادی در داخل گروه فوروارد کند، پیام او حذف می شود."
  elseif key == 'fwdchannel' then
    return "هرکس پیامی را از یک کانال فوروارد کرده و به گروه ارسال کند، پیام او حذف خواهد شد."
  elseif key == 'persian' then
    return "هرکس در گروه فارسی تایپ کند، پیام او حذف خواهد شد."
  elseif key == 'english' then
    return "هرکس در گروه انگلیسی تایپ کند، پیام او حذف خواهد شد."
  elseif key == 'username' then
    return "هرکس در پیام خود از نام کاربری (@Username) استفاده کند، پیام او حذف خواهد شد."
  elseif key == 'hashtag' then
    return "هرکس در پیام خود از هشتگ (#) استفاده کند، پیام او حذف خواهد شد."
  elseif key == 'webpage' then
    return "هرکس در پیام خود از لینک سایت استفاده کند، پیام او حذف خواهد شد."
  elseif key == 'tgservice' then
    return "پیام های ورود و خروج دیگران از گروه، حذف خواهد شد."
  end
end
------------------------------ Buttons_Media ------------------------------
local function mediaKeyboard(keyboard, settings_section, chat_id)
  for key, icon in pairs(settings_section) do
    local current = {
      {text = icon, callback_data = 'media_settings:item:'..key..':'..chat_id},
      {text = media_strings[key] or key, callback_data = 'media_settings:alert:'..key}
    }
    table.insert(keyboard.inline_keyboard, current)
  end
  return keyboard
end
------------------------------ Buttons_Public ------------------------------
local function adsKeyboard(keyboard, settings_section, chat_id)
  for key, icon in pairs(settings_section) do
    local current = {
      {text = icon, callback_data = 'ads_settings:item:'..key..':'..chat_id},
      {text = ads_strings[key] or key, callback_data = 'ads_settings:alert:'..key}
    }
    table.insert(keyboard.inline_keyboard, current)
  end
  return keyboard
end
------------------------------ Media keyboard ------------------------------
local function doMediaKeyboard(chat_id)
  local keyboard = {inline_keyboard = {}}

  local settings_section = changeIconMedia(config.chat_settings['media'], chat_id)
  keyboad = mediaKeyboard(keyboard, settings_section, chat_id)

  table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})

  return keyboard
end
------------------------------ Ads keyboard ------------------------------
local function doAdsKeyboard(chat_id)
  local keyboard = {inline_keyboard = {}}

  local settings_section = changeIconAds(config.chat_settings['ads'], chat_id)
  keyboad = adsKeyboard(keyboard, settings_section, chat_id)

  table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})

  return keyboard
end
------------------------------------------------------------
function plugin.onCallbackQuery(msg, blocks)
  ------------------------------------------------------------ VIP MEDIA SETTINGS ------------------------------------------------------------
  local chat_id = msg.target_id
  if chat_id and not msg.from.admin then
    api.answerCallbackQuery(msg.cb_id, ("متاسفانه شما مدیر گروه نمی باشید."), true)
    return
  end

  local ads_text = ("🔹 بخش حذف تبلیغات:\n"
  .."\nشما در این قسمت می توانید تنظیمات تبلیغات گروه خودتان را مدیریت کنید. تبلیغات را حذف کنید و امنیت را در گروه خود برقرار کنید."
  .."\nهر گزینه ای که به این ☑️ شکل باشد، به معنای غیرفعال بودن آن گزینه می باشد و هر گزینه ای که به این ✅ شکل باشد، فعال می باشد.\n"
  .."\n🔹 <i>روی دکمه های ستون سمت راست که بزنید، می توانید راهنمای مربوط به اون قفل را مشاهده کنید.</i>"
  .."\nبرنامه نویسی شده توسط:\n@Legendary_Ch")

  local media_text = ("🔶 بخش تنظیمات رسانه:\n"
  .."\nشما در این قسمت می توانید رسانه هایی که نمی خواهید کسی آن ها را در گروه ارسال کند، انتخاب کنید."
  .."\nبا انتخاب رسانه مورد نظر شما، هرکس در گروه اقدام به ارسال اون رسانه بکند، کمتر از یک ثانیه اون رسانه حذف خواهد شد.\n"
  .."\nهر گزینه ای که به این ☑️ شکل باشد، به معنای غیرفعال بودن آن گزینه می باشد و هر گزینه ای که به این ✅ شکل باشد، فعال می باشد.\n"
  .."\n🔹 <i>روی دکمه های ستون سمت راست که بزنید، می توانید راهنمای مربوط به اون رسانه را مشاهده کنید.</i>"
  .."\nبرنامه نویسی شده توسط:\n@Legendary_Ch")

  local keyboard, text, show_alert
  local user_id = msg.from.id

  if blocks[1] == 'media' then
    local t, k = u.join_channel(user_id, 'config:media:'..chat_id)
    if t and k then
      api.editMessageText(user_id, msg.message_id, t, true, k)
      return
    end
    keyboard = doMediaKeyboard(chat_id)
    api.answerCallbackQuery(msg.cb_id, "رسانه ها را ممنوع کنید تا کسی نتواند آن ها را در گروه شما ارسال کند.")
    api.editMessageText(user_id, msg.message_id, media_text, 'html', keyboard)
  end

  if blocks[1] == 'ads' then
    local t, k = u.join_channel(msg.from.id, 'config:ads:'..chat_id)
    if t and k then
      api.editMessageText(user_id, msg.message_id, t, true, k)
      return
    end
    keyboard = doAdsKeyboard(chat_id)
    api.answerCallbackQuery(msg.cb_id, "به راحتی و با چند کلیک ساده حذف تبلیغات را فعال کنید.")
    api.editMessageText(user_id, msg.message_id, ads_text, 'html', keyboard)
  end

  if blocks[1] == 'media_settings' then
    if blocks[2] == 'alert' then
      text = mediaDescription(blocks[3])
      api.answerCallbackQuery(msg.cb_id, text, true, config.bot_settings.cache_time.alert_help)
      return
    end
    show_alert = changeDatabaseOfMedia(chat_id, blocks[3])
    api.answerCallbackQuery(msg.cb_id, show_alert)
    keyboard = doMediaKeyboard(chat_id)
    api.editMessageReplyMarkup(user_id, msg.message_id, keyboard)
  end

  if blocks[1] == 'ads_settings' then
    if blocks[2] == 'alert' then
      text = adsDescription(blocks[3])
      api.answerCallbackQuery(msg.cb_id, text, true, config.bot_settings.cache_time.alert_help)
      return
    end
    show_alert = changeDatabaseOfAds(chat_id, blocks[3])
    api.answerCallbackQuery(msg.cb_id, show_alert)
    keyboard = doAdsKeyboard(chat_id)
    api.editMessageReplyMarkup(user_id, msg.message_id, keyboard)
  end

end

plugin.triggers = {
  onCallbackQuery = {
    '^###cb:(media_settings):(item):([%w_]+):(-?%d+)$',
    '^###cb:(ads_settings):(item):([%w_]+):(-?%d+)$',
    '^###cb:(media_settings):(alert):([%w_]+)$',
    '^###cb:(ads_settings):(alert):([%w_]+)$',
    '^###cb:config:(ads):(-?%d+)$',
    '^###cb:config:(media):(-?%d+)$'
  }
}

return plugin
