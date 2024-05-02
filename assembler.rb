require 'pry'
require_relative 'address_parser'
require_relative 'command_parser'

filename = ARGV[0]

lines = File.readlines(filename).map(&:strip)
                                .map{ |line| line.split("//")[0] }
                                .filter{ |line| (line != "") && (line != nil) }
                                .map(&:strip)

commands = []

jump_points = {}

# first pass
lines.each do |line|
    if line[0] == "("
        jump_point_name = line[1..-2]
        jump_points[jump_point_name] = commands.count
    else
        commands.append(line)
    end
end

ends = []

a_parser = AddressParser.new(jump_points)
c_parser = CommandParser.new()
commands.each do |command|
    if command[0] == "@"
        result = a_parser.get_binary_command(command)
    else
        result = c_parser.get_binary_command(command)
    end
    ends.append(result)
end

new_file_path = filename.gsub(/\.asm\z/, ".hack")

File.open(new_file_path, "w") do |f|
    ends.each { |element| f.puts(element) }
end


# binding.pry