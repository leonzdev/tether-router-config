# tether-router-config
config files and setup steps for an open wrt based router that use multiple usb hotspots as uplinks

The router is based on OpenWRT with custom components to support hotspot tethering, load balancing, and monitoring.

## OpenWRT
Network config
```
/etc/config/network
```

## firewall rules
Set TTL for outgoing packet to battle tethering discrimination.
```
/etc/firewall.user
```

## mwan3
Load balancing & failover - hotspot uplink can be unstable from time to time. Mwan3 can load balance / failover using multiple connections.
```
/etc/config/mwan3
```

## tether-router-monitor
Usb hotspot connection may drop and requires a hard reset (unplug then plug in). Monitor the situation so I can take action before all connection fail.

Checkout and build with golang: [tether-router-monitor](https://github.com/leonzdev/tether-router-monitor)

Put binary in `/root/.bin` or anywhere in `PATH`
Put dependencies in `/root/.bin` or `PATH`
