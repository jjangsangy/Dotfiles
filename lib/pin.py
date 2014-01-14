import logging


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def pin_mapping():
    pin_map = []
    for col in range(1,7):
        for row in range(1,7):
            pin_map.append(col,row)

    return pin_map

def main():
    RC = pin_mapping()
    print RC

if __name__ == '__main__':
    main()
