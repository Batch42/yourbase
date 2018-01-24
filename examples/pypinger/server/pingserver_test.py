'''
This verifies that the pingserver is functioning as expected.
The pingserver should give a specific UDP response ("ping") to the specified UDP message
defined internally by the constant "pingcom"
'''

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


pingcom = 'pingplease' #Must match pingserver.py's "pingcom" constant


class TestPingServer(unittest.TestCase):
    def test_server_up(self):
        self.assertFalse(trade(pingcom) == 'timeout',
                         'Server failed to respond in a timely fashion.')

    def test_server_pinging(self):
        msg = trade(pingcom)
        if msg == 'timeout':
            self.assertTrue(msg == 'ping',
                            'Server failed to respond in a timely fashion.')
        else:
            self.assertTrue(msg == 'ping',
                            'Server gave erroneous response: \"' + msg+'\"')

    def test_server_stability(self):
        self.assertTrue(trade("wrong command") == 'Hello World',
                        'Server responded improperly')


if __name__ == '__main__':
    unittest.main()
