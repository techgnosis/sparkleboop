#!/usr/bin/env python3
"""Generate Sparkleboop launcher icons using only stdlib (struct + zlib)."""

import math
import os
import struct
import zlib

def create_png(width, height, pixels):
    """Create a PNG file from RGBA pixel data."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack('>I', len(data)) + c + crc

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))

    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter none
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw += struct.pack('BBBB', r, g, b, a)

    idat = chunk(b'IDAT', zlib.compress(raw, 9))
    iend = chunk(b'IEND', b'')
    return header + ihdr + idat + iend


def lerp(a, b, t):
    return int(a + (b - a) * t)


def blend(c1, c2, t):
    """Blend two RGBA colors."""
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t),
            lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t))


def dist(x1, y1, x2, y2):
    return math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)


def point_in_diamond(px, py, cx, cy, w, h):
    """Check if point is inside a diamond shape centered at (cx, cy)."""
    dx = abs(px - cx) / (w / 2)
    dy = abs(py - cy) / (h / 2)
    return dx + dy <= 1.0


def point_in_rounded_rect(px, py, x1, y1, x2, y2, radius):
    """Check if point is inside a rounded rectangle."""
    if px < x1 or px > x2 or py < y1 or py > y2:
        return False
    # Check corners
    corners = [(x1 + radius, y1 + radius),
               (x2 - radius, y1 + radius),
               (x1 + radius, y2 - radius),
               (x2 - radius, y2 - radius)]
    for cx, cy in corners:
        if ((px < x1 + radius or px > x2 - radius) and
            (py < y1 + radius or py > y2 - radius)):
            if dist(px, py, cx, cy) > radius:
                return False
    return True


def generate_icon(size):
    """Generate a sparkleboop icon at the given size."""
    pixels = [(0, 0, 0, 0)] * (size * size)
    center = size / 2
    margin = size * 0.02
    radius = size * 0.18

    # Colors
    bg_top = (48, 10, 80)       # deep purple
    bg_bot = (20, 5, 45)        # darker purple
    diamond_top = (255, 100, 180)  # pink
    diamond_mid = (220, 50, 140)   # magenta
    diamond_bot = (180, 30, 100)   # dark magenta
    highlight = (255, 200, 240)    # light pink
    facet_light = (255, 150, 210)  # mid pink
    sparkle_color = (255, 255, 255, 255)

    for y in range(size):
        for x in range(size):
            idx = y * size + x
            nx = x / size  # normalized coords
            ny = y / size

            # Rounded rect background
            if not point_in_rounded_rect(x, y, margin, margin,
                                          size - 1 - margin, size - 1 - margin, radius):
                pixels[idx] = (0, 0, 0, 0)
                continue

            # Background gradient (top to bottom)
            bg = blend(bg_top + (255,), bg_bot + (255,), ny)

            # Add subtle radial glow in center
            d = dist(nx, ny, 0.5, 0.45) / 0.5
            if d < 1.0:
                glow = (80, 30, 120, 255)
                bg = blend(bg, glow, max(0, (1.0 - d) * 0.4))

            # Diamond shape - main gem
            dw = size * 0.52
            dh = size * 0.58
            if point_in_diamond(x, y, center, center * 0.95, dw, dh):
                # Vertical gradient on diamond
                local_y = (y - (center * 0.95 - dh / 2)) / dh
                local_y = max(0, min(1, local_y))

                if local_y < 0.35:
                    gem = blend(highlight + (255,), diamond_top + (255,), local_y / 0.35)
                elif local_y < 0.65:
                    gem = blend(diamond_top + (255,), diamond_mid + (255,), (local_y - 0.35) / 0.3)
                else:
                    gem = blend(diamond_mid + (255,), diamond_bot + (255,), (local_y - 0.65) / 0.35)

                # Facet lines - create diamond facets
                rel_x = (x - center) / (dw / 2)
                rel_y = (y - center * 0.95) / (dh / 2)

                # Upper facet highlight (top triangle)
                if rel_y < 0 and abs(rel_x) < 0.3 - rel_y * 0.3:
                    gem = blend(gem, (255, 220, 245, 255), 0.3)

                # Left facet
                if rel_x < -0.1 and abs(rel_y) < 0.5:
                    darken = 0.15
                    gem = (max(0, gem[0] - int(darken * 60)),
                           max(0, gem[1] - int(darken * 60)),
                           max(0, gem[2] - int(darken * 40)),
                           255)

                # Facet edge lines
                # Horizontal middle
                if abs(rel_y - 0.05) < 0.03:
                    gem = blend(gem, facet_light + (255,), 0.5)
                # Upper left diagonal
                if abs(rel_x + rel_y * 0.8) < 0.04 and rel_y < 0.05:
                    gem = blend(gem, facet_light + (255,), 0.4)
                # Upper right diagonal
                if abs(rel_x - rel_y * 0.8) < 0.04 and rel_y < 0.05:
                    gem = blend(gem, facet_light + (255,), 0.4)
                # Lower left diagonal
                if abs(rel_x * 0.6 + rel_y * 0.5 - 0.05) < 0.04 and rel_y > 0.05:
                    gem = blend(gem, facet_light + (255,), 0.3)
                # Lower right diagonal
                if abs(rel_x * 0.6 - rel_y * 0.5 + 0.05) < 0.04 and rel_y > 0.05:
                    gem = blend(gem, facet_light + (255,), 0.3)

                bg = gem

            # Small highlight sparkle at top-right of diamond
            sparkle_cx, sparkle_cy = center + size * 0.1, center * 0.95 - size * 0.15
            sd = dist(x, y, sparkle_cx, sparkle_cy)
            if sd < size * 0.04:
                t = 1.0 - sd / (size * 0.04)
                bg = blend(bg, sparkle_color, t * 0.9)

            pixels[idx] = bg

    # Add sparkle accents around the diamond
    sparkle_positions = [
        (0.22, 0.25), (0.78, 0.30), (0.18, 0.70),
        (0.82, 0.65), (0.35, 0.15), (0.70, 0.80),
    ]
    for sx, sy in sparkle_positions:
        scx = int(sx * size)
        scy = int(sy * size)
        r = max(1, int(size * 0.015))
        for dy in range(-r * 3, r * 3 + 1):
            for dx in range(-r * 3, r * 3 + 1):
                px, py = scx + dx, scy + dy
                if px < 0 or px >= size or py < 0 or py >= size:
                    continue
                idx = py * size + px
                if pixels[idx][3] == 0:  # skip transparent
                    continue
                # Cross/star sparkle shape
                is_sparkle = False
                adx, ady = abs(dx), abs(dy)
                if adx <= r and ady <= r:
                    is_sparkle = True  # center dot
                elif (adx <= 1 and ady <= r * 2) or (ady <= 1 and adx <= r * 2):
                    is_sparkle = True  # cross arms

                if is_sparkle:
                    d = dist(dx, dy, 0, 0) / (r * 3)
                    t = max(0, 1.0 - d) * 0.7
                    pixels[idx] = blend(pixels[idx], sparkle_color, t)

    return create_png(size, size, pixels)


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    res_dir = os.path.join(project_dir, 'android', 'app', 'src', 'main', 'res')

    densities = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    for folder, size in densities.items():
        out_path = os.path.join(res_dir, folder, 'ic_launcher.png')
        print(f'Generating {folder}/ic_launcher.png ({size}x{size})...')
        png_data = generate_icon(size)
        with open(out_path, 'wb') as f:
            f.write(png_data)
        print(f'  -> {len(png_data)} bytes')

    print('\nDone! All icons generated.')


if __name__ == '__main__':
    main()
