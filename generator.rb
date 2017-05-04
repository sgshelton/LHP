require "rubygems"
require "sequel"

# connect to an in-memory database
DB = Sequel.sqlite
# DB = Sequel.sqlite('lindy_hoppers.db')
# DB = Sequel.connect('postgres://user:password@localhost/my_db')
# DB = Sequel.postgres('my_db', :user => 'user', :password => 'password', :host => 'localhost')
# DB = Sequel.ado('mydb')

# create an item`s table
DB.create_table :items do
  primary_key :id
  String :name
  String :allergies
  Boolean :tolerates_smokers
  Boolean :is_smoker
  Integer :sharing
  # 0 = No sharing bed or room with opposite sex
  # 1 = Sharing bed with same sex
  # 2 = sharing room with opposite sex
  # 3 = sharing bed with opposite sex
  # 4 = sharing bed with opposite sex, but only specific person

    String :matched_with

  # Float :price
end

# create a dataset from the items table
lindy_hoppers = DB[:items]

# populate the table
# items.insert(:name => 'abc', :price => rand * 100)
# items.insert(:name => 'def', :price => rand * 100)
# items.insert(:name => 'ghi', :price => rand * 100)
lindy_hoppers.insert(:name => 'Katelyn Mcwhirter', :tolerates_smokers => false, :is_smoker => false, :allergies => 'N/A', :sharing => 1)
lindy_hoppers.insert(:name => 'Sam Shelton', :tolerates_smokers => false, :is_smoker => false, :allergies => 'perfumes', :sharing => 1)
lindy_hoppers.insert(:name => 'Jony Navaro', :tolerates_smokers => false, :is_smoker => false, :allergies => 'N/A', :sharing => 4)

# print out the number of records
puts "Lindy Hopper count: #{lindy_hoppers.count}"

# puts "All names:"
# lindy_hoppers.each{|person| puts person[:name]}


lindy_hoppers.select(:name).order(:name).each{| x | puts x[:name]}

# print out the average price
# puts "The average price is: #{items.avg(:price)}"