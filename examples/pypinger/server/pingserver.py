'''
pings client when asked
Otherwise presents default message
'''

from socket import *

serv = socket(AF_INET, SOCK_DGRAM)

serv.bind(('', 12345))

pingcom = 'pingplease'

while True:

        message, addr = serv.recvfrom(16)
        if pingcom == message.decode():
            serv.sendto('ping'.encode(), addr)
        else:
            serv.sendto('Hello World'.encode(), addr)
