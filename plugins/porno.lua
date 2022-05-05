local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local url = 'https://api.telegram.org/file/bot'..config.telegram.token..'/'

local plugin = {}

local mainText = ([[
🔞 تشخیص محتوای پورنوگرافی:

🔻 شما می توانید به سادگی و با یک دکمه، از ارسال استیکر و عکس پورن به گروه خود جلوگیری کنید.

🔸 توضیحات مهم:
برای مدیریت راحت تر شما عزیزان، این بخش را به 4 سطح تقسیم بندی کرده ایم.

• سطح 1 : در صورتی که روی این سطح تنظیم کنید، عکس و استیکر پورن پاک خواهد شد.
• سطح 2 (پیشنهاد ما) : در صورت تنظیم روی سطح 2، درصد سخت گیری ربات بالاتر می رود و ممکن است مواردی که شبیه به پورن هستند هم حذف شوند.
• سطح 3 : این سطح علاوه بر موارد بالا، احتمال حذف عکس هایی با پوشش تقریبا برهنه (بیکینی یا لباس شنا) و مواردی شبیه به این را دارد.
• سطح 4 (پیشنهاد نمی شود) : این سطح سخت گیر ترین حالت ربات می باشد. علاوه بر موارد بالا، احتمال حذف پوشش هایی با برهنگی کم و مواردی شبیه به این وجود دارد.

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
    ]])
local levelStatusText = {
    low = "سطح 1",
    medium = "سطح 2",
    high = "سطح 3",
    veryHigh = "سطح 4"
}

local function pornoKeyboard(chat_id)
    local keyboard = {}
    keyboard.inline_keyboard = {}

    local status = db:hget('chat:'..chat_id..':porno', 'status') or 'off'
    local statusKeyboard = {
        {text = status == 'on' and 'فعال | ✅' or 'غیرفعال | ❌', callback_data = 'porno:changeStatus:'..chat_id},
        {text = "♨️ وضعیت :", callback_data = 'porno:alert:status:'..chat_id}
    }
    table.insert(keyboard.inline_keyboard, statusKeyboard)
    
    if status == "on" then
        local levelStatus = db:hget('chat:'..chat_id..':porno', 'level') or "medium"

        table.insert(keyboard.inline_keyboard,
        {{text = ('🔻 سطح سخت گیری (%s) 🔻'):format(levelStatusText[levelStatus]), callback_data = 'porno:alert:level:'..chat_id}})

        local hardshipLevel = {
            {text = ("(سطح 4)"):format(levelText), callback_data = 'porno:changeLevel:veryHigh:'..chat_id},
            {text = ("(سطح 3)"):format(levelText), callback_data = 'porno:changeLevel:high:'..chat_id},
            {text = ("(سطح 2)"):format(levelText), callback_data = 'porno:changeLevel:medium:'..chat_id},
            {text = ("(سطح 1)"):format(levelText), callback_data = 'porno:changeLevel:low:'..chat_id}
        }
        table.insert(keyboard.inline_keyboard, hardshipLevel)
    end

    table.insert(keyboard.inline_keyboard, {{text = 'برگشت ↶', callback_data = 'config:back:'..chat_id}})
    return keyboard
end

function plugin.onCallbackQuery(msg, blocks)
    local chat_id = msg.target_id
    local user_id = msg.from.id
    if not chat_id and not msg.from.admin then
        api.answerCallbackQuery(msg.cb_id, '🚷 شما دیگر ادمین این گروه نمی باشید', true)
        return
    end

    local t, k = u.join_channel(msg.from.id, 'config:filter:'..chat_id)
    if t and k then
      api.editMessageText(msg.from.id, msg.message_id, t, true, k)
      return
    end

    local text, answer, keyboard
    if blocks[1] == 'config' then
        if not u.is_vip_group(chat_id) then
            api.answerCallbackQuery(msg.cb_id, "استفاده از قابلیت تشخیص محتوای پورنوگرافی تنها برای گروه های ویژه فعال می باشد!\n"
            .."اطلاعات بیشتر با ارسال دستور panel/ در گروه.", true)
            return
        end
        local t, k = u.join_channel(msg.from.id, 'config:porno:'..chat_id)
        if t and k then
            api.editMessageText(msg.chat.id, msg.message_id, t, true, k)
            return
        end
        api.answerCallbackQuery(msg.cb_id, "🔞 تنظیمات بخش تشخیص محتوای پورنوگرافی...")
        api.editMessageText(user_id, msg.message_id, mainText, true, pornoKeyboard(chat_id))
    end

    if blocks[1] == 'changeStatus' then
        local status = db:hget('chat:'..chat_id..':porno', 'status') or 'off'
        if status == "off" then
            db:hset('chat:'..chat_id..':porno', 'status', 'on')
            api.answerCallbackQuery(msg.cb_id, "تشخیص محتوای پورنوگرافی فعال شد ✅")
        else
            db:hset('chat:'..chat_id..':porno', 'status', 'off')
            api.answerCallbackQuery(msg.cb_id, "تشخیص محتوای پورنوگرافی غیرفعال شد ❌")
        end
        api.editMessageText(user_id, msg.message_id, mainText, true, pornoKeyboard(chat_id))
    end

    if blocks[1] == 'changeLevel' then
        local newLevel = blocks[2]
        db:hset('chat:'..chat_id..':porno', 'level', newLevel)
        api.answerCallbackQuery(msg.cb_id, "سطح سخت گیری بر روی "..levelStatusText[newLevel].." تنظیم شد!")
        api.editMessageText(user_id, msg.message_id, mainText, true, pornoKeyboard(chat_id))
    end

    if blocks[1] == 'alert' then
        if blocks[2] == 'status' then
            api.answerCallbackQuery(msg.cb_id, "وضعیت قفل پورنوگرافی: فعال/غیرفعال", true, config.bot_settings.cache_time.alert_help)
        end
        if blocks[2] == 'level' then
            api.answerCallbackQuery(msg.cb_id, "سطح تشخیص پورنوگرافی (توضیحات کامل در بالای دکمه ها)", true, config.bot_settings.cache_time.alert_help)
        end
    end
end

function plugin.onEveryMessage(msg)
    local chat_id = msg.chat.id
    local time = clr.cyan..'['..os.date('%X')..'] '..clr.reset
    if u.is_vip_group(chat_id) then
        if not msg.from.admin and not u.is_free_user(chat_id, msg.from.id) then
            local status = db:hget('chat:'..chat_id..':porno', 'status') or 'off'
            local level = db:hget('chat:'..chat_id..':porno', 'level') or "medium"
            if status == 'on' then 
                if msg.photo or msg.sticker then
                    local media = msg.photo and msg.photo[1] or msg.sticker
                    local file_path = api.getFile(media.file_id).result.file_path
                    local download_link = url..file_path
                    local res = api.performRequest("http://localhost:5000/?url="..download_link)
                    if res then
                        local de = JSON.decode(res)
                        if de then
                            if de.score and de.score >= 0.9 then	
                                if level == "low" then
                                    api.deleteMessage(chat_id, msg.message_id)
                                    print(time.."Deleted "..clr.red.."[LOW PORN]"..clr.green.." Successfully"..clr.reset)
                                    return
                                end
                            end
                            if de.score and de.score >= 0.7 then
                                if level == "medium" then
                                    api.deleteMessage(chat_id, msg.message_id)
                                    print(time.."Deleted "..clr.red.."[MEDIUM PORN]"..clr.green.." Successfully"..clr.reset)
                                    return
                                end
                            end
                            if de.score and de.score >= 0.5 then
                                if level == "high" then
                                    api.deleteMessage(chat_id, msg.message_id)
                                    print(time.."Deleted "..clr.red.."[HIGH PORN]"..clr.green.." Successfully"..clr.reset)
                                    return
                                end
                            end
                            if de.score and de.score >= 0.3 then
                                if level == "veryHigh" then
                                    api.deleteMessage(chat_id, msg.message_id)
                                    print(time.."Deleted "..clr.red.."[VERYHIGH PORN]"..clr.green.." Successfully"..clr.reset)
                                    return
                                end
                            end
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
        '^###cb:porno:(.*):(.*):(.*)$',
        '^###cb:porno:(.*):(.*)$',
        '^###cb:(config):porno:(-?%d+)$'
    }
}

return plugin