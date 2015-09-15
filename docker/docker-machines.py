#!/usr/bin/env python3

import os

def start(env):
    status = os.system('docker-machine status %s' % env)
    if status == 'Stopped':
        user_input = input('Would you like to start Docker Machine %s: [Yy/Nn]' % env)
        if user_input.strip().lowers()[0] == 'y':
            start_cmd =  'docker-machine start %s' % env[0]
            print('Starting Docker Machine %s' % env[0])
            os.system(start_cmd)


if __name__ == '__main__':
    list_machines = os.popen('docker-machine ls').readlines()[1:]
    for machine in list_machines:
        output = machine.split()
        start(output[0])
