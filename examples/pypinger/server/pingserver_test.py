from socket import *
import unittest

client = socket(AF_INET, SOCK_DGRAM)
client.settimeout(2)


def trade(m):
    global client
    client.sendto(m.encode(), ('localhost', 12345))
    try:
        message, server = client.recvfrom(16)
        return message.decode()
    except Exception:
        return 'timeout'


password = 'ping!ping!ping'


class TestPingServer(unittest.TestCase):
    def test_server_up(self):
        self.assertFalse(trade(password) == 'timeout',
                         'Server failed to respond in a timely fashion.')

    def test_server_pinging(self):
        msg = trade(password)
        if msg == 'timeout':
            self.assertTrue(msg == 'ping',
                            'Server failed to respond in a timely fashion.')
        else:
            self.assertTrue(msg == 'ping',
                            'Server gave erroneous response: \"' + msg+'\"')

    def test_server_secure(self):
        self.assertTrue(trade("wrong password") == 'timeout',
                        'Server responded when it should not have.')


if __name__ == '__main__':
    unittest.main()
