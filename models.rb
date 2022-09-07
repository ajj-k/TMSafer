require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection(:production)

class User < ActiveRecord::Base
    has_secure_password
    validates :mail,
    presence: true,
    format: {with:/\A.+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+\z/}
    has_many :schools, dependent: :destroy
end

class School < ActiveRecord::Base
    has_many :members, dependent: :destroy
    belongs_to :user
end

class Member < ActiveRecord::Base
    has_many :tasks, dependent: :destroy
    belongs_to :school
end

class Task < ActiveRecord::Base
    belongs_to :member
end