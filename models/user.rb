class User
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String, :required => true, :unique => true
	property :pw_hash,		String, :required => true, :length => 60
	property :pw_salt,		String, :required => true

	has n, :datasets
end

