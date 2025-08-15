task :read_json => :environment do

  File.readlines('/mnt/c/Users/Jeremy/Documents/reg.txt').each do |line|
    # Address,Name,Type,Value,Um,Default,Min,Max,Description
    data = line.split(',')
    address = data[0]
    name = data[1]
    min_value = data[6]
    max_value = data[7]
    description = data[8]
    puts "{ name: '#{name}', description: '#{description}', address: #{address}, min_value: #{min_value}, max_value: #{max_value} },"
  end

end
