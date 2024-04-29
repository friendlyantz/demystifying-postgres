require 'active_record'
require 'awesome_print'
require 'pg'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'index_test',
  username: 'friendlyantz',
  password: 'password',
  host: 'localhost',
  port: 5432
)

conn = PG.connect(
  dbname: 'postgres',
  user: 'friendlyantz',
  password: 'password',
  host: 'localhost', # if you run in dockerm you need to connect via tcp and specify host/post, otherwise it uses unix socket
  port: 5432
)

begin
  conn.exec('CREATE DATABASE index_test')
rescue PG::DuplicateDatabase
  puts 'Database index_test already exists.'
end

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    return if ActiveRecord::Base.connection.table_exists?(:users)

    create_table :users do |t|
      t.string :name
    end
  end
end

class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    return if ActiveRecord::Base.connection.table_exists?(:posts)

    create_table :posts do |t|
      t.text :content
      t.references :user, foreign_key: true
    end
  end
end

CreateUsers.new.migrate(:up)
CreatePosts.new.migrate(:up)

class User < ActiveRecord::Base
  validates_presence_of :name, on: :create, message: "can't be blank"
  validates_uniqueness_of :name, on: :create, message: 'must be unique'

  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user
end

Post.destroy_all
User.destroy_all

User.create(name: 'Anton')
User.create(name: 'Mike')
User.create(name: 'Rian')
User.create(name: 'Jody')
User.create(name: 'Rubyists')

Post.create(user: User.first, content: 'Fresh comment🍋')
Post.create(user: User.find_by(name: 'Mike'), content: 'Jak się masz? Ship it!🛳️')
Post.create(user: User.find_by(name: 'Rian'), content: 'BuildKite rulez🪁')
Post.create(user: User.find_by(name: 'Jody'), content: 'Comment ça va de Jody🇫🇷')

binding.irb
