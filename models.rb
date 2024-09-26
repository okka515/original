require 'bundler/setup'
Bundler.require
require 'bcrypt'

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    has_many :follows
    has_many :likes
    has_many :contents
    validates :name, uniqueness: true
end

class Follow < ActiveRecord::Base
    belongs_to :user
end

class Like < ActiveRecord::Base
    belongs_to :user
    belongs_to :content
end

class Content < ActiveRecord::Base
    belongs_to :user
    has_many :likes
    validates :latitude, numericality: true, allow_nil: true
    validates :longitude, numericality: true, allow_nil: true
end