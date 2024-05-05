require 'pry'
require_relative 'vm_line_parser'

filename = ARGV[0]

# binding.pry
# sdlfkj

output = []

if File.file?(filename)
    files = [filename]
    new_file_path = filename.gsub(/\.vm\z/, ".asm")
elsif
    files = Dir["#{filename}/*.vm"]
    new_file_path = "#{filename}/#{File.basename(filename)}.asm"
end

files.each do |file|
    parser = VMLineParser.new(file)
    lines = File.readlines(file)
                .map(&:strip)
                .map{ |line| line.split("//")[0] }
                .filter{ |line| (line != "") && (line != nil) }
                .map(&:strip)

    lines.each_with_index do |line, index|
        res = parser.parse_line(line, index)
        output.append(res)
    end
end


# BOOTSTRAP

bootlines = VMLineParser.new.parse_line("call Sys.init 0", "INIT")

bootstrap = [
    "@256",
    "D=A",
    "@SP",
    "M=D",
]

header = bootstrap + bootlines



# write file
File.open(new_file_path, "w") do |f|
    header.each { |element| f.puts(element) }
    output.each { |element| f.puts(element) }
end
