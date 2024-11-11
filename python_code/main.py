"""
This code is pc code in FPGA competition _2024/10/13 by martin_
"""

import file_for_fpga


if __name__ == '__main__':
    # based on top1.v 's test
    # a = file_for_fpga.fpga_function()
    # # a.UDP_transmitter(1)
    # a.udp_receive_revised()

    list = [10,1,50,50,10+1+50+50,250]
    b = file_for_fpga.fpga_function()
    for ii in range(0,len(list)):
        # print(list[ii])
        b.uart_tx(list[ii])

