class Dataset
	include DataMapper::Resource

	property :id,        Serial
	property :name,      String,   :required => true
	property :year,      String,   :required => true
	property :url,       String,   :length => 256
	property :touch,     DateTime
	property :episodes,  Text
	property :collapsed, Text
	
	belongs_to :user
end

