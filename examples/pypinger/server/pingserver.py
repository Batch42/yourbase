from socket import *

serv = socket(AF_INET, SOCK_DGRAM)

serv.bind(('', 12345))

password = 'ping!ping!ping'

while True:

        message, addr = serv.recvfrom(16)
        if password == message.decode():
                serv.sendto('ping'.encode(), addr)
