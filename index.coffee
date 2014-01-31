fs = require 'fs'
{ parse, packet_names } = require './parser'
zlib = require 'zlib'

source = fs.createReadStream process.argv[2]

gunzip = zlib.createInflateRaw()


bytes = new Buffer(0)

source.pipe(gunzip)
	.on 'data', (data) ->
		bytes = Buffer.concat [bytes, data]
	.on 'end', ->
		for packet in parse bytes
			if packet.decoded
				process.stdout.write JSON.stringify
					type: packet_names[packet.type]
					data: packet.decoded
			else
				process.stdout.write JSON.stringify
					type: packet_names[packet.type] || packet.type
					data: packet.data
			process.stdout.write "\n"