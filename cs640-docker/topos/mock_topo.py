from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import OVSController
from mininet.cli import CLI
from mininet.log import setLogLevel

class SingleSwitchTopo(Topo):
    "Single switch connected to n hosts."
    def build(self, n=2):
        switch = self.addSwitch('s1')
        for h in range(n):
            host = self.addHost('h%s' % (h + 1))
            self.addLink(host, switch)

def run():
    topo = SingleSwitchTopo(n=2)
    net = Mininet(topo=topo, controller=OVSController)
    net.start()
    
    print("Testing ping...")
    net.pingAll()
    
    print("Testing iperf...")
    h1, h2 = net.get('h1', 'h2')
    h1.cmd('iperf -s -p 5001 &')
    result = h2.cmd('iperf -c %s -p 5001 -t 2' % h1.IP())
    print("Iperf result:")
    print(result)
    
    net.stop()

if __name__ == '__main__':
    setLogLevel('info')
    run()
