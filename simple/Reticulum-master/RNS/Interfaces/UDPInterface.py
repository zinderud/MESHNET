# Reticulum License
#
# Copyright (c) 2016-2025 Mark Qvist
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# - The Software shall not be used in any kind of system which includes amongst
#   its functions the ability to purposefully do harm to human beings.
#
# - The Software shall not be used, directly or indirectly, in the creation of
#   an artificial intelligence, machine learning or language model training
#   dataset, including but not limited to any use that contributes to the
#   training or development of such a model or algorithm.
#
# - The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from RNS.Interfaces.Interface import Interface
import socketserver
import threading
import socket
import time
import sys
import RNS


class UDPInterface(Interface):
    BITRATE_GUESS = 10*1000*1000
    DEFAULT_IFAC_SIZE = 16

    @staticmethod
    def get_address_for_if(name):
        from RNS.Interfaces import netinfo
        ifaddr = netinfo.ifaddresses(name)
        return ifaddr[netinfo.AF_INET][0]["addr"]

    @staticmethod
    def get_broadcast_for_if(name):
        from RNS.Interfaces import netinfo
        ifaddr = netinfo.ifaddresses(name)
        return ifaddr[netinfo.AF_INET][0]["broadcast"]

    def __init__(self, owner, configuration):
        super().__init__()

        c           = Interface.get_config_obj(configuration)
        name        = c["name"]
        device      = c["device"] if "device" in c else None
        port        = int(c["port"]) if "port" in c else None
        bindip      = c["listen_ip"] if "listen_ip" in c else None
        bindport    = int(c["listen_port"]) if "listen_port" in c else None
        forwardip   = c["forward_ip"] if "forward_ip" in c else None
        forwardport = int(c["forward_port"]) if "forward_port" in c else None

        if port != None:
            if bindport == None:
                bindport = port
            if forwardport == None:
                forwardport = port

        self.HW_MTU = 1064

        self.IN  = True
        self.OUT = False
        self.name = name
        self.online = False
        self.bitrate = UDPInterface.BITRATE_GUESS

        if device != None:
            if bindip == None:
                bindip = UDPInterface.get_broadcast_for_if(device)
            if forwardip == None:
                forwardip = UDPInterface.get_broadcast_for_if(device)


        if (bindip != None and bindport != None):
            self.receives = True
            self.bind_ip = bindip
            self.bind_port = bindport

            def handlerFactory(callback):
                def createHandler(*args, **keys):
                    return UDPInterfaceHandler(callback, *args, **keys)
                return createHandler

            self.owner = owner
            address = (self.bind_ip, self.bind_port)
            socketserver.UDPServer.address_family = socket.AF_INET
            self.server = socketserver.UDPServer(address, handlerFactory(self.process_incoming))

            thread = threading.Thread(target=self.server.serve_forever)
            thread.daemon = True
            thread.start()

            self.online = True

        if (forwardip != None and forwardport != None):
            self.forwards = True
            self.forward_ip = forwardip
            self.forward_port = forwardport


    def process_incoming(self, data):
        self.rxb += len(data)
        self.owner.inbound(data, self)

    def process_outgoing(self,data):
        try:
            udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            udp_socket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            udp_socket.sendto(data, (self.forward_ip, self.forward_port))
            self.txb += len(data)
            
        except Exception as e:
            RNS.log("Could not transmit on "+str(self)+". The contained exception was: "+str(e), RNS.LOG_ERROR)


    def __str__(self):
        return "UDPInterface["+self.name+"/"+self.bind_ip+":"+str(self.bind_port)+"]"

class UDPInterfaceHandler(socketserver.BaseRequestHandler):
    def __init__(self, callback, *args, **keys):
        self.callback = callback
        socketserver.BaseRequestHandler.__init__(self, *args, **keys)

    def handle(self):
        data = self.request[0]
        self.callback(data)