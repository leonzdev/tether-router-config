# tether-router-config
config files and setup steps for an open wrt based router that use multiple usb hotspots as uplinks

The router is based on OpenWRT with custom components to support hotspot tethering, load balancing, and monitoring.

## firewall rules
Set TTL for outgoing packet to battle tethering discrimination.

## mwan3
Load balancing & failover - hotspot uplink can be unstable from time to time. Mwan3 can load balance / failover using multiple connections.

## tether-router-monitor
Usb hotspot connection may drop and requires a hard reset (unplug then plug in). Monitor the situation so I can take action before all connection fail.
