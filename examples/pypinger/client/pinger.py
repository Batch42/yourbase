from socket import *

password = 'ping!ping!ping'

client = socket(AF_INET, SOCK_DGRAM)
client.sendto(password.encode(), ('localhost', 12345))
try:
    message, server = client.recvfrom(16)
    print(message.decode())
except:
    print('Request has timed out')
