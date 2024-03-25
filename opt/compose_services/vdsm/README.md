# Setup VDSM
https://github.com/vdsm/virtual-dsm

Running DSM in KVM vm that is isolated in a docker container. Managed by docker compose

## Prerequisite
* Docker
* Docker compose
* Macvlan kmod

## Network setup
### Goals
To set up VDSM in a way that is least likely to interfere with the operation of the host OpenWRT system
* Give the VDSM container a separate IP
* Expose all necessary ports without manual port mapping
* Make the services exposed by VDSM accessible to LAN

### Steps
Nees to setup `macvlan` with some tricks
* Carve out a range of IPs for docker `macvlan` interfaces. Here we use `192.168.1.64/28` which ranges from 192.168.1.64 to 192.168.1.95
* Create a `macvlan` device (`/etc/config/network`)
* ```
  config device
	option type 'macvlan'
	option ifname 'br-lan'
	option mode 'bridge'
	option name 'docker-lan-shim'
  ```
* Create a shim interface on the device (`/etc/config/network`)
* ```
  config interface 'dockerlanshim'
	option proto 'static'
	option device 'docker-lan-shim'
	option ipaddr '192.168.1.2'
	option netmask '255.255.255.255'
  ```
* Create a route so that all hosts use the shim interface to communicate with docker containers' `macvlan` interfaces
  * Create a static route for the OpenWRT host (`/etc/config/network`)
  * ```
    config route
	  option interface 'dockerlanshim'
	  option target '192.168.1.64/28'
    ```
  * Create a static DHCP route that is broadcasted to LAN hosts (`/etc/config/dhcp`)
  * ```
    config dhcp 'lan'
  	option interface 'lan'
  	option start '100'
  	option limit '150'
  	option leasetime '12h'
  	option dhcpv4 'server'
  	option dhcpv6 'server'
  	option ra 'server'
  	list ra_flags 'managed-config'
  	list ra_flags 'other-config'
    # Static route to use 192.168.1.2 for traffic to 192.168.1.64/28
  	list dhcp_option '121,192.168.1.64/28,192.168.1.2'

    ```
    The static DHCP route is necessary because otherwise LAN hosts will be able to ping the VDSM's IP (example: 192.168.1.64) but won't be able to open the web page. I think
    this is a bug (or feature?) with the way the VDSM container is set up: there container sets up multiple network interfaces and give 1 of them to the qemu VM *within* the container.

    The embedded the VM then starts up the web server to host the management page and other services on the network interface.

    With a direct connection, hosts on LAN would be able to reach services on the VDSM IP (example: 192.168.1.64) if they were started up from within the container
    but outside of the VM (you can attach to the container and try to run nginx then curl 192.168.1.64:5000 from LAN) but they would fail to reach services started
    up within the VM (192.168.1.64:5000).

    When routed through the `dockerlanshim` interface, however, LAN hosts would reach the embedded VM host's network. The static DHCP route is essential to enforce such routing rule

* Create a `macvlan` docker network
* ```bash
  docker network create -d macvlan \
    --subnet=192.168.1.0/24 \
    --gateway=192.168.1.2 \
    --ip-range=192.168.1.64/28 \
    -o parent=br-lan dockerlan 
  ```
* Use `macvlan` in `docker-compose.yml`
* ```yaml
  version: "3"
  networks:
    dockerlan:
      name: dockerlan
      external: true
  services:
    dsm:
      container_name: dsm
      image: vdsm/virtual-dsm
      environment:
        ...
      devices:
        - /dev/kvm
        - /dev/vhost-net
      networks:
       - dockerlan
      device_cgroup_rules:
        - 'c *:* rwm'      
      cap_add:
        - NET_ADMIN
      volumes:
        ...
      restart: on-failure
      stop_grace_period: 2m
  ```

## VDSM setup
Once network is setup, follow instructions from the [virtual-dsm repo](https://github.com/vdsm/virtual-dsm/blob/master/readme.md)
