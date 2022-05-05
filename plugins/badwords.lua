local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function doKeyboard_badword(chat_id)
  local keyboard = {}
	keyboard.inline_keyboard = {}
  for badword_key, default_status in pairs(config.chat_settings['badword_key']) do
    local status = (db:hget('chat:'..chat_id..':badword_key', badword_key)) or default_status
    if status == 'ok' then
			status = 'خاموش ❌'
		else
			status = 'روشن ✅'
		end

    local badword_texts = {
			bad = ("فحاشی در گروه 😼")
		}

		local badword_texts = badword_texts[badword_key] or badword_key
    local line = {
      {text = status, callback_data = 'badword:'..badword_key..':'..chat_id},
      {text = badword_texts, callback_data = 'badwordallert:'..chat_id}
    }
    table.insert(keyboard.inline_keyboard, line)
	end

  local bad_type = (db:hget('chat:'..chat_id..':bad_type', 'type')) or config.chat_settings['badword_warn']['bad_type']
  local texts
  if bad_type == 'del' then
    texts = 'حذف فحش 😼'
  elseif bad_type == 'warn' then
    texts = 'فقط اخطار 🗣'
  end

  local take_keyboard = {
    {text = texts, callback_data = 'bad_type:'..chat_id},
    {text = ("حالت اولیه 👻"), callback_data = 'first_halat:'..chat_id}
  }
  table.insert(keyboard.inline_keyboard, take_keyboard)

  local type_of_warns = db:hget('chat:'..chat_id..':bad_type', 'type') or config.chat_settings['badword_warn']['bad_type']

  if type_of_warns == 'warn' then
    local max = (db:hget('chat:'..chat_id..':badword_warn', 'warn')) or config.chat_settings['badword_warn']['warn']
    local action = (db:hget('chat:'..chat_id..':badword_warn', 'type')) or config.chat_settings['badword_warn']['type']
    local caption
    if action == 'kick' then
      caption = ("اخراج 🔵")
    else
      caption = ("مسدود 🔴")
    end
    local action_button = {
      {text = caption, callback_data = 'type:'..chat_id},
      {text = ("حالت دوم 🎈"), callback_data = 'halat:'..chat_id}
    }
    table.insert(keyboard.inline_keyboard, action_button)
    --buttons line
    local max = (db:hget('chat:'..chat_id..':badword_warn', 'warn')) or config.chat_settings['badword_warn']['warn']
    local warn = {
      {text = '➖', callback_data = 'badword_warns:dim:'..chat_id},
      {text = ('اخطار ها: (%d)'):format(max), callback_data = 'numberofwarn:'..chat_id},
      {text = '➕', callback_data = 'badword_warns:raise:'..chat_id},
    }
    table.insert(keyboard.inline_keyboard, warn)
  end
  --back button
  table.insert(keyboard.inline_keyboard, {{text = 'برگشت 🔙', callback_data = 'config:back:'..chat_id}})

  return keyboard
end

function plugin.onCallbackQuery(msg, blocks)
  local chat_id = msg.target_id
	if chat_id and not msg.from.admin then
		api.answerCallbackQuery(msg.cb_id, ("‼️ متاسفیم!\nشما دیگر مدیر گروه نمی باشید."), true)
  else
    local channel = config.channel_id
    local keyboardw = {inline_keyboard={{{text = ("همین الان عضو شو!"), url = 'https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q'}}}}
    local t, k = u.join_channel(msg.from.id, 'config:badwords:'..chat_id)
    if t and k then
      api.editMessageText(msg.chat.id, msg.message_id, t, true, k)
      return
    end
    local badword_text_first = ([[
بخش ضد فحش 😼

⁉️ با فعال کردن ضد فحش، تا حدودی از فحش های رکیک جلوگیری کنید! (برای اضافه کردن فحش به بخش تنظیمات فیلتر کردن مراجعه کنید)

توسط دکمه روشن و خاموش حالت ضد فحش رو در گروه خودتون مدیریت کنید.
توسط دکمه حالت اولیه، تعیین کنید فحش ها پاک شوند یا اخطار بهشون داده بشه؟!
توسط دکمه حالت دوم می توانید تعیین کنید اگر اخطار های یک کاربر به آخر رسید مسدود شود یا اخراج؟
و توسط دکمه + یا - می توانید اخطار ها رو کم یا زیاد کنید.

_ربات حتما در گروه شما باید ادمین باشد._

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
      ]])

      if blocks[1] == 'config' then
        local keyboard = doKeyboard_badword(chat_id)
        api.editMessageText(msg.chat.id, msg.message_id, badword_text_first, true, keyboard)
        api.answerCallbackQuery(msg.cb_id, ("تنظیمات ضد فحش"))
      else
        if blocks[1] == 'badwordallert' then
          api.answerCallbackQuery(msg.cb_id, ("برای فعال کردن حالت ضد فحش، روی گزینه سمت چپ بزنید."), true, (72 * 3600))
          return
        end
        if blocks[1] == 'first_halat' then
          api.answerCallbackQuery(msg.cb_id, "در صورتی که فحش ارسال شد، ربات به فرد اخطار دهد یا فقط فحش آن را حذف کند؟", true, (72 * 3600))
          return
        end
        if blocks[1] == 'numberofwarn' then
          api.answerCallbackQuery(msg.cb_id, ("این عدد نشان می دهد هر کاربر چند بار اخطار دریافت می کند. می توانید آن را کم یا زیاد کنید."), true, (72 * 3600))
          return
        end
        if blocks[1] == 'halat' then
          api.answerCallbackQuery(msg.cb_id, ("توسط گزینه سمت چپ، می توانید حالت مخصوص رو فعال کنید.\n"
          .."اگر اخطار های کاربر به آخر برسد، اخراج شود یا مسدود؟"), true, (72 * 3600))
        return
      end

			local cb_text
			if blocks[1] == 'badword_warns' then
        local current = tonumber(db:hget('chat:'..chat_id..':badword_warn', 'warn')) or 2
				if blocks[2] == 'dim' then
					if current < 2 then
						cb_text = ("‼️ شما نمی توانید اخطار ها رو از عدد 1 کمتر کنید.")
					else
						local new = db:hincrby('chat:'..chat_id..':badword_warn', 'warn', -1)
						cb_text = string.format('%d 👉🏻 %d', current, new)
					end
				elseif blocks[2] == 'raise' then
					if current > 7 then
						cb_text = ("‼️ شما نمیتوانید اخطار ها رو از عدد 8 بیشتر کنید.")
					else
						local new = db:hincrby('chat:'..chat_id..':badword_warn', 'warn', 1)
						cb_text = string.format('%d 👉🏻 %d', current, new)
					end
				end
			end

			if blocks[1] == 'type' then
				local hash = 'chat:'..chat_id..':badword_warn'
				local current = (db:hget(hash, 'type')) or config.chat_settings['badword_warn']['type']
				if current == 'ban' then
					db:hset(hash, 'type', 'kick')
					cb_text = ("از این پس اخطار های کاربری که فحش بفرستد به آخر برسد، کاربر اخراج می شود.")
					api.answerCallbackQuery(msg.cb_id, cb_text, true)
				else
					db:hset(hash, 'type', 'ban')
					cb_text = ("از این پس اخطار های کاربری که فحش بفرستد به آخر برسد، کاربر مسدود می شود.")
					api.answerCallbackQuery(msg.cb_id, cb_text, true)
				end
			end

      if blocks[1] == 'bad_type' then
        local hash = 'chat:'..chat_id..':bad_type'
        local status = (db:hget(hash, 'type')) or config.chat_settings['badword_warn']['bad_type']
        if status == 'del' then
          db:hset(hash, 'type', 'warn')
          cb_text = ("از این پس با ارسال فحش، اخطار داده می شود.")
          api.answerCallbackQuery(msg.cb_id, cb_text)
        elseif status == 'warn' then
          db:hset(hash, 'type', 'del')
          cb_text = ("از این پس با ارسال فحش، فحش حذف خواهد شد.")
          api.answerCallbackQuery(msg.cb_id, cb_text)
        end
      end

      if blocks[1] == 'badword' then
        local badwords = blocks[2]
        cb_text = u.changeBadword(chat_id, badwords, 'next')
      end
      local keyboard = doKeyboard_badword(chat_id)
      api.editMessageReplyMarkup(msg.chat.id, msg.message_id, keyboard)
      api.answerCallbackQuery(msg.cb_id, cb_text)
    end
  end
end

local function max_reached(chat_id, user_id)
	local max = tonumber(db:hget('chat:'..chat_id..':badword_warn', 'warn')) or 2
	local n = tonumber(db:hincrby('chat:'..chat_id..':badword_warns', user_id, 1))
	if n >= max then
		return true, n, max
	else
		return false, n, max
	end
end

function plugin.onEveryMessage(msg)
  if msg.chat.type ~= 'private' then
    local status = db:hget('chat:'..msg.chat.id..':badword_key', 'bad')
    if status and status ~= 'ok' and not msg.from.mod and not msg.cb then
      local badwords = {'کیر', 'کص', 'کسکش', 'جنده', 'کون', 'حروم زاده', 'حرام زاده', 'kir', 'jende', 'jnde', 'جاکش', 'جارکش', 'سکس', 'خایه', 'گوه', 'suck', 'tokhme sag', 'تخم سگ', 'ko3'}
      for i = 1, #badwords do
        if string.match(msg.text, badwords[i]:lower()) then
          local stats
          local name = u.getname_final(msg.from)
          local max_reached_var, n, max = max_reached(msg.chat.id, msg.from.id)
          local hash = 'chat:'..msg.chat.id..':bad_type'
          local del_badwords = db:hget(hash, 'type') or config.chat_settings['badword_warn']['bad_type']
          if del_badwords == 'del' then
            api.deleteMessage(msg.chat.id, msg.message_id)
            print("Badword deleted successfully :)")
            return
          elseif del_badwords == 'warn' then
            if max_reached_var then --max num reached. Kick/ban the user
              stats = (db:hget('chat:'..msg.chat.id..':badword_warn', 'type')) or config.chat_settings['badword_warn']['type']
              --try to kick/ban
              if stats == 'kick' then
                res = api.kickUser(msg.chat.id, msg.from.id)
              elseif stats == 'ban' then
                res = api.banUser(msg.chat.id, msg.from.id)
              end
              if res then --kick worked
                db:hdel('chat:'..msg.chat.id..':badword_warns', msg.from.id) --remove badword warns
                local message
                if stats == 'ban' then
                  message = ("کاربر %s به دلیل ارسال کلمات زشت و فحاشی از گروه مسدود شد.\n❗️ <b>(%d/%d)</b>"):format(name, n, max)
                else
                  message = ("کاربر %s به دلیل ارسال کلمات زشت و فحاشی از گروه اخراج شد.\n❗️ <b>(%d/%d)</b>"):format(name, n, max)
                end
                api.sendMessage(msg.chat.id, message, 'html')
              end
            else --max num not reached -> warn
              local message = ("کاربر %s عزیز، لطفا از ارسال کلمات زشت و فحاشی خودداری کنید.\n❗️ اخطار های شما: <code>(%d/%d)</code>"):format(name, n, max)
              api.sendReply(msg, message, 'html')
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
		'^###cb:(badword):(%a+):(-?%d+)',
		'^###cb:(type):(-?%d+)',
    '^###cb:(bad_type):(-?%d+)',
		'^###cb:(badword_warns):(%a+):(-?%d+)',
    '^###cb:(badwordallert)',
		'^###cb:(numberofwarn)',
		'^###cb:(halat)',
    '^###cb:(first_halat)',

		'^###cb:(config):badwords:(-?%d+)$',
    '^###cb:config:(warns):(-?%d+)$',
	}
}

return plugin
