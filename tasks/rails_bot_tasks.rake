require 'vendor/plugins/rails_bot/lib/rails_bot'
desc "Start up RailsBot"
task :rails_bot do
	require "#{RAILS_ROOT}/config/environment"
	bot = RailsBot.new(binding)
	bot.login
	bot.register_with_chatroom
	while true
		sleep 99999
	end
end
