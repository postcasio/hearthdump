Int64 = require('node-int64')
{ Protobuf } = require("node-protobuf")
fs = require 'fs'

packet_types =
	AUTH_RESPONSE: 106
	GAME_INFO: 107
	REMOVE_GAME: 108
	GOTO_SERVER: 109
	PLAYER_JOINED: 110
	PLAYER_LEFT: 111
	MESSAGE: 126
	GOTO_UTIL: 151
	QUEUE_EVENT: 161
	DEBUG_MESSAGE: 5
	START_GAMESTATE: 7
	FIN_GAMESTATE: 8
	TURN_TIMER: 9
	NACK_OPTION: 10
	GAME_CANCELED: 12
	ALL_OPTIONS: 14
	USER_UI: 15
	GAME_SETUP: 16
	ENTITY_CHOICE: 17
	PRELOAD: 18
	POWER_HISTORY: 19
	NOTIFICATION: 21
	GAME_STARTING: 114
	DECK_LIST: 202
	UTIL_AUTH: 204
	COLLECTION: 207
	GAMES_INFO: 208
	PROFILE_NOTICES: 212
	DECK_CONTENTS: 215
	DECK_ACTION: 216
	DECK_CREATED: 217
	DECK_DELETED: 218
	DECK_RENAMED: 219
	DECK_GAIN_CARD: 220
	DECK_LOST_CARD: 221
	BOOSTER_LIST: 224
	OPENED_BOOSTER: 226
	LAST_LOGIN: 227
	DECK_LIMIT: 231
	MEDAL_INFO: 232
	PROFILE_PROGRESS: 233
	MEDAL_HISTORY: 234
	BATTLE_PAY_CONFIG_RESPONSE: 238
	CLIENT_OPTIONS: 241
	DRAFT_BEGIN: 246
	DRAFT_RETIRE: 247
	DRAFT_CHOICES_AND_CONTENTS: 248
	DRAFT_CHOSEN: 249
	DRAFT_ERROR: 251
	ACHIEVE: 252
	CARD_QUOTE: 256
	CARD_SALE: 258
	CARD_VALUES: 260
	DISCONNECTED_GAME: 289
	PURCHASE_RESPONSE: 256
	ACCOUNT_BALANCE: 262
	FEATURES_CHANGED: 264
	BATTLEPAY_STATUS_RESPONSE: 265
	MASS_DISENCHANT_RESPONSE: 269
	PLAYER_RECORDS: 270
	REWARD_PROGRESS: 271
	PURCHASE_METHOD: 272
	PURCHASE_CANCELED_RESPONSE: 275
	CHECK_LICENSES_RESPONSE: 277
	GOLD_BALANCE: 278
	PURCHASE_WITH_GOLD_RESPONSE: 280
	QUEST_CANCELED: 282
	ALL_HERO_XP: 283
	ACHIEVE_VALIDATED: 285
	PLAY_QUEUE: 286
	DRAFT_ACK_REWARDS: 288
	NOT_AVAILABLE: 290
	DC_CONSOLE_CMD: 123
	DC_RESPONSE: 124
	
packet_names = {}
packet_names[v] = k for k, v of packet_types
exports.packet_names = packet_names
	
class HearthPacket
	@type: 0
	@name: 'Unknown'
	
	@packet_classes: {}
	
	constructor: (@type, @data) ->
		if @constructor.pb and @constructor.proto
			@decoded = @constructor.pb.Parse @data, @constructor.proto

	@register: (packet_class) ->
		HearthPacket.packet_classes[packet_class.type] = packet_class
		
	@create: (type, data) ->
		if HearthPacket.packet_classes[type]
			return new HearthPacket.packet_classes[type](type, data)
		else
			return new HearthPacket(type, data)

	toString: ->
		"#{packet_names[@type]} (#{@type}) len: #{@data.length} #{@data.toString 'hex'}"
		
class HearthPacket_StartGameState extends HearthPacket
	@type: packet_types.START_GAMESTATE
	@pb: new Protobuf(fs.readFileSync("descriptors/StartGameState.desc"))
	@proto: 'StartGameState'
	
HearthPacket.register HearthPacket_StartGameState
	
class HearthPacket_GameSetup extends HearthPacket
	@type: packet_types.GAME_SETUP
	@pb: new Protobuf(fs.readFileSync("descriptors/GameSetup.desc"))
	@proto: 'GameSetup'
		
HearthPacket.register HearthPacket_GameSetup

class HearthPacket_PowerHistory extends HearthPacket
	@type: packet_types.POWER_HISTORY
	@pb: new Protobuf(fs.readFileSync("descriptors/PowerHistory.desc"))
	@proto: 'PowerHistory'
		
HearthPacket.register HearthPacket_PowerHistory

exports.parse = (@buf) ->
	offset = 8
	packets = []
	
	magic = @buf.toString('utf8', offset, offset += 9)

	if magic != 'HSLH\t\0\0\0\t'
		throw 'Invalid log format'
		
	version = @buf.slice(offset, offset += 8)
	
	while offset < @buf.length
		time = new Int64(@buf.slice offset, offset += 8)
		
		packet_type = buf.readUInt32LE(offset)
		offset += 4
		
		packet_length = buf.readUInt32LE(offset)
		offset += 4
		
		data = @buf.slice(offset, offset += packet_length)
		try
			packets.push HearthPacket.create packet_type, data

		catch e
			break
		
	packets