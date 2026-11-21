# wl-cast

Use your Wayland screen from a browser on another device, interactively. Nothing to install on the other side, so it can work in a car web browser as well.

![demo](demo/demo.png)

I wrote it for my Linux phone (an F(x)tec Pro¹x running Guix and Sway), so I can enjoy all my usual Linux utilities and programs (music player, music streaming, and everything else) in my car or on any other machine with a browser. It needs Sway for now (the capture alone works on any wlroots compositor) and a V4L2 hardware H.264 encoder.

## How it works

- `wl-cast-capture` copies the screen into GPU buffers, converts them to NV12 and hands them to the hardware encoder as DMA-BUFs. Pixels never go through the CPU, which decreases latency and increases performance.
- `wl-cast-server` serves the page and streams the video and the sound over WebRTC. Touches and keys come back over a data channel and are played on virtual input devices.
- `wl-cast` starts and stops it: `wl-cast start` asks which screen to stream if you have several and prints the link, `wl-cast stop` ends it.

Two helpers come with it. `wl-cast-screen` streams a screen made at the size of the viewer's window instead of your own (`wl-cast start -s client`), so the picture fills a car's display for instance, and it follows when the window is resized. `wl-cast-cert` gets a real certificate for a domain of yours, for browsers that refuse local addresses and self-signed certificates, like some cars' browsers.

You can add your own scripts around it, _e.g._, `examples/car-bluetooth` starts the hotspot and the stream when the car connects over Bluetooth. Copy it to `~/.local/bin`, set the names at its top, and start it from your Sway config (`exec ~/.local/bin/car-bluetooth`).

## Your own buttons and gestures

The page has a few buttons of its own (sound, keyboard, settings). Add yours in `~/.config/wl-cast/buttons`, one per line with a label and a command/script, _e.g._, a window switcher, a launcher, an on-screen keyboard. `examples/buttons` has placeholders. Three fingers on the page fold or show the buttons.

Everything specific to your host goes in an optional `~/.config/wl-cast/hook` script, see `examples/hook`: keeping the screen awake, Wi-Fi power saving, and your gesture tool on the viewer's touches, so edge swipes work from the stream as they do on the screen for instance.

The screen stays awake while streaming (`-w off` to let it blank), through your hook or else by pausing swayidle. A screen turned off is not captured, so `wl-cast dim` turns it black instead, and back: bind it to your power key, falling back to blanking when it fails (no stream). `-d` starts dimmed. The brightness comes back when the stream ends.

## Performance

Measured on the Pro¹x (Snapdragon 662, Venus encoder), streaming at 960x480 to Chromium on a PC on the same Wi-Fi:

| | |
|---|---|
| screen to encoded frame | about 20 ms, 30 ms at worst |
| frames | 30 per second while the picture moves, none lost |
| screen to browser | about 60-70 ms on a good Wi-Fi link (6-10 ms round trip, 30 ms of browser buffer); a bad link adds hundreds of ms |
| CPU | about 40 % of one core (server 27 %, capture 8 %, sound 8 %), plus 3 % in Sway |
| GPU | about 19 % of its time for the conversion to NV12, plus 1 % in Sway |
| heat | about 6 °C more after a few minutes |
| for comparison, the usual capture path (xdg-desktop-portal-wlr, PipeWire, GStreamer) | frames 400 ms old, more than a core |

Use 5 GHz Wi-Fi if you can: on the 2.4 GHz band of the same router, the phone took 500 ms to reach it, against 8 ms on 5 GHz.

## Install

On Guix, from my channel (add it to `~/.config/guix/channels.scm`):

    (channel
      (name 'mlaparie-guix-private-channel)
      (url "https://git.sr.ht/~mlaparie/guix-private-channel"))

then `guix install wl-cast`.

## Build

Needs wayland, wayland-protocols, wlr-protocols, mesa (gbm, EGL, GLES 2) and libdrm; the server needs Python 3 and GStreamer with its WebRTC plugins.

    make
    make install PREFIX=~/.local

## To do

- KDE and GNOME: capture through the screen-cast portal (PipeWire still gives DMA-BUFs), and through ext-image-copy-capture where the compositor has it.
- Input on other compositors: the virtual devices are fine, but the screen handling uses swaymsg.
- Other encoders than Venus: tested on that one only.

## AI assistance

This project used AI assistance. I am not particularly proud of it, but none of this would have been possible if I were coding it alone. Everything was however directed and tested by a human, with some organic code writing and review as well. Expect rough edges still: this was written and tested on a mobile Linux device only. PRs are welcome.

## License

AGPL-3.0-or-later. The code started in [fxtec-pro1x-guix](https://git.sr.ht/~mlaparie/fxtec-pro1x-guix).
