
"""
This file includes some function like:UDP trans、UART trans、UDP receive。_2024/10/13 by martin_
"""
import socket
import struct
import keyboard
import serial
from serial.tools import list_ports


class fpga_function:
    @staticmethod
    def UDP_transmitter(test, local_ip="127.0.0.1", local_port=1234, target_ip="192.168.1.11", target_port=1234):
        """
        通过UDP发送数据到指定的目标IP和端口。用于测试时，如果test=1，则发送数据到主机。

        :param test: 控制发送的数据，test=1时，发送模拟数据
        :param local_ip: 本地IP地址，默认值为 "127.0.0.1"
        :param local_port: 本地端口，默认值为 1234
        :param target_ip: 目标IP地址，默认值为 "192.168.1.11"
        :param target_port: 目标端口，默认值为 1234
        :return: 无
        """
        # 创建UDP套接字
        udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        local_addr = ('', local_port)
        udp_socket.bind(local_addr)

        # 模拟发送的数据
        udp_trans_data = []
        udp_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1024 * 1024)  # 设置1MB的发送缓冲区
        # test=1 时，发送 1 到 1000 的整数数据
        if test == 1:
            print("UDP 服务器启动成功，等待发送数据...")
            while True:

                integer_data = [i for i in range(1, 1001)]
                for ii in range(len(integer_data)):
                    # 将数据拆分为高字节和低字节
                    high_byte = (integer_data[ii] >> 8) & 0xFF
                    low_byte = integer_data[ii] & 0xFF

                    udp_trans_data.append(low_byte)
                    udp_trans_data.append(high_byte)

                # 将数据通过UDP发送到指定目标
                for i in range(len(udp_trans_data)):
                    data = struct.pack('!B', udp_trans_data[i])  # 将整数打包为一个字节
                    udp_socket.sendto(data, (target_ip, target_port))

                        # 检测键盘按键，如果按下's'，则停止发送
                if keyboard.is_pressed('s'):
                    print("检测到停止信号，停止发送数据...")
                    break

    @staticmethod
    def udp_receive_revised(max_recv = 1024,local_ip="", local_port=1234):

        # 创建UDP套接字
        print("UDP 服务器启动成功，等待接收数据...")
        while 1:
            print('----------------------------UDP RECEIVE-----------------------')
            udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            local_addr = ('', local_port)
            udp_socket.bind(local_addr)

            recv_data = udp_socket.recvfrom(max_recv)
            result_recv_data = recv_data[0].hex()
            print(f'The data of udp received is : {result_recv_data}')
            if keyboard.is_pressed('s'):  # s键停止
                break

    @staticmethod
    def uart_rx(port="COM14", str=b'udp.start.trans\r\r\n'):
        ports_list = list(serial.tools.list_ports.comports())
        if len(ports_list) <= 0:
            print("NO UART EQUIPMENT")
        else:
            ser = serial.Serial(port=port, baudrate=115200, timeout=1)
            while True:
                com_input = ser.read(100)
                print(f'data form uart is :{com_input}')
                if str in com_input:
                    print('----UDP TRANSMISSION----')
                    return 1
                # if com_input:  # 如果读取结果非空，则输出
                #     return com_input

    @staticmethod
    def uart_tx(data, port="COM16"):
        ports_list = list(serial.tools.list_ports.comports())
        if len(ports_list) <= 0:
            print("NO UART EQUIPMENT")
        else:
            ser = serial.Serial(port=port, baudrate=115200)
            write_len = ser.write(data.encode('utf-8'))
            print("串口发出{}个字节。".format(write_len))
            ser.close()

