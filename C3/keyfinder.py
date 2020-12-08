# -*- coding: utf-8 -*-

import os
import sys
import argparse


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--stringobject",
        type=str,
        required=True,
        help="String to process")
    parser.add_argument(
        "--keytofind",
        type=str,
        required=True,
        help="Key to find")

    args = parser.parse_args(sys.argv[1:])

    keyfind(args.stringobject, args.keytofind)

def keyfind(objectstr, keyfind):

    found = False

    objectstr = objectstr.replace('“', '').replace('”','').replace('"','')
    while found == False:
        if objectstr.startswith('{') and objectstr.endswith('}'):
            objectstr = objectstr[1:-1]
        keyarray = objectstr.split(":", 1)
        if len(keyarray)==1:
            print("No value found")
            break
        if keyarray[0]==keyfind:
            found=True
            print(keyarray[1])
        else:
            objectstr=keyarray[1]
            continue


if __name__ == "__main__":
    main()


