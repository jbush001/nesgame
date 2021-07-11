#!/bin/bash

set -e

dasm game.asm -f3 -lgame.lst -oprgrom.bin
python3 mkrom.py prgrom.bin graphics.txt
nestopia game.nes
