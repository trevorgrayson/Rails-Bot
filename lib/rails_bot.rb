require 'stringio'
require 'xmpp4r'
require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/muc/helper/simplemucclient'
require File.dirname(__FILE__) + '/bot_commands.rb'

class RailsBot
	include Jabber

	bot_config_path = "#{RAILS_ROOT}/config/rails_bot.yml"	

	if !FileTest.exists? bot_config_path
		bot_config_path = "#{File.dirname(__FILE__)}/../config/rails_bot.yml" 
	end

	RAILSBOT = YAML.load_file(bot_config_path)
	WAIT_TIME = 2


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
		@muc = Jabber::MUC::SimpleMUCClient.new(@client)

		register_behaviors
		@muc.join(muc_jid,'tugboat')

	end

	def register_behaviors
		@muc.on_message {| time,nick,text |
			if ( nick != RAILSBOT['name'] )
				puts( (time || Time.new).strftime('%I:%M') + " <#{nick}> #{text}" )

				if text[0] == 92 # / = 47, \ = 92
					#User started with the magic character, this will be run as ruby code
					self.schedule(nick, text) {
						strio = StringIO.new
						old_stdout = $stdout
						$stdout = strio

						begin
							result = eval(text[1..-1], @sbinding)
						rescue Exception => e
							@muc.say "Well done sir.\n" + e
						end

						strio.rewind
						@muc.say strio.read      #echo stdout to chatroom

						$stdout = old_stdout

						result.inspect           #Implicitly Show results IRB style
					}

				elsif text.match '^(hello|hey|hi|sup|salutations|greetings)$'
					#Be polite and respond to greetings. (Also good to check bot's heartbeat)
					@muc.say 'Hello.'

				elsif text.match 'what is happening'
					#Describe what's going on with background tasks
					if @jobs.size > 0
						response = "\n"
						@jobs.each {|job,attrs|
							response += "#{attrs[:nick]} told me to `#{attrs[:text]}`.#{" Which I just finished." if !job.status}\n"
						}
						
						@muc.say response + "Now let me get back to work!"

					else 
						@muc.say "Just hanging out."
					end
				else
					#Check regex list of commands. This is the customizable part.
					@cmds.each{|regex,func|
						if text.match Regexp.new regex
							self.schedule(nick, text) do
								send(func, text)  
							end
							@muc.say response
						end
					}
				end
			end
		}

	end

	def schedule(requestor, request)
		begin
			job = Thread.new {
				Thread.stop                #Let's pause the process, so we can schedule it.
				@muc.say yield             #Process has been resumed.. have at it!
				@jobs.delete job           #Clean up the job.
			}

			#Keep track of what's going on
			@jobs.merge!({ job => {
					:nick => requestor,
					:text => request
				}
			})

			puts @jobs.inspect
			job.run

		rescue StandardError => e
			puts e.to_s
			response = e.to_s
		end
	end

end
