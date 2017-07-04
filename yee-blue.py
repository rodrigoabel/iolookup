#!/usr/bin/python

import bluetooth
import time
import RPi.GPIO as GPIO, os
from yeelight import Bulb


print "in / out program"

GPIO.setmode(GPIO.BCM)
bulb = Bulb("192.168.1.35")
GPIO.setup(23, GPIO.OUT)

while True:
	print "checkeando" + time.strftime("%a, %d %b %Y %H: %M: %S", time.gmtime())

	result = bluetooth.lookup_name('A0:99:9B:3C:E5:20',timeout=5)
	if (result != None):
		print "IN :D"
		GPIO.output(23, True)
                bulb.turn_on()
	else:
		print "OUT :("
		GPIO.output(23, False)
                bulb.turn_off()
	time.sleep(1)
