class Dataset
	include DataMapper::Resource

	property :id,			Serial
	property :name,			String,		:required => true
	property :touch,		DateTime
	property :data,			Text
	property :collapsed, 	Text
	
	belongs_to :user
end

