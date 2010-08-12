def find_active_record_object_by_id body
	find_active_record_object body
end

def find_active_record_object body
	object, oid = body.split('#')
	object.strip!
	object.capitalize!
	oid.strip!
	puts oid

	object.constantize.find(oid).inspect
end

def deploy_to_staging body
	out = 'deploying to staging...'
	#Bot::Variables.servers.each{|server_ip|
	#	out += "Deploying to #{server_ip}"
	#}

	out
end

def clear_cache body=''
	out = 'clearing object and page cache.. '
	#Bot::Variables.servers.each{|server_ip|
	out += `curl http://admin:smapi@stage.sonymusicdigital.com/admin/maintenance/clear_object_cache`
	out += `curl http://admin:smapi@stage.sonymusicdigital.com/admin/maintenance/clear_page_cache`
end

def clear_object_cache body=''
	#Bot::Variables.servers.each{|server_ip|
	`curl http://admin:smapi@stage.sonymusicdigital.com/admin/maintenance/clear_object_cache`
end

def clear_page_cache body=''
	#Bot::Variables.servers.each{|server_ip|
	`curl http://admin:smapi@stage.sonymusicdigital.com/admin/maintenance/clear_page_cache`
end

def push_sql_staging body
	store_permalink = body[11..-1].downcase.gsub(' ','-')

	begin
		store = Store::Base.find_by_permalink!(store_permalink)
		out = "Pushing SQL for '#{store_permalink} (#{store.id})..."
		filename = "store-#{store_permalink}-#{Time.new.strftime('%Y%m%d%H%M')}.sql"
		export_return = `../m2-core/loader/export-store.sh #{store.id} /tmp/#{filename}`
	rescue
		return "I don't know of any stores named #{store_permalink}"
	end

	`scp /tmp/#{filename} root@staging_database:~/`
	puts "/Users/tgrayson/bin/deploy_stage /tmp/#{filename}"
	`/Users/tgrayson/bin/deploy_stage /tmp/#{filename}`
	`curl --basic --user "sonyd2c:tugboat" --data-ascii "status=#sonydev%20#m2%20#{store.name}%20has%20been%20pushed%20to%20stage." http://twitter.com/statuses/update.json`

	#require 'net/ftp'

	#begin
	#	ftp = Net::FTP.new('ftp.sonymusicmobile.com')
	#	ftp.login 'tgrayson','jasminegr33n'
	#	ftp.put "/tmp/#{filename}"
	#	ftp.close
	#rescue
	#	return "Oops. I exported #{store_permalink} as #{filename}, but I couldn't get this to upload"
	#end
	out + " #{filename} uploaded."

	if clear_cache
		out += "  The cache has been cleared."
	end

	out
end

def twitter body
	body = body[8..-1]
	`curl --basic --user "sonyd2c:tugboat" --data-ascii "status=#m2 #sonydev #{body}" http://twitter.com/statuses/update.json`
end 

def find_styles_by_store_permalink body
	store_permalink = body.gsub(/ styles$/,'').downcase.gsub(' ','-')
	if store = Store::Base.find_by_permalink!(store_permalink)
		store.title + "\n" + "Style ids:" + store.styles.collect{|style| style.id }.join(',')
	else
		"No store with that permalink!"
	end
end

def find_by_store_permalink body
	store_permalink = body.gsub(/ store$/,'').downcase.gsub(' ','-')
	Store::Base.find_by_permalink!(store_permalink).inspect
end

def asfd body
	sql_file = body[10..-1]
	publish sql_file
	sql_file
end
