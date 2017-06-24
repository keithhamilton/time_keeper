#!/usr/bin/python

import time

import requests
import RPi.GPIO as GPIO

JOB_ENDPOINT = 'http://0.0.0.0:4000/jobs/switch'


if __name__ == '__main__':

    GPIO.setmode(GPIO.BCM)

    pins = [14, 15, 17, 18, 22, 23, 27]
    for pin in pins:
        GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    while True:
        for pin in PINS:
            if not GPIO.input(pin):
                requests.post(JOB_ENDPOINT, data = {'job_switch_id': pin})

        time.sleep(0.3)
