"""
This code is pc code in FPGA competition _2024/10/13 by martin_
"""

import file_for_fpga


if __name__ == '__main__':
    # based on top1.v 's test
    a = file_for_fpga.fpga_function()
    a.UDP_transmitter(1)