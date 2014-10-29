#!/usr/bin/env python
from twisted.internet import reactor

from twisted.protocols import sip
from twisted.internet.protocol import ServerFactory
from twisted.protocols.sip import *

import optparse
import pdb

# Options parser
def parseOptions():
  usage = "usage: %prog [options]"
  parser = optparse.OptionParser(usage=usage);
  parser.add_option('-i', action="store", dest="prox_interface", type="string", help="Interface to listen on")
  parser.add_option('-p', action="store", dest="prox_port", type='int', help="Listening port")
  parser.add_option('-r', action="store", dest="remote_addr", type="string", help="Address where the proxied requests will be sent")
  return parser.parse_args()



class SipProxy(sip.Proxy):

  def __init__(self):
    sip.Proxy.__init__(self,host=opts.prox_interface ,port=opts.prox_port)
    self.tries=0

  def handle_request(self,message,addr):
    print ("Received -----")
    print message.toString()

    # Replace Via header
    viaHeader = self.getVia()
    senderVia = parseViaHeader(message.headers["via"][0])
    viaHeader.branch = senderVia.branch + "1"
    message.headers["via"].insert(0,viaHeader.toString())

    # Change call id
    message.headers["call-id"][0]=message.headers["call-id"][0]+"1"

    # Remove Record-Routes
    message.headers["record-route"]=[]

    # Replace Contact header
    if message.headers.has_key("contact"):
      message.headers["contact"]=[]
      message.headers["contact"].append("<sip:"+opts.prox_interface+":"+str(opts.prox_port)+">")

    addr= opts.remote_addr.split(":");
    if (len(addr) > 1):
      remote_port=int(addr[1])
    else:
      remote_port=5060

    uri = URL(host=addr[0], port=remote_port)

    # Modify Request URI
    message.uri = uri

    d = defer.succeed(uri)
    d.addCallback(self.sendMessage, message)
    d.addErrback(self._cantForwardRequest, message)

    self.tries+=1;


  def handle_response(self, message, addr):
    """Default response handler."""
    v = parseViaHeader(message.headers["via"][0])
    if (v.host, v.port) != (self.host, self.port):
      # we got a message not intended for us?
        # XXX note this check breaks if we have multiple external IPs
        # yay for suck protocols
        log.msg("Dropping incorrectly addressed message")
        return
    del message.headers["via"][0]
    if not message.headers["via"]:
      # this message is addressed to us
      self.gotResponse(message, addr)
      return
    message.headers["call-id"][0]=message.headers["call-id"][0][:-1]

    # Replace Contact header
    if message.headers.has_key("contact"):
      message.headers["contact"]=[]
      message.headers["contact"].append("<sip:"+opts.prox_interface+":"+str(opts.prox_port)+">")

    self.deliverResponse(message)




class sipfactory(ServerFactory):
  protocol=SipProxy

(opts, args) = parseOptions()
reactor.listenUDP(opts.prox_port,SipProxy(),opts.prox_interface)
reactor.run()

