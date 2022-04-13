#!/usr/bin/env python3

import math

def tohex(val, nbits):
    return format((val + (1 << nbits)) % (1 << nbits), '04X')

def convert_file(file_in, file_out, address, bits, skip_header_lines, skip_lines, shift_right):
    with open(file_in, 'r') as input:
        element_counter = 0;    
        lines = input.readlines()[skip_header_lines:]

        with open(file_out, 'w') as output:
            skip_counter = 0
            for line in lines:
                elements = line.split(',')
                if len(elements) == 4:
                    if skip_counter % skip_lines == 0:
                        for e in list(map(int, elements)):
                            output.write('0x' + tohex(address + element_counter, 16) + ' ')
                            output.write('0x' + tohex(math.floor(e / 2**shift_right), bits) + '\n')
                            element_counter = element_counter + 1
                    skip_counter = skip_counter + 1

convert_file('lanczos2_12.txt',     'lanczos2_12.out'    , 0x7000, 10, 6, 4, 1)
convert_file('Scan_Br_120_80.txt',  'Scan_Br_120_80.out' , 0x7100, 10, 7, 1, 0)
