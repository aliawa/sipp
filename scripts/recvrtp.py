import socket
import optparse

# Options parser
usage = "usage: %prog [options] ip-address port"
parser = optparse.OptionParser(usage=usage);
options, args = parser.parse_args()

if len(args) !=2:
    parser.error("Incorrect number of arguments");

ip = args[0]
port=int(args[1])
print "connect to : {0} {1}".format(ip,port)

sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
sock.bind((ip, port))

count=0
while True:
    count=count+1
    data, addr = sock.recvfrom(1024) # buffer size is 1024 bytes
    print "received message:", count

