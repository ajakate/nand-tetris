require 'pry'
class VMLineParser

    POINTER_MAP = {
        "local" => "LCL",
        "argument" => "ARG",
        "this" => "THIS",
        "that" => "THAT",
    }

    def initialize(filename = "nil.vm")
        @base_filename = filename.split("/")[-1][0..-4]
    end

    def generic_push(target_address)
        [
            "@#{target_address}",
            "D=M",
            "@SP",
            "A=M",
            "M=D",
            "@SP",
            "M=M+1"
        ]
    end

    def generic_pop(target_address)
        [
            "@SP",
            "M=M-1",
            "A=M",
            "D=M",
            "@#{target_address}",
            "M=D"
        ]
    end

    def push(stack_name, value)
        if stack_name == "constant"
            return [
                "@#{value}",
                "D=A",
                "@SP",
                "A=M",
                "M=D",
                "@SP",
                "M=M+1"
            ]
        end

        if stack_name == 'temp'
            target_address = 5 + value.to_i
            return generic_push(target_address)
        end

        if stack_name == 'pointer'
            if value == "0"
                target_address = "THIS"
            else
                target_address = "THAT"
            end
            return generic_push(target_address)
        end

        if stack_name == 'static'
            target_address = "#{@base_filename}.#{value}"
            return generic_push(target_address)
        end

        pointer = POINTER_MAP[stack_name]
        return [
            "@#{value}",
            "D=A",
            "@#{pointer}",
            "A=D+M",
            "D=M",
            "@SP",
            "A=M",
            "M=D",
            "@SP",
            "M=M+1"
        ]
    end

    def pop(index, stack_name, value)

        if stack_name == 'temp'
            target_address = 5 + value.to_i
            return generic_pop(target_address)
        end

        if stack_name == 'pointer'
            if value == "0"
                target_address = "THIS"
            else
                target_address = "THAT"
            end
            return generic_pop(target_address)
        end

        if stack_name == 'static'
            target_address = "#{@base_filename}.#{value}"
            return generic_pop(target_address)
        end

        pointer = POINTER_MAP[stack_name]
        return [
            "@#{value}",
            "D=A",
            "@#{pointer}",
            "D=D+M",
            "@target_address_#{index}",
            "M=D",
            "@SP",
            "M=M-1",
            "A=M",
            "D=M",
            "@target_address_#{index}",
            "A=M",
            "M=D"
        ]
    end

    def generic_arith(command)
        [
            "@SP",
            "M=M-1",
            "A=M",
            "D=M",
            "A=A-1",
            command,
        ]
    end

    def add()
        generic_arith("M=D+M")
    end

    def sub()
        generic_arith("M=M-D")
    end

    def and()
        generic_arith("M=D&M")
    end

    def or()
        generic_arith("M=D|M")
    end

    def generic_comparison(i, jump_cond)
        [
            "@SP",
            "M=M-1",
            "A=M",
            "D=M",
            "A=A-1",
            # D is bottom, M is top/current, SP currently at where it should be!
            "D=D-M",
            "@SET_TRUE_#{i}",
            "D;#{jump_cond}",
            "D=0",
            "@END_#{i}",
            "0;JMP",

            "(SET_TRUE_#{i})",
            "D=-1",

            "(END_#{i})",

            "@SP",
            "A=M",
            "A=A-1",
            "M=D",
        ]
    end

    def eq(i)
        generic_comparison(i, "JEQ")
    end

    def lt(i)
        generic_comparison(i, "JGT")
    end

    def gt(i)
        generic_comparison(i, "JLT")
    end

    def neg()
        [
            "@SP",
            "A=M-1",
            "M=-M",
        ]
    end

    def not()
        [
            "@SP",
            "A=M-1",
            "M=!M",
        ]
    end

    def label(name)
        [
            "(#{name})"
        ]
    end

    def goto(label)
        [
            "@#{label}",
            "0;JMP"
        ]
    end

    def if_goto(label)
        [
            "@SP",
            "M=M-1",
            "A=M",
            "D=M",
            "@#{label}",
            "D;JNE"
        ]
    end

    def function(name, arg_size)
        command = ["(#{name})"]
        arg_size.to_i.times do
            push_local_0 = [
                "@SP",
                "A=M",
                "M=0",
                "@SP",
                "M=M+1"
            ]
            command = command + push_local_0
        end
        command
    end

    def return()
        [
            # store endframe; LCL loc
            "@LCL",
            "D=M",
            "@endframe",
            "M=D",
            # gets the return address, store in temp var
            "@5",
            "D=D-A",
            "A=D",
            "D=M",
            "@return_address",
            "M=D",
            # POP STACK, put in ARG0
            "@SP",
            "M=M-1",
            "A=M",
            "D=M",
            "@ARG",
            "A=M",
            "M=D",
            # SP = ARG + 1
            "@ARG",
            "D=M+1",
            "@SP",
            "M=D",
            # push that
            "@endframe",
            "D=M-1",
            "A=D",
            "D=M",
            "@THAT",
            "M=D",
            # push this
            "@2",
            "D=A",
            "@endframe",
            "D=M-D",
            "A=D",
            "D=M",
            "@THIS",
            "M=D",
            # push arg
            "@3",
            "D=A",
            "@endframe",
            "D=M-D",
            "A=D",
            "D=M",
            "@ARG",
            "M=D",
            # push LCL
            "@4",
            "D=A",
            "@endframe",
            "D=M-D",
            "A=D",
            "D=M",
            "@LCL",
            "M=D",
            # jump back
            "@return_address",
            "A=M",
            "0;JMP"
        ]
    end

    def call(index, name, arg_size)
        return_address = "#{name}$ret.#{index}"
        [
            # push return address to stack
            "@#{return_address}",
            "D=A",
            "@SP",
            "A=M",
            "M=D",
            "@SP",
            "M=M+1",
            # push LCL
            "@LCL",
            "D=M",
            "@SP",
            "A=M",
            "M=D",
            "@SP",
            "M=M+1",
            # push ARG
            "@ARG",
            "D=M",
            "@SP",
            "A=M",
            "M=D",
            "@SP",
            "M=M+1",
            # push THIS
            "@THIS",
            "D=M",
            "@SP",
            "A=M",
            "M=D",
            "@SP",
            "M=M+1",
            # push THAT
            "@THAT",
            "D=M",
            "@SP",
            "A=M",
            "M=D",
            "@SP",
            "M=M+1",
            # ARG = SP - 5 - nArgs
            "@SP",
            "D=M",
            "@#{arg_size}",
            "D=D-A",
            "@5",
            "D=D-A",
            "@ARG",
            "M=D",
            # LCL = SP
            "@SP",
            "D=M",
            "@LCL",
            "M=D",
            # goto function
            "@#{name}",
            "0;JMP",
            # return address label
            "(#{return_address})"
        ]
    end

    def parse_line(line, index)
        command, *args = line.split(" ")
        command = command.gsub("-","_")
        if ["eq","lt","gt"].include?(command)
            to_asm = ["// #{line}"] + send(command, index)
        elsif ["call", "pop"].include?(command)
            to_asm = ["// #{line}"] + send(command, index, *args)
        else
            to_asm = ["// #{line}"] + send(command, *args)
        end
    end
end
