# RailsBot
#class << ActiveRecord::Base
#end
require 'stringio'
require 'xmpp4r'
require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/muc/helper/simplemucclient'
require 'vendor/plugins/rails_bot/lib/bot_commands'

class RailsBot
	include Jabber
	RAILSBOT = YAML.load_file( "#{RAILS_ROOT}/config/rails_bot.yml" )

	def initialize(bind)
		@cmds = YAML.load_file("config/bot_commands.yml")
		@sbinding = bind
		@jobs = {}
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

		self.register_behaviors
		muc.join(muc_jid,'tugboat')

	end

	def register_behaviors
		muc.on_message {| time,nick,text |
			if ( nick != RAILSBOT['name'] )
				puts( (time || Time.new).strftime('%I:%M') + " <#{nick}> #{text}" )

				if text[0] == 92 # / = 47, \ = 92
					strio = StringIO.new
					old_stdout = $stdout
					$stdout = strio

					begin
						result = eval(text[1..-1], @sbinding)
					rescue Exception => e
						muc.say "Well done sir.\n" + e
					end

					strio.rewind
					muc.say strio.read
					muc.say result.inspect

					$stdout = old_stdout
				elsif text.match '^(hello|hey|hi|sup|salutations|greetings)$'
					muc.say 'Hello.'
				elsif text.match 'what is happening'
					if @jobs.size > 0
						response = "\n"
						@jobs.each {|job,attrs|
							response += "#{attrs[:nick]} told me to `#{attrs[:text]}`.#{" Which I just finished." if !job.status}\n"
						}
						
						muc.say response + "Now let me get back to work!"
					else 
						muc.say "Just hanging out."
					end
				else
					@cmds.each{|regex,func|
						if text.match Regexp.new regex
							begin
								job = Thread.new {

									Thread.stop
									muc.say	send(func, text)
									@jobs.delete job
								}

								#Keep track of what's going on
								@jobs.merge!({ job => {
										:nick => nick,
										:text => text
									}
								})

								puts @jobs.inspect
								job.join(5)

								case job.status
									when 'run' then 
										"Trevor Grayson did not expect this case."
									when 'sleep' then 
										muc.say "#{nick}: I'm working on it. Give me a couple of minutes on this one."
										job.run
									when 'aborting' then "I'm aborting this job."
									#when false then ""
									#else
								end

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

	end

end
