# HTTPS for the stream

`wl-cast start` serves every link twice: plain HTTP on `-p` (8081) and
HTTPS on `-t` (8443).  Most browsers take the HTTP link.  Some refuse plain
HTTP, self-signed certificates or local addresses, cars' browsers among
them (a Tesla's, 2026-11-19), and then the HTTPS link needs a certificate
they trust.

## Three levels

1. **Nothing to do:** the HTTPS port uses a self-signed certificate that
   wl-cast-server makes on first use for the host's addresses
   (`~/.local/state/wl-cast/cert.pem`).  The browser warns once; accept it.
2. **Your own certificate:** put `cert.pem` and `key.pem` in
   `/var/lib/wl-cast/tls/`, readable by the user who runs wl-cast.  The
   server serves them instead.  The name in the certificate has to resolve
   to the host's address on the viewer's network.
3. **wl-cast-cert**, for a browser that also refuses local addresses and
   resolves names through its own DNS (a car's): a real certificate for a
   domain of yours, and the host's hotspot answering for it.

## wl-cast-cert

How it works, as tesla-carplay does it:

- your domain (`stream.example.com`) gets a public A record that is in no
  private range (240.3.3.4 by default), so the car's DNS accepts it;
- a Let's Encrypt certificate is made for it by certbot with a DNS
  challenge, through your DNS provider's API, and renewed when 30 days are
  left;
- the host's hotspot sends that address, ports 443 and 8443, to the
  stream's HTTPS port 8443 (nftables, until the next reboot).  So
  `https://stream.example.com/` works in the car, with no port.

So it only works on the host's own hotspot: on another network nothing
sends that address to the host.  The hotspot may run on `wlan0` or on
`ap0` (beside a Wi-Fi network), with whichever address NetworkManager
gives it.

### Setting it up

1. A domain at a provider with an API: Porkbun works; Cloudflare and
   deSEC scripts are there but have not been run.  At Porkbun, turn API
   Access on for the domain (its Details page) and make an API key.
2. `~/.config/wl-cast/https.conf`, mode 600, your own file (a link or
   another owner's file is refused).  KEY=value lines, read, never run:

   ```sh
   STREAM_DOMAIN=stream.example.com
   STREAM_ADDRESS=240.3.3.4
   DNS_PROVIDER=porkbun
   PORKBUN_API_KEY=pk1_...
   PORKBUN_SECRET_KEY=sk1_...
   ```

3. Run `sudo wl-cast-cert` once (it needs root for certbot, the
   certificate directory and nftables).  It prints the result; a first
   certificate takes about two minutes.
4. Let `wl-cast start` run it from then on: when `https.conf` names a
   domain and the hotspot is up, it calls `sudo -n wl-cast-cert` before
   the server starts (which is when the server reads the certificate), so
   the redirect is back after a reboot and the certificate renewed when
   due.  That needs sudo without a password for it, a sudoers line such as
   `%wheel ALL=(root) NOPASSWD: /usr/bin/wl-cast-cert` (your
   distribution's path to it), else `wl-cast start` says so and goes on
   with the host's own certificate.  Offline (no internet on the host), a
   certificate from before is kept and the redirect still set.
5. Start the stream on the hotspot (`wl-cast start -v hotspot`) and open
   `https://stream.example.com/` in the car.  `wl-cast start` prints that
   link, with the key, before the hotspot's own.

Another provider: a script `wl-cast-dns-NAME` doing what
`dns/wl-cast-dns-porkbun` does (`a NAME ADDRESS`, and certbot's `auth` and
`cleanup` hooks), then `DNS_PROVIDER=NAME`.

### Files

| path | what |
|---|---|
| `/var/lib/wl-cast/tls/cert.pem`, `key.pem` | the certificate the server serves (key readable by group users) |
| `/var/lib/wl-cast/tls/name`, `status` | its name (`wl-cast start` puts it in the links) and the last result |
| `/var/lib/wl-cast/letsencrypt/` | certbot's account and certificates |
| `/var/log/wl-cast-cert.log` | every result |

With no `STREAM_DOMAIN`, wl-cast-cert removes the redirect and the server
goes back to its own certificate.

As root, wl-cast-cert needs `certbot`, `nft`, `curl` and `openssl` in its
PATH (sudo gives a bare one); it says which is missing.  The redirect goes
to port 8443: keep wl-cast's `-t` at its default.
