# wl-cast

Use your Wayland screen from a browser on another device, interactively. Nothing to install on the other side, so it can work in a car web browser as well.

![demo](demo/demo.png)

I wrote it for my Linux phone (an F(x)tec Pro¹x running Guix and Sway), so I can enjoy all my usual Linux utilities and programs (music player, music streaming, and everything else). It needs Sway for now (the capture alone works on any wlroots compositor) and a V4L2 hardware H.264 encoder.

## How it works

- `wl-cast-capture` copies the screen into GPU buffers, converts them to NV12 and hands them to the hardware encoder as DMA-BUFs. Pixels never go through the CPU, which decreases latency and increases performance.
- `wl-cast-server` serves the page and streams the video and the sound over WebRTC. Touches and keys come back over a data channel and are played on virtual input devices.
- `wl-cast` starts and stops it: `wl-cast start` asks which screen to stream if you have several and prints the link, `wl-cast stop` ends it.

Also included: `wl-cast-screen` gives the viewer a screen of its own at its size, and `wl-cast-cert` gets a real certificate for browsers that refuse local addresses. `examples/car-bluetooth` starts the hotspot and the stream automatically when the car connects to Bluetooth.

## Your own buttons and gestures

The page has a few buttons of its own (sound, keyboard, settings). Add yours in `~/.config/wl-cast/buttons`, one per line with a label and a command/script, _e.g._, a window switcher, a launcher, an on-screen keyboard. `examples/buttons` has placeholders. Three fingers on the page fold or show the buttons.

Everything specific to your host goes in an optional `~/.config/wl-cast/hook` script, see `examples/hook`: keeping the screen awake, Wi-Fi power saving, and your gesture tool on the viewer's touches, so edge swipes work from the stream as they do on the screen for instance.

## Latency

Measured on the Pro¹x (Snapdragon 662, Venus encoder):

| | |
|---|---|
| screen to encoded frame | 32-45 ms |
| screen to browser, same Wi-Fi | about 70 ms |
| CPU for capture and encoding | about 4 % of a core |
| GPU for the conversion to NV12 | about 2.5 % of its time (1600x800, 20 fps); Sway's copy adds nothing measurable |
| through the screen-cast portal instead | 400 ms and more than a core |

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

AI assistance was significant in writing this project. I decided what to build and tested the results on my phone and in my car. Expect rough edges; reports are welcome.

## License

AGPL-3.0-or-later. The code started in [fxtec-pro1x-guix](https://git.sr.ht/~mlaparie/fxtec-pro1x-guix).
