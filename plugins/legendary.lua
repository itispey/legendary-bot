local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

--[[function plugin.cron()
  if tonumber(os.date('%H')) == 0 then
    if not db:get('send:backup') then
      api.sendDocument(config.backup_ch, config.json_path, nil, u.getShamsiTime(os.time(), 'date_num'))
      db:setex('send:backup', (3600 * 2), 'done')
    end
  end
end]]

local function getTextOFCommend(key)
	if key == 'start' then
		return ([[
سلام دوست خوبم!

اسم من %s هست.

من قابلیت های خیلی زیادی دارم و میتونم بهترین مدیر گروه، برای گروه شما باشم.

برخی از قابلیت های من:

• قابلیت حذف تمامی تبلیغاتی که در گروه ارسال می شود.
• قابلیت اخطار به افراد.
• تنظیمات بسیار راحت با کیبورد شیشه ای و کاملا زیبا.
• قابلیت سایلنت کردن کاربر ها (آن کاربر در گروه می باشد اما قادر به چت کردن نمی باشد)
• قابلیت قفل گروه به صورت دستی و خودکار.
• قابلیت فیلترسازی کلمات و سیستم تشخیص سانسور قوی.
• ارسال پیام خوش آمد گویی به صورت پیام، استیکر و گیف با نام کاربر و ...
• قابلیت اخراج و مسدود کردن افراد.
• قابلیت اضافه کردن ادمین به گروه و تغییر دسترسی های ادمین ها.
• قابلیت محدود کردن کاربران.
• قابلیت ساخت دستور جدید و نوشتن پاسخ برای آن ها.
• قابلیت ویژه ضد ربات.
• قابلیت ارسال گزارش به ادمین ها.
• قابلیت مشاهده رویداد های گروه و ثبت آن ها در کانال برای همیشه.
• و کلی قابلیت دیگه همه و همه در این ربات...

برنامه نویسی شده توسط:
[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
		]]):format(bot.first_name)
  elseif key == 'lock_gp' then
    return ([[
💢 قابلیت قفل گروه:

توسط ربات لجندری، به سادگی گروه خود را به 2 صورت دستی و اتوماتیک قفل کنید.

قفل اتوماتیک هرشب سر ساعتی که تعیین کردید فعال می شود و سر ساعتی که تعیین کردید غیر فعال می شود. این عمل هر شب به صورت خودکار انجام می شود.
توسط قفل دستی می توانید هر زمان که دوست داشتید گروه را قفل کنید و هر زمان که دوست داشتید، آن را باز کنید.

`/config`

بعد از ارسال پنل تنظیمات به پیوی شما، کافیست به بخش قفل گروه مراجعه کنید.

توجه:
• بخش قفل اتوماتیک این قابلیت نیاز به حساب ویژه دارد.

%s
    ]]):format(config.channel_link)
  elseif key == 'addadmin' then
    return ([[
👤+ اضافه کردن و تغییر دسترسی های ادمین ها:

در صورتی که شما هم جزو آن دسته از آدم هایی هستید که برای پیدا کردن کاربر مورد نظر و ادمین کردن آن ساعت ها در لیست عضو های گروهتان در جست و جوی آن هستید، توسط این قابلیت به سادگی کاربران خود را ادمین کنید و یا دسترسی های آن ها را تغییر دهید.

`/addadmin [reply|@username|ID|Mention]`
اضافه کردن ادمین و تعیین دسترسی های آن ادمین

مثال:
*/addadmin @username*

`/editadmin [reply|@username|ID|Mention]`
تغییر دسترسی های ادمین مورد نظر و یا برکنار کردن او از مدیریت

نکات مهم:
• ربات حتما باید دسترسی اضافه کردن ادمین را داشته باشد.
• شخصی که از این دستور استفاده می کند حتما باید دسترسی اضافه کردن ادمین را داشته باشد.
• در صورتی که کاربری توسط یک ادمین دیگر به مقام مدیریت رسیده است، ربات نمی تواند دسترسی های آن را تغییر دهد.

`/adminlist` or `لیست ادمین ها`
دریافت لیست ادمین های گروه.

`!cache` or `آپدیت ادمین ها`
به روز رسانی لیست ادمین ها (زمانی کاربرد دارد که شما یک ادمین جدید اضافه کردید یا یک ادمین را برکنار کردید)

%s
    ]]):format(config.channel_link)
  elseif key == 'logchannel' then
    return ([[
🌲 کانال رویداد ها:

توسط این قابلیت، رویداد های مهم گروه خود را در کانالی خصوصی به ثبت برسانید و هر روز آن ها را چک کنید.

`/config`

بعد از ارسال پنل تنظیمات به پیوی، به بخش کانال رویداد ها بروید و ابتدا کانال را ثبت کنید و سپس تنظیمات مورد نظر خودتان را انجام دهید.

%s
    ]]):format(config.channel_link)
	elseif key == 'kickoption' then
		return ([[
🚷 قابلیت اخراج / مسدود کردن افراد:

`/kick [reply|@username|ID]`
اخراج کردن یک شخص در گروه (قابلیت بازگشت با لینک را دارد)
➖➖➖➖➖➖➖➖➖➖
`/ban [reply|@username|ID]`
مسدود کردن یک شخص در گروه (قابلیت بازگشت با لینک را ندارد)
➖➖➖➖➖➖➖➖➖➖
`/tempban [reply]`
مسدود کردن یک کاربر به مدتی معلوم! روی یک کاربر ریپلای کنید و این دستور رو بزنید و مشخص کنید چه مدت مسدود شود!
➖➖➖➖➖➖➖➖➖➖
`/fwdban [reply]`
مسدود کردن یک کاربر با پیام فوروارد شده از اون!
یک پیام از کاربری که میخواهید اون رو مسدود کنید، فوروارد کنید و روی آن ریپلای کنید و این دستور رو بزنید.
➖➖➖➖➖➖➖➖➖➖
`/unban [reply|@username|ID]`
خارج کردن شخص مورد نظر از لیست مسدود شده ها.
➖➖➖➖➖➖➖➖➖➖
`/user [reply|@username|ID]`
مشاهده اطلاعات کاربر مورد نظر در گروه شما.
➖➖➖➖➖➖➖➖➖➖
`/status [reply|@username|ID]`
مشاهده مشخصات کاربر (ادمین هست، از گروه خارج شده، از گروه اخراج شده، دسترسی ها و ...)

%s
		]]):format(config.channel_link)
	elseif key == 'deleteads' then
		return ([[
🔷 قابلیت حذف تبلیغاتی که در گروه شما ارسال می شود:

ربات لجندری توانایی حذف تبلیغاتی که در گروه شما ارسال می شود را دارد!
برای فعال کردن این قابلیت، روش زیر را انجام دهید.

`!config` | `!settings` | `تنظیمات`
هر کدام از دستورات بالا را که بزنید، تنظیمات گروه شما به پیوی شما ارسال خواهد شد.

سپس به بخش تنظیمات حذف تبلیغات مراجعه کنید و گزینه مورد نظرتان را فعال کنیدو.

اگر میخواهید گزینه های بیشتری داشته باشید، می توانید "حساب ویژه" را خریداری کنید.

%s
		]]):format(config.channel_link)
	elseif key == 'whitelinks' then
		return ([[
🔶 قابلیت اضافه کردن لینک های مجاز:

اگر گزینه حذف تبلیغات را فعال کرده باشید، هر نوع لینکی که ارسال شود، حذف خواهد شد.
اگر میخواهید برخی لینک ها حذف نشوند، آن ها را مجاز کنید.

`!wl [link]` | `!withelist [link]`
توسط این دستور لینک های خودتان را مجاز کنید.
• مثال:
*!wl https://telegram.me/joinchat/....*

• شما می توانید با یک بار ارسال این دستور، کلی لینک را مجاز کنید! فقط کافیست بعد از نوشتن لینک اول، یک فاصله بگذارید و لینک بعدی را بنویسید.
➖➖➖➖➖➖➖➖➖➖
`!unwl [link]` | `!unwithelink [link]`
حذف یک یا چند لینک از لیست لینک های مجاز.
➖➖➖➖➖➖➖➖➖➖
`!wl` | `!withelist`
نشان دادن لیست لینک های مجاز.
➖➖➖➖➖➖➖➖➖➖
`!wl -`
حذف تمامی لینک های مجاز شده.

%s
		]]):format(config.channel_link)
	elseif key == 'welcome' then
		return ([[
🔻 قابلیت تغییر متن خوش آمدگویی:

`!welcome [Your text]` or `خوشامد`
نوشتن متن خوش آمدگویی.

مثال:
!welcome سلام خیلی خوش آمدید.
➖➖➖➖➖➖➖➖➖➖
🔸 متغیر ها:
متغیر چیست؟ متغیر ها کلمه هایی هستند که اگر آن ها را در متن خود به کار ببرید، آن ها تغییر خواهند کرد.

• شما می توانید در پیام خوش آمدگویی از متغیر های زیر استفاده کنید.

*$name* نام کاربری شخصی که وارد گروه می شود
*$surname* نام خانوادگی شخصی که وارد گروه می شود
*$id* شناسه کاربری شخصی که وارد گروه می شود
*$title* نام گروهی که کاربر وارد آن می شود
*$username* یوزرنیم شخصی که وارد گروه می شود
*$rules* لینک قوانین گروه
*$force* تعداد شخصی که کاربر باید اضافه کند تا بتواند چت کند (گروه های ویژه)

🔹 مثال:
سلام $name به گروه $title خوش اومدی.
مشخصات شما:
نام کاربری شما: $username
شناسه عددی شما: $id

`لطفا قبل از هرکاری، [قوانین]($rules) گروه را مطالئه کنید.`

🔹 خروجی این پیام:
سلام `علی` به گروه `دوستان باحال` خوش اومدی.
مشخصات شما:
نام کاربری شما: @Username
شناسه کاربری شما: 3122141

لطفا قبل از هرکاری، [قوانین](https://t.me/Legendary_Ch) گروه را مطالئه کنید.
➖➖➖➖➖➖➖➖➖➖
`!welcome [reply][Gif|Sticker]`
شما می توانید به جای پیام خوش امدگویی، از گیف و استیکر استفاده کنید! برای این کار فقط باید روی گیف یا استیکر ریپلای کنید و دستور `welcome/` رو بزنید.
➖➖➖➖➖➖➖➖➖➖
💚 دکمه قوانین در زیر پیام خوش آمدگویی:
ابتدا دستور `config` را در گروه خودتان ارسال کنید.
سپس به بخش تنظیمات اصلی بروید و تیک گزینه "دکمه قوانین" را فعال کنید.
از این پس هرکس وارد گروه شما شود، یک دکمه شیشه ای حاوی لینک قوانین گروه در زیر پیام خوش آمدگویی اعمال خواهد شد.
➖➖➖➖➖➖➖➖➖➖
🗑 قابلیت حذف پیام خوش آمدگویی:
اگر احساس میکنید پیام های خوش آمدگویی گروه شما خیلی زیاد شده است، گزینه "حذف پیام قبلی" را در تنظیمات فعال کنید تا پیام های خوش آمدگویی قبلی، به طور اتوماتیک حذف شوند.

%s
		]]):format(config.channel_link)
	elseif key == 'addcmd' then
		return ([[
⛱ قابلیت اضافه کردن دستور جدید:

توسط این قابلیت، می توانید دستوراتی با # توی گروه خودتان بسازید و در پاسخ به آن، هرچیزی دوست داشتید اضافه کنید.

🔷 ساخت دستور جدید متنی:
توسط این قابلیت، زمانی که کاربر دستور مورد نظر شما را زد، پیامی که تعریف کردید را دربافت خواهد کرد.

• دستور فارسی:
`دستور [#دستور_شما] [متن شما]`

مثال:
`دستور #سلام سلام به روی ماهت :)`

سپس هرکس عبارت #سلام را ارسال کند، متن "سلام به روی ماهت :)" را دریافت خواهد کرد.

• دستور انگلیسی:
`!addword [#Your_Commend] [Your text]`

مثال:
`!addword #read لطفا قوانین گروه را رعایت کنید.`

سپس هرکس عبارت #read رو ارسال کند، متن "لطفا قوانین گروه را رعایت کنید" را دریافت خواهد کرد.
➖➖➖➖➖➖➖➖➖➖
🔶 ساخت دستور جدید و دریافت رسانه:
شما توسط این قابلیت، می توانید در جواب دستوری که ساختید، یک رسانه را انتخاب کنید.

• رسانه ها محدودیت حجمی نخواهند داشت.
• رسانه هایی که پشتیبانی می شوند: عکس، فیلم، استیکر، موسیقی، صدا، فایل و گیف خواهد بود.

• دستور فارسی:
`دستور [#دستور_شما] [ریپلای روی یک رسانه]`

• دستور انگلیسی:
`!addword [#Your_Commend] [reply to a media]`
➖➖➖➖➖➖➖➖➖➖
`حذف دستور [#دستور_شما]`
`!delword [#Your_Commend]`
دستوراتی که ساختید رو به راحتی حذف کنید (می توانید توی یک پیام چند تا دستور با هم حذف کنید.)
➖➖➖➖➖➖➖➖➖➖
`لیست دستورات`
`!wordslist`
دریافت لیست دستوراتی که ساختید.

%s
		]]):format(config.channel_link)
	elseif key == 'rules_getlink' then
		return ([[
✍🏻 قوانین و لینک گروه:

!setrules [Your text] or تنظیم قوانین
قوانین گروه خودتان را ثبت کنید (بعد از یک فاصله از دستور، متن قوانین را بنویسید)

• تنها کسی که دسترسی "تغییرات گروه" را دارد، می تواند قوانین ثبت کند.
➖➖➖➖➖➖➖➖➖➖
`!delrules` or `حذف قوانین`
حذف قوانین گروه.
➖➖➖➖➖➖➖➖➖➖
`!rules` or `قوانین`
دریافت قوانین گروه.
➖➖➖➖➖➖➖➖➖➖
`!setlink [Link]` or `ذخیره لینک`
ذخیره لینک گروه شما (در صورتی که ربات دسترسی دعوت با لینک را داشته باشد، نیازی به استفاده از این دستور نیست)
➖➖➖➖➖➖➖➖➖➖
`!link` or `لینک`
دریافت لینک گروه (ربات باید دسترسی اضافه کردن عضو به گروه را داشته باشد!)
➖➖➖➖➖➖➖➖➖➖
`!change link` or `تغییر لینک`
اگر لینک قبلی کار نمی کند، از این دستور استفاده کنید و لینک گروهتون رو عوض کنید.
➖➖➖➖➖➖➖➖➖➖
`!id` or `آیدی`
گرفتن شناسه گروه یا شناسه کاربر.

%s
		]]):format(config.channel_link)
	elseif key == 'change_info' then
		return ([[
🔻 تغییر محتویات گروه:

درصورتی که شما دسترسی تغییر محتویات گروه را داشته باشید، می توانید محتویات گروه را به سادگی تغییر دهید.

`!setphoto` or `تنظیم پروفایل`
با ریپلای کردن روی یک عکس و نوشتن دستور بالا، به سادگی آن عکس را روی عکس گروه خودتان بذارید.
➖➖➖➖➖➖➖➖➖➖
`!delphoto` or `حذف پروفایل`
حذف عکس گروه.
➖➖➖➖➖➖➖➖➖➖
`!setname [Name]` or `تنظیم نام`
تغییر نام گروه (نام جدید را با یک فاصله بعد از دستور بنویسید)
➖➖➖➖➖➖➖➖➖➖
`!setdes [Description]` or `تنظیم توضیحات`
نوشتن توضیحات گروه توسط ربات! بعد از نوشتن دستور، یک فاصله بگذارید و متن مورد نظر خودتان را بنویسید.
➖➖➖➖➖➖➖➖➖➖
`!pin` or `سنجاق`
با نوشتن این دستور و ریپلای روی یک پیام، آن پیام را سنجاق کنید.
➖➖➖➖➖➖➖➖➖➖
`!unpin` or `حذف سنجاق`
اگر پیامی را سنجاق کرده باشید، از حالت سنجاق خارج می شود.
➖➖➖➖➖➖➖➖➖➖
`!active` or `فعال`
در صورتی که میخواهید تعداد اعضای فعال در روزهای اخیر را مشاهده کنید از این دستور استفاده کنید.
%s
		]]):format(config.channel_link)
	elseif key == 'report' then
		return ([[
🗣 قابلیت گزارش:

`!config`
ابتدا در دکمه فهرست گزینه ریپورت را روی ✅ قرار دهید. (به صورت پیشفرض فعال می باشد)

*@admin* یا *!report*
هر کاربری روی پیام یک کاربر دیگر ریپلای کند و دستور بالا را ارسال کند، پیام برای تمام ادمین ها ارسال می شود. (به شرطی که قبلا ربات رو استارت کرده باشند)

• ارسال تمام مشخصات فرستنده گزارش.
• ارسال تمام مشخصات گزارش شده.
• ارسال پیامی که گزارش شده است.
• فرستادن پیامی حاوی مطلب "گزارش شما به دست *X* ادمین رسید.".

`!reportflood [x/y]`
با فرستادن دستور بالا در گروه خود، می توانید تعیین کنید چند گزارش در چند دقیقه ارسال شود! مثلا اگر کاربر ها پشت سر هم گزارش میفرستند و باعث بهم ریختن گروه می شوند، شما توسط این قابلیت می توانید تعیین کنید که مثلا در 20 دقیقه فقط 5 گزارش ارسال شود!
نمونه دستور:
`/reportflood 20/5`

%s
		]]):format(config.channel_link)
	elseif key == 'antiflood' then
		return ([[
⚜️ قابلیت حساسیت پیام در گروه:

`!config`
با زدن روی دکمه حساسیت پیام، می توانید حساسیت پیام را در خودتون رو مدیریت کنید.

گزینه هایی که روی ✅ قرار دارند توسط ربات "حساب" می شوند (یعنی اگر گزینه ای را روی ☑️ قرار بدید ربات آنرا حساسیت پیام حساب نخواهد کرد)

🔷 شما می توانید تایین کنید فردی که پیام پشت سر هم میفرستد، اخراج، مسدود یا سایلنت شود!

• اگر کاربر اخراج شود، می تواند با لینک به گروه بازگردد.
• اگر کاربر مسدود شود، دیگر نمی تواند به گروه برگردد مگر آنکه توسط یک ادمین unban/ شود.
• اگر یک کاربر سایلنت شود، در گروه می تواند حضور داشته باشد اما دیگر توانایی چت کردن نخواهد داشت! شما می توانید آن کاربر را با دستور unsilent/، از حالت سایلنت شده خارج کنید.

اطلاعات بیشتر درباره این قابلیت را می توانید در راهنمای همان قابلیت مطالئه کنید.

%s
		]]):format(config.channel_link)
	elseif key == 'warn' then
		return ([[
💖 قابلیت اخطار دادن به افراد:

`!config`
با ارسال این دستور در گروه خودتان و رفتن به بخش تنظیمات اصلی، می توانید تعداد اخطار ها را کم یا زیاد کنید.

➖➖➖➖➖➖➖➖➖➖
`!warn [reason]` or `اخطار`
اخطار دادن به کاربران (هم با دلیل هم بدون دلیل)
➖➖➖➖➖➖➖➖➖➖
`!nowarn` or `حذف اخطار`
پاک کردن اخطار های یک کاربر.
➖➖➖➖➖➖➖➖➖➖
`!cleanwarns` or `پاکسازی اخطار ها`
حذف تمامی اخطار های کاربران
➖➖➖➖➖➖➖➖➖➖
`!user [reply|@username|ID|mention]`
توسط این دستور می توانید مشاهده کنید هر کاربر چقد اخطار دارد.
➖➖➖➖➖➖➖➖➖➖
`!ping`
توسط این دستور می توانید چک کنید ربات آنلاین هست یا خیر.

%s
		]]):format(config.channel_link)
	elseif key == 'antibot' then
		return ([[
🥁 قابلیت پیشرفته ضد ربات:

`!config`
با ارسال این دستور و رفتن به بخش تنظیمات اصلی، می توانید ضد ربات را فعال کنید.

• در صورتی که یک ادمین ربات اضافه کند، ربات اضافه شده اخراج نخواهد شد.
• زمانی که ربات اضافه شده اخراج شود، دکمه شیشه ای را مشاهده خواهید کرد به نام "مسدود کردن کاربر" !
• در صورتی که روی دکمه بزنید، اگر ادمین باشید و دسترسی حذف اعضا را داشته باشید، آن کاربری که ربات را اضافه کرده است اخراج خواهد شد.

%s
		]]):format(config.channel_link)
	elseif key == 'about' then
    local version, lastupdateEn, lastupdateFa = u.version_info()
		return ([[
🔷 ربات مدیریت گروه لجندری، ارائه ای متفاوت از تیم لجندری.

🔸 نسخه ربات: `%s`
🔹 آخرین آپدیت در تاریخ: `%s`
🔻 Last update: `%s`

• با تشکر از دوستان عزیزی که به ما در ساخت و آپدیت ربات های لجندری کمک کردند:
Saeed, Zahra Sadat, Nicholas Guriev, Behrad, Shayan, Sajjad Momen, Seyed, SiNa, Miroo, Mehrdad, Aras, Pouria, Mahdi, Hamid, Haniyeh, Amir Mohammad

و همچنین تشکر ویژه از Riccardo بابت سورس Group Butler

🔸 تمامی حقوق این ربات متعلق به تیم لجندری می باشد و هرگونه کپی برداری از متن ها، از چیدمان ربات و پروفایل های ربات، کاملا غیر مجاز و دور از انسانیت می باشد.
در صورتی که میخواهید از برخی متن ها و چیدمان یا قابلیت های ربات استفاده کنید، لطفا از نام و منبع لجندری استفاده کنید.
• *Copyright © by* [Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q) *2016 - 2020*
		]]):format(version, lastupdateFa, lastupdateEn)
	elseif key == 'help_first' then
		return ([[
💖 بخش راهنمای ربات:

🔸 کار با ربات لجندری بسیار ساده می باشد اما با این حساب، اگر باز هم در کار کردن با ربات مشکلی دارید، می توانید از راهنمای آن استفاده کنید.

• راه اندازی ربات: در صورتی که نمی دانید چگونه ربات رو نصب کنید، از راهنمای این بخش استفاده کنید.
• دستورات و قابلیت های ربات: در این بخش می توانید «تمامی دستورات ربات» را مشاهده کنید و در صورتی که به مشکلی برخوردید، به این بخش مراجعه کنید.

%s
		]]):format(config.channel_link)
	elseif key == 'run_bot' then
		return ([[
♨️ راهنمای راه اندازی ربات:

🔸 راه اندازی ربات یکی از ساده ترین کار های ممکن می باشد! با این حال اگر شما مشکلی دارید، می توانید از راهنمای زیر استفاده کنید.

1. ربات را از طریق [این لینک](https://telegram.me/%s?startgroup=new) به گروه خودتان اضافه کنید. (اگر گروه شما پیدا نشد، آن را جستجو کنید. در صورتی که نتوانستید آن را جستجو کنید، به قسمت افزودن عضو گروه خود برید و یوزرنیم ربات را جستجو کنید و ربات را اضافه کنید)
2. بعد از این که ربات را اضافه کردید، آن را مدیر گروه خود کنید و دسترسی کامل به آن دهید (دسترسی آخر یا همون اضافه کردن ادمین اجباری نیست)
3. سپس برای تنظیم ربات، عبارت "تنظیمات" یا "Settings" را در گروه خود ارسال کنید.
4. و در آخر تنظیماتی به پیام خصوصی شما ارسال خواهد شد که با آن می توانید به سادگی ربات را تنظیم کنید :)

%s
		]]):format(bot.username, config.channel_link)
	elseif key == 'commends' then
		return ([[
🔶 دستورات ربات لجندری:

🔹 در این بخش می توانید تمام دستورات و قابلیت های ربات را مشاهده کنید. به نکات زیر توجه کنید:

• تمامی دستورات هم می توانند با "/!#" شروع شوند و هم می توانند بدون این ها نوشته شوند! مانند:
`/settings` - `!settings` - `#settings` - `Settings`

• در کنار برخی دستورات، کلماتی مانند
*[reply], [@username], [ID], [Mention]*
وجود دارد!
این ها به معنی این نیست که شما هم در کنار دستورتان هم از این کلمات استفاده کنید.

🔻 معنی برخی این کلمات:
مثلا در راهنمای "اخراج و مسدود"، شما دستور زیر را می بینید:
`!ban [reply|@username|ID]`
خب معنی این چیست؟ 🤔

• *[reply]*
این کلمه به معنی ریپلای کردن روی پیام یک کاربر و نوشتن آن دستور می باشد!

• *[@username]*
این کلمه به معنی نوشتن نام کاربری آن کاربر مورد نظر شما بعد از نوشتن دستور می باشد! مانند:
`/ban %s`

• *[ID]*
این کلمه به معنی شناسه عددی فرد مورد نظر شما می باشد! مانند:
`/ban %s`
(شناسه عددی کاربر را می توانید با ریپلای کردن روی پیام آن و نوشتن /id پیدا کنید.)

🚫 شما نباید بعد از نوشتن دستور این محتویات را داخل کروشه "*[]*" بگذارید.

%s
		]]):format(bot.id, bot.id, config.channel_link)
	elseif key == 'support' then
		return ([[
💜 بخش پشتیبانی ربات:

🔻 در صورتی که نیاز به پشتیبانی دارید، می توانید به سوپرگروه پشتیبانی بپیوندید و سوال خودتان را مطرح کنید؛ در صورتی که تیم پشتیبانی آنلاین باشند، حتما پاسخ شما را خواهند داد.

• زمانی که وارد گروه شدید، قوانین را مطالئه کنید.
• از ارسال هرگونه تبلیغات خودداری کنید.
• هر چقد با ادب بیشتری سوال خودتان را بپرسید، بهتر و دقیق تر پاسخ دریافت خواهید کرد :)

[Legendary Ch](https://telegram.me/joinchat/AAAAAEIMxObc7_gBcu-13Q)
		]])
	elseif key == 'filter' then
		return ([[
🍷 بخش فیلتر کلمات

🔸 از این پس می توانید به راحتی کلمات مورد نظرتان را فیلتر کنید و هرکس از آن کلمات در داخل جمله خود استفاده کرد، متن آن کاربر حذف خواهد شد.

`!config`
ابتدا این دستور را در گروه خودتان ارسال کنید؛ سپس به بخش تنظیمات فیلتر رفته و در قسمت فیلتر کلمات، می توانید کلمات مورد نظرتان را از داخل "پیوی" ربات فیلتر کنید.

%s
		]]):format(config.channel_link)
	elseif key == 'silent' then
		return ([[
🚫 ویژگی سایلنت کردن کاربر ها

🔥 در صورتی که قصد دارید تا یک کاربر را سایلنت کنید تا اون کاربر نتواند در گروه چت کند، می توانید از ویژگی زیر استفاده کنید.

`!silent [reply][(1-12)mo]`
سایلنت کردن یک کاربر به مدت چند ماه!
🔹 مثال دستور:
ابتدا روی پیام یک کاربری ریپلای می کنید؛ سپس دستور زیر را می نویسید:
*/silent 8mo*
سپس کاربر مورد نظر شما به اندازه 8 ماه، سایلنت می شود و بعد از 8 ماه به صورت اتوماتیک از لیست سایلنت شده ها خارج می شود.

• شما نمی توانید کاربری را بیشتر از *12* ماه سایلنت کنید.
• عدد شما باید بین 1 تا 12 باشد.
➖➖➖➖➖➖➖➖➖➖
`!silent [reply][(1-48)w]`
سایلنت کردن یک کاربر به مدت چند هفته!
🔸 مثال دستور:
ابتدا روی پیام کاربر ریپلای کرده و دستور زیر را بنویسید:
*/silent 15w*
بعد از ارسال این دستور، کاربر مورد نظر به مدت 15 هفته نمی تواند چت کند.

• شما نمی توانید کاربری را بیشتر از *48* هفته سایلنت کنید.
• عدد شما باید بین 1 تا 48 باشد.
➖➖➖➖➖➖➖➖➖➖
`!silent [reply][(1-360)d]`
سایلنت کردن یک کاربر به مدت چند روز!
🔹 مثال دستور:
روی پیام کاربر مورد نظر ریپلای کنید و دستور زیر را بنویسید:
*/silent 30d*
و بعد از ارسال این دستور، کاربر مورد نظر به مدت 30 روز توانایی چت کردن ندارد.

• شما نمی توانید کسی را بیشتر از *360* روز سایلنت کنید.
• عدد باید بین 1 تا 360 باشد.
➖➖➖➖➖➖➖➖➖➖
`!silent [reply][(1-8640)h]`
سایلنت کردن کاربر به مدت چند ساعت!
🔸 مثال دستور:
روی پیام کاربر مورد نظر ریپلای کنید و دستور زیر را بنویسید:
*/silent 48h*
سپس کاربر مورد نظر شما به مدت 48 ساعت سایلنت می شود.

• شما نمی توانید کسی را بیشتر از *8640* ساعت (1 سال) سایلنت کنید.
• عدد شما باید بین 1 تا 8640 باشد.
➖➖➖➖➖➖➖➖➖➖
`!silent [reply][forever]`
سایلنت کردن یک کاربر برای همیشه!
🔹 مثال دستور:
بعد از ریپلای روی پیام کاربر مورد نظر، دستور زیر را بنویسید:
*/silent forever*

_نکته: شما نمی توانید ادمین ها را سایلنت کنید._
➖➖➖➖➖➖➖➖➖➖
`!unsilent [reply|@username|ID|mention]`
خارج کردن کاربر مورد نظر از لیست سایلنت شده ها با ریپلای روی پیام آن ها یا استفاده از یوزرنیم، آیدی یا منشن کردن آن ها.

• این دستور برای تمام حساب ها آزاد می باشد.
➖➖➖➖➖➖➖➖➖➖
`!silentlist`
مشاهده کاربر های سایلنت شده توسط دستور silent/

%s
		]]):format(config.channel_link)
  	elseif key == 'clean' then
    	return ([[
🔥 قابلیت پاکسازی:

• نکته: استفاده از این قابلیت نیاز به حساب ویژه نیاز دارد.

برای استفاده از قابلیت پاکسازی، ابتدا "تنظیمات" را در گروه خود ارسال کنید و به بخش پاکسازی رفته و ربات پاکسازی را به گروه خود اضافه کنید.

`!clean [num|chat]`
حذف تعدادی از پیام ها یا حذف تعداد انبوهی از پیام ها!

🔹 مثال:

`!clean 30`
این دستور 30 پیام اخیر گروه را حذف می کند!

`!clean chat`
این دستور تعداد زیادی پیام را هم زمان حذف می کند (بستگی به گروه و تعداد چت ها دارد)

%s
		]]):format(config.channel_link)
	elseif key == 'porno' then
		return ([[
🔞 تشخیص محتوای پورنوگرافی:
• *توجه: این قابلیت نیاز به حساب ویژه دارد!*

🔻 شما می توانید به سادگی و با یک دکمه، از ارسال استیکر و عکس پورن به گروه خود جلوگیری کنید.

`!config`
ابتدا این دستور را ارسال کنید و سپس به بخش تنظیمات پورنوگرافی بروید و آن را فعال کنید.

🔸 توضیحات مهم:
برای مدیریت راحت تر شما عزیزان، این بخش را به 4 سطح تقسیم بندی کرده ایم.

• سطح 1 : در صورتی که روی این سطح تنظیم کنید، عکس و استیکر پورن پاک خواهد شد.
• سطح 2 (پیشنهاد ما) : در صورت تنظیم روی سطح 2، درصد سخت گیری ربات بالاتر می رود و ممکن است مواردی که شبیه به پورن هستند هم حذف شوند.
• سطح 3 : این سطح علاوه بر موارد بالا، احتمال حذف عکس هایی با پوشش تقریبا برهنه (بیکینی یا لباس شنا) و مواردی شبیه به این را دارد.
• سطح 4 (پیشنهاد نمی شود) : این سطح سخت گیر ترین حالت ربات می باشد. علاوه بر موارد بالا، احتمال حذف پوشش هایی با برهنگی کم و مواردی شبیه به این وجود دارد.

%s
		]]):format(config.channel_link)
	elseif key == 'editname' then
		return ([[
♨️ تشخیص تغییر نام و یوزرنیم
• *توجه: این قابلیت تنها برای حساب های ویژه فعال می باشد.*

همیشه کاربران می توانستند با تغییر نام و نام کاربری (یوزرنیم) خود، هویت واقعی خود را مخفی نگه دارند؛ اما توسط ویژگی جدید ربات های لجندری، دیگر انجام این کار ممکن نیست!

`!config`
پس از ارسال این دستور، به بخش "تنظیمات اولیه" بروید و گزینه "تغییر مشخصات" را فعال کنید.

همچنین می توانید توسط دستور user، نام های قبلی کاربر را مشاهده کنید.

%s
		]]):format(config.channel_link)
	elseif key == 'freeusers' then
		return ([[
🕊 کاربران آزاد:
تا حالا شده که بخواهید ربات به یک کاربر گیر ندهد و پیام های آن کاربر حذف نشود؟

اگر قبلا این مورد برای شما پیش آمده است، دیگر نیازی نیست آن کاربر را ادمین کنید! توسط این ویژگی، به سادگی کاربر را به لیست "کاربران آزاد" اضافه کنید و ربات دیگر پیام آن کاربر را حذف نمی کند :)

`!setfree [reply|ID|username|mention]`
اضافه کردن یک کاربر به لیست آزاد.

`!remfree [reply|ID|username|mention]`
حذف یک کاربر از لیست آزاد.

`!freelist`
مشاهده لیست کاربران آزاد.

%s
		]]):format(config.channel_link)
	elseif key == 'forceadd' then
		return ([[
🔸 اد اجباری
اگر جزو آن دسته از افرادی هستید که علاقه دارید هرکس به گروه شما ملحق شد بلافاصله چند نفر اضافه کند تا بتواند چت کند، این قابلیت مخصوص شما می باشد.

کاربری که جدید اضافه می شود، باید اون تعداد عضوی که شما از قبل تعیین کردید را اضافه کند تا بتواند چت کند. همچنین این قانون شامل عضو های جدیدی که توسط اون کاربر اضافه می شوند هم می شود.

• توجه: لطفا در صورتی که میخواهید از این قابلیت استفاده کنید حتما در پیام خوش آمدگویی بنویسید که کاربران باید چه مقدار عضو اضافه کنند تا بتوانند چت کنند. می توانید از متغیر $force استفاده کنید

`!setadd [on|off]`
`اد اجباری [روشن|خاموش]`
توسط این دستور می توانید اد اجباری را فعال/غیرفعال کنید.

`!setaddnumber [number]`
`تنظیم اجباری [عدد]`
با این دستور می توانید تعیین کنید کاربر هایی که جوین می شوند چه مقدار عضو اضافه کنند تا بتوانند چت کنند.

%s
		]]):format(config.channel_link)
	end
end
------------------------------- [Start keyboard] -------------------------------
local function startKeyboard()
	local keyboard = {}
	keyboard.inline_keyboard = {
		{{text = ("راهنمای کامل 📚"), callback_data = 'legendary:help_first'}, {text = ("پشتیبانی 🚀"), callback_data = 'legendary:support'}},
		{{text = ("راهنماهای جانبی ⁉️"), url = 'https://t.me/LFHelp'}},
		{{text = ("درباره ما🎗"), callback_data = 'legendary:about'}}
	}
	return keyboard
end
-------------------------------- [Help keyboard] -------------------------------
local function helpFirstKeyboard()
	local keyboard = {}
	keyboard.inline_keyboard = {
		{{text = ("راه اندازی ربات 💠"), callback_data = 'legendary:run_bot'}},
		{{text = ("دستورات و قابلیت های ربات 📈"), callback_data = 'legendary:commends'}},
		{{text = ("برگشت 🔙"), callback_data = 'legendary:back_key'}}
	}
	return keyboard
end
-------------------------------- [Help commends] -------------------------------
local function helpCommend()
	local keyboard = {}
	keyboard.keyboard = {
		{{text = '• پورنوگرافی'}, {text = '• تشخیص تغییر نام'}},
		{{text = '• کاربران آزاد'}, {text = '• اد اجباری'}},
		{{text = '• قفل گروه'}, {text = '• پاکسازی'}},
		{{text = '• اضافه کردن ادمین'}, {text = '• کانال رویداد'}},
		{{text = '• اخراج و مسدود'}, {text = '• حذف تبلیغات'}},
		{{text = '• فیلتر کلمات'}, {text = '• خوش آمدگویی'}},
		{{text = '• اضافه کردن دستور'}, {text = '• حساسیت پیام'}},
		{{text = '• تعیین قوانین/دریافت لینک'}, {text = '• تغییر اطلاعات گروه'}},
		{{text = '• اخطار دادن'}, {text = '• ضد ربات'}},
		{{text = '• بی صدا کردن کاربر'}},
		{{text = 'برگشت 🔙'}}
	}
	keyboard.resize_keyboard = true
	keyboard.one_time_keyboard = true
	return keyboard
end
------------------------------- [Back to menu] ---------------------------------
local function backKeyboard(back_value)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{{text = 'برگشت 🔙', callback_data = 'legendary:'..back_value}}
	}
	return keyboard
end
--------------------------------------------------------------------------------
function plugin.onTextMessage(msg, blocks)
	if msg.chat.type == 'private' then
		-------------------------------------
		local text
		if blocks[1] == 'اخراج و مسدود' then
			text = getTextOFCommend('kickoption')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'قفل گروه' then
			text = getTextOFCommend('lock_gp')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'اضافه کردن ادمین' then
			text = getTextOFCommend('addadmin')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'کانال رویداد' then
			text = getTextOFCommend('logchannel')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'حذف تبلیغات' then
			text = getTextOFCommend('deleteads')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'خوش آمدگویی' then
			text = getTextOFCommend('welcome')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'اضافه کردن دستور' then
			text = getTextOFCommend('addcmd')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'تعیین قوانین/دریافت لینک' then
			text = getTextOFCommend('rules_getlink')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'تغییر اطلاعات گروه' then
			text = getTextOFCommend('change_info')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'حساسیت پیام' then
			text = getTextOFCommend('antiflood')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'گزارش یک گروه' then
			text = getTextOFCommend('reportgp')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'اخطار دادن' then
			text = getTextOFCommend('warn')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'ضد ربات' then
			text = getTextOFCommend('antibot')
			api.sendReply(msg, text, true)
		--------------------------------------
		elseif blocks[1] == 'فیلتر کلمات' then
			text = getTextOFCommend('filter')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'بی صدا کردن کاربر' then
			text = getTextOFCommend('silent')
			api.sendReply(msg, text, true)
    	elseif blocks[1] == 'پاکسازی' then
      		text = getTextOFCommend('clean')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'پورنوگرافی' then
			text = getTextOFCommend('porno')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'تشخیص تغییر نام' then
			text = getTextOFCommend('editname')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'اد اجباری' then
			text = getTextOFCommend('forceadd')
			api.sendReply(msg, text, true)
		elseif blocks[1] == 'کاربران آزاد' then
			text = getTextOFCommend('freeusers')
			api.sendReply(msg, text, true)
		end
		-------------------------------------
		if blocks[1] == 'start' then
			db:sadd('legendary:users', msg.from.id)
			local text, keyboard = u.join_channel(msg.from.id, 'legendary:start')
			if text and keyboard then
        		api.sendReply(msg, text, true, keyboard)
			else
       			api.sendReply(msg, getTextOFCommend('start'), true, startKeyboard())
      		end
		end
		-------------------------------------
		if blocks[1] == 'برگشت' then
			keyboard = {remove_keyboard = true}
			text = getTextOFCommend('start')
			api.sendReply(msg, 'در حال برگشت...', true, keyboard)
			api.sendMessage(msg.chat.id, text, true, startKeyboard())
		end
		------------------------------------
		if blocks[1] == 'help' then
			local res = api.sendMessage(msg.from.id, getTextOFCommend('help_first'), true, helpFirstKeyboard())
			if not res then
				u.sendStartMe(msg)
			end
		end
	end
end

function plugin.onCallbackQuery(msg, blocks)
	local text, answer, status, keyboard
  	---------------------------------
  	if blocks[1] == 'start' then
    	local text, keyboard = u.join_channel(msg.from.id, 'legendary:start')
    	if text and keyboard then
      		api.answerCallbackQuery(msg.cb_id, 'شما در کانال عضو نیستید!', true)
      		return
    	else
			api.answerCallbackQuery(msg.cb_id, 'تایید شد ✅')
			api.editMessageText(msg.from.id, msg.message_id, getTextOFCommend('start'), true, startKeyboard())
			return
    	end
  	end
	---------------------------------
	if blocks[1] == 'help_first' then
		text = getTextOFCommend('help_first')
		keyboard = helpFirstKeyboard()
		answer = 'بخش راهنمای کامل ربات ...'
	---------------------------------
	elseif blocks[1] == 'run_bot' then
		text = getTextOFCommend('run_bot'):format(bot.username)
		answer = 'چطور ربات را به گروهم ببرم؟ 🤔'
		keyboard = backKeyboard('help_first')
	---------------------------------
	elseif blocks[1] == 'commends' then
		text = 'در حال ارسال راهنما...'
		answer = 'بخش راهنمای ربات!\nلطفا قبل از ارسال دکمه ها، متن راهنما را بخوانید.'
		status = true
		api.sendMessage(msg.chat.id, getTextOFCommend('commends'):format('@'..bot.username, bot.id), true, helpCommend())
	---------------------------------
	elseif blocks[1] == 'support' then
		--[[text = getTextOFCommend('support')
		answer = 'قبل از وارد شدن به گروه، به نکات زیر توجه کنید :)'
		local data = u.loadFile(config.info_path) or {}
		local link = data['support_info']['chat_link']
		keyboard = {inline_keyboard = {{{text = 'ورود به گروه پشتیبانی 🍷', url = link}}, {{text = ("برگشت 🔙"), callback_data = 'legendary:back_key'}}}}]]
	---------------------------------
	elseif blocks[1] == 'back_key' then
		answer = 'برگشت به منوی اصلی...'
		text = getTextOFCommend('start')
		keyboard = startKeyboard()
	---------------------------------
	elseif blocks[1] == 'about' then
		answer = 'ربات لجندری، بهترین مدیر گروه ☺️'
		text = getTextOFCommend('about')
		keyboard = backKeyboard('back_key')
	---------------------------------
	end
	api.answerCallbackQuery(msg.cb_id, answer, status)
	api.editMessageText(msg.chat.id, msg.message_id, text, true, keyboard)
end

plugin.triggers = {
	onTextMessage = {
		'^/(start)$',
		config.cmd..'(help)$',
		config.cmd..'(about)$',
		'^/start :(help)$',
		'^/start :(adminbot)$',
		'^• (.*)$',
		'^(برگشت) 🔙$',
		---------------------------
		'^([Hh]elp)$',
		'^([Aa]bout)$'
	},
	onCallbackQuery = {
		'^###cb:legendary:(.*)$',
		'^###cb:fromhelp:(peyman)$'
	}
}

return plugin