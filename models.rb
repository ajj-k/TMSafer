require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    has_many :schools
end

class School < ActiveRecord::Base
    has_many :members
    belongs_to :user
end

class Member < ActiveRecord::Base
    has_many :tasks
    belongs_to :school
end

class Task < ActiveRecord::Base
    belongs_to :member
end