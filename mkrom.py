"""Create a ROM image from graphics assets and assembled binary code.

Format: https://wiki.nesdev.com/w/index.php/INES
"""

import math
import sys

class PatternTable:
    def __init__(self):
        self.contents = bytearray(b'\00' * 0x2000)
        self.next_sprite = 0

    def _copy_tile(self, tile_index, color_data, color_start, stride):
        """Copy an 8x8 tile into graphics memory.

        Tiles are used both for backgrounds and sprites. These are stored in a planar
        format.

        Params:
            tile_index (int) Index of tile to write (0-511)
            color_data (list<int>) Each pixel is a number 0-3
            color_start (int) Index into color data to begin copying from.
            stride (int) Number of pixels between two adjacent pixels in the same column.
        """
        tile_base_addr = tile_index * 16
        for y in range(8):
            plane0_byte = 0
            plane1_byte = 0
            for x in range(8):
                pixel = color_data[color_start + y * stride + x]
                plane0_byte |= (pixel & 1) << (7 - x)
                plane1_byte |= ((pixel >> 1) & 1) << (7 - x)

            self.contents[tile_base_addr + y] = plane0_byte
            self.contents[tile_base_addr + 8 + y] = plane1_byte

    def copy_sprite(self, width, height, color_data):
        """Copy a sprite into graphics memory.

        This will be broken into 8x8 tiles, which will be written in order,
        left to right, top to bottom.

        Params:
            width (int) Width of the sprite in pixels. Must be multiple of 8.
            height (int) Height of sprite in pixels. Must be multiple of 8.
            color_data (list<int>) List of pixel colors, 0-3.

        Returns:
            (int) Index of first tile.
        """
        tile_index = self.next_sprite
        width_tiles = width // 8
        height_tiles = height // 8
        for y in range(height_tiles):
            for x in range(width_tiles):
                self._copy_tile(tile_index + y * width_tiles + x, color_data, (y * width + x) * 8, width)

        self.next_sprite += width_tiles * height_tiles
        return tile_index


def parse_text_sprites(f):
    """Read ASCII sprites and copy all into a pattern ROM."""
    color_data = []
    sprite_width = 0
    def add_sprite():
        nonlocal color_data
        index = pat.copy_sprite(sprite_width, len(color_data) // sprite_width, color_data)
        print('wrote sprite @', index)
        color_data = []

    pat = PatternTable()
    for line in f.readlines():
        sline = line.strip()
        if sline == '' and color_data:
            # blank lines end a sprite
            add_sprite()
        else:
            sprite_width = len(sline)
            color_data += ['.123'.find(ch) for ch in sline]

    if color_data:
        add_sprite()

    return pat.contents

def main():
    with open(sys.argv[1], 'rb') as code_file:
        code = code_file.read()

    with open(sys.argv[2], 'r') as graphic_file:
        chrom = parse_text_sprites(graphic_file)

    with open('game.nes', 'wb') as output_file:
        # Header
        output_file.write(b'NES\x1a\x01\x01\x11\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        output_file.write(code)    # PRG ROM (padded)
        output_file.write(chrom)   # Pattern ROM

if __name__ == '__main__':
    main()
