def find_active_record_object_by_id body
	find_active_record_object body
end

def find_active_record_object body
	object, oid = body.split('#')
	object.strip!
	object.capitalize!
	oid.strip!

	object.constantize.find(oid).inspect
end

def run_rake_task body #please don't run arbitrary system commands here
	`#{body}`
end

def get_some_rest body 
	num = body.split(' ')[1]
	sleep num.to_i

	"That was a nice nap"
end
