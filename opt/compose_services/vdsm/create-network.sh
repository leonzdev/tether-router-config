docker network create -d macvlan \
    --subnet=192.168.1.0/24 \
    --gateway=192.168.1.2 \
    --ip-range=192.168.1.64/28 \
    -o parent=br-lan dockerlan
