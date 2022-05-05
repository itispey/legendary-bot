-- Editing this file directly is now highly disencouraged. You should instead use environment variables. This new method is a WIP, so if you need to change something which doesn't have a env var, you are encouraged to open an issue or a PR
local json = require 'dkjson'

local _M =
{
	-- Getting updates
	telegram =
	{
		token = assert(os.getenv('TG_TOKEN'), 'You must export $TG_TOKEN with your Telegram Bot API token'),
		allowed_updates = os.getenv('TG_UPDATES') or {'message', 'edited_message', 'callback_query'},
		polling =
		{
			limit = os.getenv('TG_POLLING_LIMIT'), -- Not implemented
			timeout = os.getenv('TG_POLLING_TIMEOUT') -- Not implemented
		},
		webhook = -- Not implemented
		{
			url = os.getenv('TG_WEBHOOK_URL'),
			certificate = os.getenv('TG_WEBHOOK_CERT'),
			max_connections = os.getenv('TG_WEBHOOK_MAX_CON')
		}
	},

	-- Data
	postgres = -- Not implemented
	{
		host = os.getenv('POSTGRES_HOST') or 'localhost',
		port = os.getenv('POSTGRES_PORT') or 5432,
		user = os.getenv('POSTGRES_USER') or 'postgres',
		password = os.getenv('POSTGRES_PASS') or 'postgres',
		database = os.getenv('POSTGRES_DB') or 'groupbutler',
	},
	redis =
	{
		host = os.getenv('REDIS_HOST') or 'localhost',
		port = os.getenv('REDIS_PORT') or 6379,
		db = os.getenv('REDIS_DB') or 0
	},

	-- Aesthetic
	lang = os.getenv('DEFAULT_LANG') or 'en',
	human_readable_version = os.getenv('VERSION') or 'unknown',
	channel = os.getenv('CHANNEL') or '@Legendary_Ch',
	--source_code = os.getenv('SOURCE') or 'https://github.com/RememberTheAir/GroupButler/tree/beta',
	--help_group = os.getenv('HELP_GROUP') or 'telegram.me/GBgroups',

	-- Core
	log =
	{
		chat = assert(os.getenv('LOG_CHAT'), 'You must export $LOG_CHAT with the numerical ID of the log chat'),
		admin = assert(os.getenv('LOG_ADMIN'), 'You must export $LOG_ADMIN with your Telegram ID'),
		stats = os.getenv('LOG_STATS')
	},
	--superadmins = assert(json.decode(os.getenv('330287055', '252449061')),
		--'You must export $SUPERADMINS with a JSON array containing at least your Telegram ID'),
	superadmins = {725233206, 292528701},
	cmd = '^[/!#]',
	-----------------------------------------------------------
	version = '5.0.7.1',
	lastupdateEn = 'Wednesday, June 21, 2017 (17:03)',
	lastupdateFa = 'چهارشنبه، 17 آبان 1396 (22:38)',
	channel_id = -1001108133094,
	forwarder = 449739989,
	ip = '94.130.127.210',
	free_bots = {353423647, 322365471},
	backup_ch = -1001062962345,
	team_gp = -1001128531760,
	support_gp = -1001132670630,
	payment_ch = -1001351328364,
	-----------------------------------------------------------
	json_path = '/home/beta/Legend/data/vip_log.json',
	info_path = '/home/beta/Legend/data/info.json',
	log_path = '/home/beta/Legend/data/log/',
	-----------------------------------------------------------
	bots = {
		['@LegendaryAlphaBot'] = 442013781,
		['@LegendaryBetaBot'] = 370176483,
		['@LegendaryDeltaBot'] = 395406961,
		['@LegendaryOmegaBot'] = 415876216,
		['@LegendarySigmaBot'] = 397779733
	},
	-----------------------------------------------------------
	cli_bots = {
		['@LegendaryAlpha'] = 508708834,
		['@LegendaryBeta'] = 482687690,
		['@LegendaryDelta'] = 549443383,
		['@LegendaryOmega'] = 479543911,
		['@LegendarySigma'] = 514043650
	},
	-----------------------------------------------------------
	bot_settings = {
		cache_time = {
			adminlist = 18000,
			alert_help = 3600,
			chat_titles = 18000
		},
		report = {
			duration = 1200,
			times_allowed = 2
		},
		notify_bug = false,
		log_api_errors = true,
		stream_commands = true,
		admin_mode = false
	},
	plugins = {
		'onmessage',
		--'antispam',
		'base',
		'newadmin',
		--'addcli',
		--'backup',
		'banhammer',
		'configure',
		'floodmanager',
		'legendary',
		'links',
		'logchannel',
		--'mediasettings',
		'panel',
		--'badwords',
		--'vipsettings',
		'checks',
		'silent',
		'filter',
		'autolock',
		--'clean',
		'menu',
		'manage',
		--'private_settings',
		'report',
		'rules',
		'service',
		'users',
		'warn',
		'welcome',
		'admin',
		'extra',
	},
	new_settings = {
		--[[['media'] = {
			['text'] = 'off',
			['photo'] = 'off',
			['video'] = 'off',
			['gif'] = 'off',
			['voice'] = 'off',
			['audio'] = 'off',
			['document'] = 'off',
			['sticker'] = 'off',
			['location'] = 'off',
			['contact'] = 'off',
			['game'] = 'off',
		},]]
		['public'] = {
			['Link'] = 'off',
			['Fwduser'] = 'off',
			['Persian'] = 'off',
			['English'] = 'off',
			['Mention'] = 'off',
		},
		['vip'] = {
			['Fwdchannel'] = 'off',
			['Username'] = 'off',
			['Hashtag'] = 'off',
			['Webpage'] = 'off',
			['Tgservice'] = 'off',
		},
	},
	chat_settings = {
		['settings'] = {
			['Welcome'] = 'off',
			['Rules'] = 'off',
			['Extra'] = 'off',
			['Reports'] = 'off',
			['Welbut'] = 'off',
			['Weldelchain'] = 'off',
			['Antibot'] = 'off'
		},
		--[[['antispam'] = {
			['links'] = 'alwd',
			['forwards'] = 'alwd',
			['warns'] = 2,
			['action'] = 'mute'
		},]]
		['flood'] = {
			['MaxFlood'] = 5,
			['ActionFlood'] = 'mute'
		},
		['char'] = {
			['Arab'] = 'allowed', --'kick'/'ban'
			['Rtl'] = 'allowed'
		},
		['badword_warn'] = {
			['type'] = 'ban',
			['bad_type'] = 'del',
			['warn'] = 2
		},
		['badword_key'] = {
			['bad'] = 'ok'
		},
		['floodexceptions'] = {
			['text'] = 'no',
			['photo'] = 'no', -- image
			['forward'] = 'no',
			['video'] = 'no',
			['sticker'] = 'no',
			['gif'] = 'no',
		},
		['warnsettings'] = {
			['type'] = 'mute',
			['mediatype'] = 'mute',
			['max'] = 3,
			['mediamax'] = 2
		},
		['welcome'] = {
			['type'] = 'no',
			['content'] = 'no'
		},
		['media'] = {
			['photo'] = 'ok', --'notok' | image
			['audio'] = 'ok',
			['video'] = 'ok',
			['video_note'] = 'ok',
			['sticker'] = 'ok',
			['gif'] = 'ok',
			['voice'] = 'ok',
			['contact'] = 'ok',
			['document'] = 'ok', -- file
			['link'] = 'ok',
			['game'] = 'ok',
			['location'] = 'ok'
		},
		['tolog'] = {
			['ban'] = 'no',
			['kick'] = 'no',
			['unban'] = 'no',
			['tempban'] = 'no',
			['report'] = 'no',
			['warn'] = 'no',
			['nowarn'] = 'no',
			--['mediawarn'] = 'no',
			--['spamwarn'] = 'no',
			['silent'] = 'no',
			['flood'] = 'no',
			['new_chat_member'] = 'no',
			['new_chat_photo'] = 'no',
			['delete_chat_photo'] = 'no',
			['new_chat_title'] = 'no',
			['pinned_message'] = 'no'
		},
		['change_per'] = {
			['can_change_info'] = 'true',
			['can_delete_messages'] = 'true',
			['can_invite_users'] = 'true',
			['can_pin_messages'] = 'true',
			['can_promote_members'] = 'false',
			['can_restrict_members'] = 'true'
		},
		['defpermduration'] = {
			['timeframe'] = 'd',
			['duration'] = 1
		},
	},
	private_settings = {
		rules_on_join = 'off',
		reports = 'off'
	},
	chat_hashes = {'info', 'welcome', 'links', 'warns', 'mediawarn', 'spamwarns', 'report', 'lock_media', 'public_settings', 'vip'}, -- 'extra', 'defpermissions', 'defpermduration'
	chat_sets = {'whitelist'},--, 'mods'},
	bot_keys = {
		d3 = {'bot:general', 'bot:usernames', 'bot:chat:latsmsg'},
		d2 = {'bot:groupsid', 'bot:groupsid:removed', 'tempbanned', 'bot:blocked', 'remolden_chats'} --remolden_chats: chat removed with $remold command
	}
}

local multipurpose_plugins = os.getenv('MULTIPURPOSE_PLUGINS')
if multipurpose_plugins then
	_M.multipurpose_plugins = assert(json.decode(multipurpose_plugins),
		'$MULTIPURPOSE_PLUGINS must be a JSON array or empty')
end

return _M
