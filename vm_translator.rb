require 'pry'
require_relative 'vm_line_parser'

filename = ARGV[0]

lines = File.readlines(filename).map(&:strip)
                                .map{ |line| line.split("//")[0] }
                                .filter{ |line| (line != "") && (line != nil) }
                                .map(&:strip)

parser = VMLineParser.new(filename)

output = []

lines.each_with_index do |line, index|
    res = parser.parse_line(line, index)
    output.append(res)
end

new_file_path = filename.gsub(/\.vm\z/, ".asm")

File.open(new_file_path, "w") do |f|
    output.each { |element| f.puts(element) }
end
