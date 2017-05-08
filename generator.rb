require "rubygems"
require "sequel"
require 'open-uri'
require 'openssl'
require "csv"

Sequel.extension :pretty_table  #Sequel::PrettyTable.print()/Sequel::PrettyTable.string()

system("clear")

url = "https://docs.google.com/spreadsheets/d/1CS1jm7zEtt1QrtsnKfdwWKowUsJ68JiU22j-VHF9i3E/pub?gid=291640441&single=true&output=csv"
download = open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
IO.copy_stream(download, 'responses.csv')
CSV.new(download).each do |l|
   puts  l
end

# @total_spaces
# connect to an in-memory database
DB = Sequel.sqlite
# DB = Sequel.sqlite('guests.db')
# DB = Sequel.connect('postgres://user:password@localhost/my_db')
# DB = Sequel.postgres('my_db', :user => 'user', :password => 'password', :host => 'localhost')
# DB = Sequel.ado('mydb')

def import_csv(tabname, data)
  csv = CSV.parse(data, :headers=> true, :header_converters => :symbol )
  DB.create_table(tabname){
    primary_key :id
    csv.headers.each{|col|
    String col
    }
  }
  # p csv.headers
  DB[tabname].multi_insert(csv.map {|row| row.to_h})
end

import_csv(:guests, File.read('responses.csv'))

# create an item`s table
# DB.create_table :guests do
#   primary_key :id
#   String :first_name
#   String :last_name
#   String :home_scene
#   String :gender
#   String :allergies
#   Boolean :is_smoker
#   Boolean :tolerates_smokers
#   String :room
#   String :bed
#   # Integer :sharing
#   # 0 = No sharing bed or room with opposite sex
#   # 1 = Sharing bed with same sex
#   # 2 = sharing room with opposite sex
#   # 3 = sharing bed with opposite sex
#   # 4 = sharing bed with opposite sex, but only specific person
# 
#     String :matched_with
#     String :other_notes
#     String :avoid
# end

DB.create_table :hosts do
  primary_key :id
  String :name
  String :allergens
  Boolean :tolerates_smokers
  Boolean :is_smoker
  String :rooms
  String :matched_with
  String :avoid
end


# create a dataset from the items table
guests = DB[:guests]
hosts = DB[:hosts]

def string_array(in_var)
  return "#{in_var.split(",")}"
end

def int_array(in_var)
  return "#{in_var.split(",").map { |s| s.to_i }}"
end

def full_name(z)
  temp_name = "#{z[:first_name]} #{z[:last_name]}"
  return temp_name
end

def print_all_tables
  DB.tables.each{|table|
    puts table
    Sequel::PrettyTable.print(DB[table])
  }
end

def print_results(query)
  line=''
  query.columns.each{|column|
    print column
    print " "
    line=line+('-' * column.length)+'|'
  }
  puts " "
  puts line
  # puts " "
  query.all.each{ |result|
    result.each{ |x|
      print x[1]
      print " "
      }
    puts " "
    }
end

def pretty_print_results(query)
  line='├'
  max_lengths = {}
  query.columns.each_with_index{|column, index|
    # line=line+('-' * column.length)+'|'
    max_lengths[index] = column.length
  }

  # puts " "
  # puts max_lengths
  # puts " "
  # puts line
  # puts " "
  query.all.each{ |result|
    result.each_with_index{ |x, index|
      # print x[1]
      # print " "
      if x[1].to_s.length > max_lengths[index]
        max_lengths[index] = x[1].to_s.length
      end
      }
    # puts " "
    }
    # puts " "
    # puts max_lengths
    # puts " "
  # total_length=0
  # puts max_lengths
  # line_hash = {}
  # puts " "
  max_lengths.each{|z| line += ('─' * (z[1]+2)) + '┼' }
  # puts line_hash
  # print '|'
  # line_hash.each{|col| print col[1] + '|'}
  # puts " "
  line = line.gsub(/┼$/, '┤')
  puts line.gsub(/^├/, '╔').gsub(/┤$/, '╗').gsub(/┼/, '╦').gsub('─','═')
  # puts " "
  # puts " "
  # line = '|' + ('-' * (total_length + 1) ) + '|'
  print '║ '
    query.columns.each_with_index{|column, index|
      print (" " * ((max_lengths[index] - column.length) / 2) )
      print column
      print (" " * (((max_lengths[index] - column.length) / 2) + ((max_lengths[index] - column.length) % 2)) )
      print ' ║ '
    }
  puts " "
  puts line.gsub(/^├/, '╚').gsub(/┤$/, '╝').gsub(/┼/, '╩').gsub('─','═')#.gsub('─','#')
  puts line.gsub(/^├/, '┌').gsub(/┤$/, '┐').gsub(/┼/, '┬')#.gsub('─','#')
  # puts line#.gsub('─','#')
    query.all.each_with_index{ |result, index_outer|
      print '│ '
      result.each_with_index{ |x, index|
        print (" " * ((max_lengths[index] - x[1].to_s.length) / 2) )
        print x[1]
        print (" " * (((max_lengths[index] - x[1].to_s.length) / 2) + ((max_lengths[index] - x[1].to_s.length) % 2)) )
        print ' │ '
        }
      puts " "
      if index_outer == (query.all.size - 1)
        puts line.gsub(/^├/, '└').gsub(/┤$/, '┘').gsub(/┼/, '┴')
      else
        puts line
      end
      }
end

coed_room_guests = guests.where(:room => 'I am okay sleeping in a room with people of any gender')
coed_male_share = coed_room_guests.where(:gender => 'Males', :bed => 'I am okay sharing a bed, but only with someone of the same gender')
coed_female_share = coed_room_guests.where(:gender => 'Female', :bed => 'I am okay sharing a bed, but only with someone of the same gender')
coed_coed_share = coed_room_guests.where(:bed => 'I am okay sharing a bed with somene of any gender')
coed_solo = coed_room_guests.where(:bed => 'I do not want to share a bed')
male_room_guests = guests.where(:gender => 'Male', :room => 'I only want to sleep in a room with people of the same gender')
male_only_share = male_room_guests.where(:bed => 'I only want to sleep in a room with people of the same gender')
male_only_solo = male_room_guests.where(:bed => 'I do not want to share a bed')
female_room_guests = guests.where(:gender => 'Female', :room => 'I am okay sharing a bed, but only with someone of the same gender')
female_only_share = female_room_guests.where(:bed => 'I am okay sharing a bed, but only with someone of the same gender')
female_only_solo = female_room_guests.where(:bed => 'I do not want to share a bed')


# def update_spaces(x)
# 
#   # spaces = x.select(:rooms)
#   puts "updating total"
#   # x.select(:rooms).each{| x | puts x[:rooms]}
#   sum = 0
#   x.select(:rooms).each{| z | zp[:rooms]{ | y | sum +=y} }
#   puts "finished updating"
#   # puts x[:rooms]
# end

# hosts.insert(:name => 'Brittany Bassett', :allergens => string_array('dogs,cats'), :tolerates_smokers => false, :is_smoker => false, :rooms => int_array("3,3,4"),:matched_with => nil, :avoid => 'Kirby')

# prints all names:
# guests.each{|person| puts person[:name]}

# update_spaces(hosts)

# guests.select(:first_name,:last_name).order(:last_name).each{| x | puts full_name(x)}
# hosts.select(:name, :rooms).order(:name).each{| x | puts x[:name]; puts x[:rooms]}
# guests.select(:name).order(:name).each{| x | puts x[:name]}.where()

puts "ordering by last_name"
pretty_print_results(guests.select(:id, :first_name, :last_name).order(:last_name))
puts " "
puts "ordering by id"
pretty_print_results(guests.select(:id, :first_name, :last_name).order(:id))

puts " "
puts "test1"
pretty_print_results(coed_room_guests.select(:id,:first_name,:last_name))

puts " "
puts "test2"
pretty_print_results(coed_room_guests.select(:id,:first_name,:last_name,:bed))
# pretty_print_results(coed_room_guests)
# guests.select(:id, :first_name, :last_name).order(:last_name).all.each{ |result|
#   result.each{ |x|
#     print x[1]
#     print " "
#     }
#   puts " "
#   }

# print_all_tables