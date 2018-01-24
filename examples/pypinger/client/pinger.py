'''
Ask server to ping
'''


from socket import *

pingcom = 'pingplease'

client = socket(AF_INET, SOCK_DGRAM)
client.sendto(pingcom.encode(), ('localhost', 12345))
try:
    message, server = client.recvfrom(16)
    print(message.decode())
except:
    print('Request has timed out')
