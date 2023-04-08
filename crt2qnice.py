#!/usr/bin/env python3

import sys

# This program converts from CRT file:
#   [0000000]  43 36 34 20  43 41 52 54  52 49 44 47  45 20 20 20   *C64 CARTRIDGE   *
#   [0000010]  00 00 00 40  01 00 00 00  00 00 00 00  00 00 00 00   *...@............*
#   [0000020]  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   *................*
#   [0000030]  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00   *................*
#   [0000040]  43 48 49 50  00 00 40 10  00 00 00 00  80 00 40 00   *CHIP..@.......@.*
#   [0000050]  0f 80 09 80  c3 c2 cd 38  30 68 a8 68  aa 68 40 a2   *.......80h.h.h@.*
# to QNICE memory load file:
#   MC_FFF4_0004
#   MC_FFF5_0100
#   ML_7000_0f80_7001_0980 ...


# Convert a byte-array to integer (assuming big-endian format)
def read_be(ar):
    val = 0
    for b in ar:
        val = (val<<8) + b
    return val


def print_chip(chip_data, load_addr, chip_num, file_out):
    if file_out != "":
        with open(file_out, mode='a') as output:
            for offset in range(0,len(chip_data),2):
                w = read_be(chip_data[offset:offset+2])
                output.write(f"x{load_addr+offset//2:04x} x{w:04x}    ")
                if (offset%16) == 14:
                    output.write("\n")


def convert_file(file_in, file_out):
    with open(file_in, mode='rb') as input:
        contents = input.read()

    # Check header
    if contents[:16] != b'C64 CARTRIDGE   ':
        print("Wrong file format")

    if contents[16:20] != b'\x00\x00\x00\x40':
        print("Wrong header length")

    if contents[20:22] != b'\x01\x00':
        print("Wrong cartridge version")

    crt_type = read_be(contents[22:24])
    print(f"{file_in}: crt_type={crt_type}")

    # Empty output file
    if file_out != "":
        handle = open(file_out, mode='w')
        handle.close()

    chip_pointer = 64
    chip_num = 0
    while len(contents) > chip_pointer:
        if contents[chip_pointer:chip_pointer+4] == b'CHIP':
            #print("Found chip")
            chip_length = read_be(contents[chip_pointer+ 4:chip_pointer+ 8])
            chip_type   = read_be(contents[chip_pointer+ 8:chip_pointer+10])
            bank_num    = read_be(contents[chip_pointer+10:chip_pointer+12])
            load_addr   = read_be(contents[chip_pointer+12:chip_pointer+14])
            chip_data = contents[chip_pointer+16:chip_pointer+chip_length]
            print(f"chip_num={chip_num:3d}, chip_length={chip_length:04x}, ",
                    f"chip_type={chip_type}, bank_num={bank_num:2d}, load_addr={load_addr:04x}")
            print_chip(chip_data, 0x7000, chip_num, file_out)
            chip_pointer += chip_length
            chip_num += 1


#convert_file('DblDrgon.crt', 'DblDrgon.txt')
#convert_file('Facemaker.crt', 'Facemaker.txt')

if len(sys.argv) > 2:
    convert_file(sys.argv[1], sys.argv[2])
else:
    convert_file(sys.argv[1], "")

