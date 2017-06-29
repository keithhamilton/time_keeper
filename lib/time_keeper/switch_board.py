#!/usr/bin/python

import time

import requests
import RPi.GPIO as GPIO

from sh import mpg123

JOB_ENDPOINT = 'https://aqueous-garden-74263.herokuapp.com/work/switch'
AUDIO_PATH = '/home/pi/time_keeper/web/static/assets/audio/{}.mp3'

if __name__ == '__main__':

    GPIO.setmode(GPIO.BCM)

    pins = [14, 15, 17, 18, 22, 23, 27]
    for pin in pins:
        GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    while True:
        for pin in pins:
            if not GPIO.input(pin):
                resp = requests.post(JOB_ENDPOINT, data = {'button_pin': pin})

                mpg123(AUDIO_PATH.format(resp.text))

        time.sleep(0.3)
