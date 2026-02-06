#!/usr/bin/python

import threading
import optparse
import SocketServer
import socket


class rtpThread (threading.Thread):
    def __init__(self, threadID, name, addr):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
        self.server = SocketServer.UDPServer(addr, RTPReceiver)
    def run(self):
        print ("Starting " + self.name)
        self.server.serve_forever()
        print ("Exiting " + self.name)

    def stop(self):
        self.server.shutdown()


class controllerThread (threading.Thread):
    def __init__(self, threadID, name, addr):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
        self.server = ControlServer(addr)
    def run(self):
        print ("Starting " + self.name)

        self.server.listen()
        print ("Exiting " + self.name)

    def stop(self):
        self.server.shutdown()


class RTPReceiver(SocketServer.BaseRequestHandler):

    def handle(self):
        data = self.request[0].strip()
        socket = self.request[1]
        print ("{} wrote:".format(self.client_address[0]))
        print (data)


class ControlServer:
    def __init__(self, addr):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.bind(addr)
        self.rtpListner=None


    def listen(self):
        print ('Opening Control socket')
        self.s.listen(1)
        conn, addr = self.s.accept()
        print ('Connection address:', addr)
        while 1:
            data = conn.recv(1024)
            print ("received data:", data)
            if data.find("start") != -1:
                pos = data.find("start")
                ip, port = data[pos+6:].split(" ",2)
                self.startRtp(ip, int(port))
            elif data.find("stop") != -1:
                self.stopRtp()
                conn.close()
                break

    def startRtp(self, ip, port):
        print ("starting rtp-listner on {}:{}".format(ip,port))
        self.rtpListner = rtpThread(1, "rtp-listner", (ip,port))
        self.rtpListner.start()

    def stopRtp(self):
        self.rtpListner.stop()





if __name__ == "__main__":
    # Options parser
    usage = "usage: %prog [options] ip-address port"
    parser = optparse.OptionParser(usage=usage);
    options, args = parser.parse_args()

    if len(args) !=2:
        parser.error("Incorrect number of arguments");

    controlThrd = controllerThread(1, "control-listner", (args[0], int(args[1])) )
    controlThrd.start()

    print ("Exiting Main Thread")
