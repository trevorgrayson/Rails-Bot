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
