# RailsBot
#class << ActiveRecord::Base
#end
require 'stringio'
require 'xmpp4r'
require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/muc/helper/simplemucclient'
require 'lib/bot_commands'

class RailsBot
	include Jabber
	RAILSBOT = YAML.load_file( "#{RAILS_ROOT}/config/rails_bot.yml" )

	def initialize
		@cmds = YAML.load_file("config/bot_commands.yml")
	end

	def login

		jid = JID::new("#{RAILSBOT['name']}@#{RAILSBOT['server']}/#{RAILSBOT['name']}")

		@client = Client.new(jid)
		@client.connect
		@client.auth(RAILSBOT['password'])
		@client.send(Jabber::Presence.new.set_show(:chat).set_status('Active'))
		puts "Authed"
		
		#m = Message::new('tgrayson@trevorgrayson.com', 'hello everybody')
			#.set_type(:normal).set_id('1').set_subject('test')
		#@client.send m
	end

	def register_with_chatroom
		muc_jid = JID::new("#{RAILSBOT['name']}@conference.#{RAILSBOT['server']}/#{RAILSBOT['name']}")
		muc = Jabber::MUC::SimpleMUCClient.new(@client)

		muc.on_message {| time,nick,text |
			if ( nick != RAILSBOT['name'] )
				puts( (time || Time.new).strftime('%I:%M') + " <#{nick}> #{text}" )

				if false && text[0] == 92 # / = 47, \ = 92
					strio = StringIO.new
					old_stdout = $stdout
					$stdout = strio

					begin
						result = eval(text[1..-1], sbinding)
					rescue Exception => e
						muc.say "Well done sir.\n" + e
					end

					strio.rewind
					muc.say strio.read
					muc.say result.inspect

					$stdout = old_stdout
				elsif text.match '^(hello|hey|hi|sup|salutations|greetings)$'
					muc.say 'Hello.'
				else
					@cmds.each{|regex,func|
						if text.match Regexp.new regex
							begin
								response = send(func, text)
							rescue StandardError => e
								puts e.to_s
								response = e.to_s
							end
							muc.say response
						end
					}
				end
			end
		}

		muc.join(muc_jid,'tugboat')

	end

end
