from pox.core import core
import pox.openflow.libopenflow_01 as of
from pox.lib.revent import *
import os
import sys

log = core.getLogger()
IPCONFIG_FILE = './ip_config'
IP_SETTING = {}


class VNetDevInfo(Event):
  '''Event to raise when the info about an OF switch is ready'''
  def __init__(self, ifaces, swid, dpid):
    Event.__init__(self)
    self.ifaces = ifaces
    self.swid = swid
    self.dpid = dpid


class VNetOFDevHandler(EventMixin):
  def __init__(self, connection):
    self.connection = connection
    self.dpid = connection.dpid % 1000
    log.debug("dpid=%s", self.dpid)
    swifaces = {}
    self.connection.send(of.ofp_set_config(miss_send_len=65535))
    for port in connection.features.ports:
      intf_name = port.name.split('-')
      if len(intf_name) < 2:
        continue
      else:
        self.swid = intf_name[0]
        intf_name = intf_name[1]
      if port.name in IP_SETTING.keys():
        swifaces[intf_name] = (IP_SETTING[port.name][0],
            IP_SETTING[port.name][1], port.hw_addr.toStr(), port.port_no)
      else:
        swifaces[intf_name] = (None, None, None, port.port_no)

    self.listenTo(connection)
    self.listenTo(core.VNetHandler)
    core.VNetOFNetHandler.raiseEvent(
        VNetDevInfo(swifaces, self.swid, self.dpid))

  def _handle_PacketIn(self, event):
    '''Handles packet in messages from the OF device'''
    pkt = event.parse()
    raw_packet = pkt.raw
    core.VNetOFNetHandler.raiseEvent(
        VNetPacketIn(raw_packet, event.port, self.swid))
    msg = of.ofp_packet_out()
    msg.buffer_id = event.ofp.buffer_id
    msg.in_port = event.port
    self.connection.send(msg)

  def _handle_VNetPacketOut(self, event):
    if event.swid != self.swid:
      return
    msg = of.ofp_packet_out()
    new_packet = event.pkt
    msg.actions.append(of.ofp_action_output(port=event.port))
    msg.in_port = of.OFPP_NONE
    msg.data = new_packet
    self.connection.send(msg)


class VNetPacketIn(Event):
  '''Event to raise upon receiving a packet_in from openflow'''
  def __init__(self, packet, port, swid):
    Event.__init__(self)
    self.pkt = packet
    self.port = port
    self.swid = swid


class VNetOFNetHandler(EventMixin):
  '''Waits for OF switches to connect and makes them simple routers'''
  _eventMixin_events = set([VNetPacketIn, VNetDevInfo])

  def __init__(self):
    EventMixin.__init__(self)
    self.listenTo(core.openflow)

  def _handle_ConnectionUp(self, event):
    log.debug("Connection %s" % (event.connection,))
    # Install table-miss flow rule: send all unmatched packets to controller
    msg = of.ofp_flow_mod()
    msg.priority = 0
    msg.actions.append(of.ofp_action_output(port=of.OFPP_CONTROLLER, max_len=65535))
    event.connection.send(msg)
    VNetOFDevHandler(event.connection)


def get_ip_setting():
  if not os.path.isfile(IPCONFIG_FILE):
    return -1
  with open(IPCONFIG_FILE, 'r') as f:
    for line in f:
      parts = line.split()
      if len(parts) == 0:
        break
      name, ip, mask = parts
      IP_SETTING[name] = [ip, mask]
  return 0


def launch():
  '''Starts a virtual network topology'''
  core.registerNew(VNetOFNetHandler)

  r = get_ip_setting()
  if r == -1:
    log.error("Failed to load VNet config file %s" % IPCONFIG_FILE)
    sys.exit(2)
  else:
    log.info('Successfully loaded VNet config file\n %s\n' % IP_SETTING)
