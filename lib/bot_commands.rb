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

def run_rake_task body #please don't run arbitrary system commands here
	`#{body}`
end
