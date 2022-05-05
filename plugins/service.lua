local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

function plugin.onTextMessage(msg, blocks)

	if not msg.service then return end
	-- [When bot added to new group] --
	if blocks[1] == 'new_chat_member:bot' or blocks[1] == 'migrate_from_chat_id' then
		local chat_id = msg.chat.id
		if u.is_blocked_global(msg.from.id) then
			u.remGroup(chat_id)
			api.leaveChat(chat_id)
			return
		end
		db:sadd('legendary:addedUser:'..msg.from.id, chat_id)
		u.initGroup(chat_id) -- add settings to database
		local data = u.loadFile(config.json_path) or {}
		if data[tostring(chat_id)] then -- check if group is VIP or not
			local expireDay = data[tostring(chat_id)]['expire_day']
			local buyer = data[tostring(chat_id)]['user_id']
			if tonumber(expireDay) > os.time() then
				db:hset('legendary:vipGroups', chat_id, expireDay..':'..buyer)
				api.sendMessage(msg.chat.id, "✅ حساب ویژه شما با موفقیت بازگردانده شد.")
			else
				data[tostring(chat_id)] = nil
				u.saveFile(config.json_path, data)
				db:hdel('legendary:vipGroups', chat_id)
				api.sendMessage(msg.from.id, 'مدت زمان حساب ویژه گروه شما به پایان رسیده است! لطفا نسبت به شارژ مجدد حساب خود، افدام کنید.')
			end
		end

		api.sendMessage(msg.chat.id, ([[
سلام! 😃
من ربات محبوب و پر قدرت لجندری هستم :)

🔹 شما می توانید از امکانات من به صورت کاملا راحت استفاده کنید و گروه خودتان را به سادگی مدیریت کنید.

🔶 لطفا قبل از شروع هر کاری، تمام ربات های گروه خود را حذف کنید! در صورتی که ربات های دیگه در گروه شما تبلیغات ارسال کنند، ربات لجندری آن ها را حذف نخواهد کرد! پس همین الان تمام ربات های رایگان گروه خود را حذف کنید تا دچار هیچ مشکلی نشوید.

🔷 همچنین شما مجاز هستید تنها از یکی از ربات های لجندری داخل گروه خود استفاده کنید.

🔸 قبل از استفاده از من، تمام راهنمای من را بخوانید؛ لازم به ذکر است من باید حتما ادمین گروه باشم و حتما باید تمام دسترسی های مدیریت برایم فعال باشد (دسترسی اضافه کردن ادمین اجباری نیست)

🔻 همچنین در صورتی که سوالی دارید، می توانید در [کانال رسمی لجندری](%s) عضو شوید و از راهنما ها استفاده کنید.

💖 ربات لجندری، بهترین انتخاب برای گروه شما :)
		]]):format(config.ch_link), true)

	elseif blocks[1] == 'left_chat_member:bot' then
		db:srem('legendary:groups', msg.chat.id)
		u.remGroup(msg.chat.id)
		print("BOT REMOVED")
	end
end

plugin.triggers = {
	onTextMessage = {
		'^###(new_chat_member:bot)',
		'^###(migrate_from_chat_id)',
		'^###(left_chat_member:bot)'
	}
}

return plugin
