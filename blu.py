import bluetooth

nearby_devices = bluetooth.discover_devices()
print "found %d devices" % len(nearby_devices)

for name, addr in nearby_devices:
     print " %s - %s" % (addr, name)
