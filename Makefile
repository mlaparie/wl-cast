PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra
PKGS = wayland-client gbm egl glesv2 libdrm

WL_PROTOCOLS := $(shell pkg-config --variable=pkgdatadir wayland-protocols)
WLR_PROTOCOLS := $(shell pkg-config --variable=pkgdatadir wlr-protocols)
XMLS = $(WL_PROTOCOLS)/stable/linux-dmabuf/linux-dmabuf-v1.xml \
       $(WLR_PROTOCOLS)/unstable/wlr-screencopy-unstable-v1.xml
GEN = $(foreach x,$(XMLS),capture/$(basename $(notdir $(x))))

SCRIPTS = wl-cast wl-cast-server wl-cast-screen wl-cast-cert wl-cast-output \
          dns/wl-cast-dns-cloudflare dns/wl-cast-dns-desec dns/wl-cast-dns-porkbun

all: capture/wl-cast-capture

capture/%-client-protocol.h: $(XMLS)
	wayland-scanner client-header $(filter %/$*.xml,$(XMLS)) $@

capture/%-protocol.c: $(XMLS)
	wayland-scanner private-code $(filter %/$*.xml,$(XMLS)) $@

capture/wl-cast-capture: capture/wl-cast-capture.c $(GEN:=-client-protocol.h) $(GEN:=-protocol.c)
	$(CC) $(CFLAGS) -Icapture -o $@ capture/wl-cast-capture.c $(GEN:=-protocol.c) \
		$(shell pkg-config --cflags --libs $(PKGS)) $(LDFLAGS)

install: all
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 capture/wl-cast-capture $(SCRIPTS) $(DESTDIR)$(BINDIR)

clean:
	rm -f capture/wl-cast-capture capture/*-protocol.c capture/*-client-protocol.h

.PHONY: all install clean
