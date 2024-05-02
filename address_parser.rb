class AddressParser

    def initialize(jump_points)
        init_vars = {
            "R0" => 0,
            "R1" => 1,
            "R2" => 2,
            "R3" => 3,
            "R4" => 4,
            "R5" => 5,
            "R6" => 6,
            "R7" => 7,
            "R8" => 8,
            "R9" => 9,
            "R10" => 10,
            "R11" => 11,
            "R12" => 12,
            "R13" => 13,
            "R14" => 14,
            "R15" => 15,
            "SCREEN" => 16384,
            "KBD" => 24576,
            "SP" => 0,
            "LCL" => 1,
            "ARG" => 2,
            "THIS" => 3,
            "THAT" => 4,    
        }
        @vars = init_vars.merge(jump_points)
        @next_var_location_index = 16
    end

    def get_binary_command(full_line)
        address_sym = full_line[1..]
        dec_number = @vars[address_sym]
        if dec_number == nil
            if /^\d+$/.match(address_sym)
                dec_number = address_sym.to_i
            else
                dec_number = @next_var_location_index
                @vars[address_sym] = dec_number
                @next_var_location_index += 1
            end
        end
        dec_number.to_s(2).rjust(16,'0')
    end
end