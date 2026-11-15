#!/usr/bin/env python3
"""Capture real QEMU QMP framebuffer and validate it is not blank; Python stdlib."""
import argparse
import binascii
import json
import pathlib
import socket
import struct
import time
import zlib


def parse_ppm(raw):
    cursor = 0

    def token():
        nonlocal cursor
        while cursor < len(raw):
            value = raw[cursor]
            if value in b" \t\n\r":
                cursor += 1
            elif value == 35:
                end = raw.find(b"\n", cursor)
                if end < 0:
                    raise ValueError("Unterminated PPM comment")
                cursor = end + 1
            else:
                break
        start = cursor
        while cursor < len(raw) and raw[cursor] not in b" \t\n\r#":
            cursor += 1
        return raw[start:cursor]

    if token() != b"P6":
        raise ValueError("QEMU screenshot is not PPM P6")
    width, height, maxval = int(token()), int(token()), int(token())
    if not (320 <= width <= 8000 and 240 <= height <= 8000 and maxval == 255):
        raise ValueError(f"Unsupported framebuffer: {width}x{height}, maxval={maxval}")
    if cursor >= len(raw) or raw[cursor] not in b" \t\n\r":
        raise ValueError("Malformed PPM header")
    cursor += 1
    pixels = raw[cursor:cursor + width * height * 3]
    if len(pixels) != width * height * 3:
        raise ValueError("Incomplete framebuffer pixel data")
    return width, height, pixels


def png_from_rgb(width, height, rgb):
    def chunk(kind, payload):
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", binascii.crc32(kind + payload) & 0xffffffff))
    stride = width * 3
    scanlines = b"".join(b"\0" + rgb[i * stride:(i + 1) * stride] for i in range(height))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(scanlines, 6)) + chunk(b"IEND", b""))


def verify_pixels(width, height, pixels):
    if width < 800 or height < 600:
        raise ValueError(f"Framebuffer resolution too small: {width}x{height}")
    step = max(3, (width * height // 5000) * 3)
    sample = [pixels[i:i + 3] for i in range(0, len(pixels) - 2, step)]
    ratio = sum(max(px) > 30 and max(px) - min(px) > 5 for px in sample) / max(len(sample), 1)
    if ratio < 0.03:
        raise ValueError(f"QEMU framebuffer looks blank/monochrome: {ratio:.2%} colored pixels")
    return ratio


def capture(qmp_path, ppm):
    """QMP is a structured JSON protocol, unlike HMP's interactive echoed input."""
    connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    connection.settimeout(20)
    connection.connect(qmp_path)
    with connection, connection.makefile("rwb", buffering=0) as stream:
        greeting = json.loads(stream.readline())
        if "QMP" not in greeting:
            raise RuntimeError(f"Invalid QMP greeting: {greeting!r}")

        def execute(command, arguments=None):
            request = {"execute": command}
            if arguments is not None:
                request["arguments"] = arguments
            stream.write(json.dumps(request).encode("utf-8") + b"\n")
            for _ in range(80):
                response = json.loads(stream.readline())
                if "event" in response:
                    continue
                if "error" in response:
                    raise RuntimeError(f"QMP {command} error: {response['error']}")
                if "return" in response:
                    return
            raise RuntimeError(f"QMP {command}: no command response")

        execute("qmp_capabilities")
        execute("screendump", {"filename": str(ppm), "format": "ppm"})
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        if ppm.is_file() and ppm.stat().st_size > 4096:
            return
        time.sleep(0.2)
    raise RuntimeError("QMP screendump reported success, but no image was written")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("monitor", nargs="?")
    parser.add_argument("png", nargs="?")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        width, height = 800, 600
        fixture = b"P6\n# test\n800 600\n255\n" + bytes((70, 110, 200)) * (width * height)
        w, h, pixels = parse_ppm(fixture)
        assert verify_pixels(w, h, pixels) > 0.5
        assert png_from_rgb(w, h, pixels).startswith(b"\x89PNG")
        print("QEMU PPM parser, pixel validation and PNG encoding: OK")
        return
    if not args.monitor or not args.png:
        parser.error("monitor socket and destination PNG are required")
    dest = pathlib.Path(args.png).resolve()
    dest.parent.mkdir(parents=True, exist_ok=True)
    ppm = dest.with_suffix(".ppm")
    capture(args.monitor, ppm)
    w, h, pixels = parse_ppm(ppm.read_bytes())
    ratio = verify_pixels(w, h, pixels)
    dest.write_bytes(png_from_rgb(w, h, pixels))
    ppm.unlink(missing_ok=True)
    print(f"QEMU graphical framebuffer: {w}x{h}; colored pixels {ratio:.1%}; saved {dest}")


if __name__ == "__main__":
    main()
