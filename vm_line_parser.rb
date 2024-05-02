require 'pry'
class VMLineParser

    POINTER_MAP = {
        "local" => "LCL",
        "argument" => "ARG",
        "this" => "THIS",
        "that" => "THAT",
    }

    def initialize(filename)
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

    def pop(stack_name, value)
        
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
            "@target_address",
            "M=D",
            "@SP",
            "M=M-1",
            "A=M",
            "D=M",
            "@target_address",
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
            "D=A+1",
            "@SP",
            "M=D"
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
            "A=M",
            "A=A-1",
            "M=-M",
        ]
    end

    def not()
        [
            "@SP",
            "A=M",
            "A=A-1",
            "M=!M",
        ]
    end

    def parse_line(line, index)
        command, *args = line.split(" ")
        if ["eq","lt","gt"].include?(command)
            to_asm = ["// #{line}"] + send(command, index)
        else
            to_asm = ["// #{line}"] + send(command, *args)
        end
        to_asm.join("\n")
    end
end