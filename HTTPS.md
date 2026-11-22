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
- the host's hotspot sends that address to the stream's HTTPS port
  (nftables, until the next reboot).

So it only works on the host's own hotspot: on another network nothing
sends that address to the host.

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

3. Run `sudo wl-cast-cert` (it needs root for certbot, the certificate
   directory and nftables).  It prints the result.  Run it again when the
   hotspot starts, or let your hook or distribution do it: it renews when
   needed and is quick otherwise.
4. Start the stream on the hotspot (`wl-cast start -v hotspot`) and open
   `https://stream.example.com:8443/` in the car.

Another provider: a script `wl-cast-dns-NAME` doing what
`dns/wl-cast-dns-porkbun` does (`a NAME ADDRESS`, and certbot's `auth` and
`cleanup` hooks), then `DNS_PROVIDER=NAME`.

### Files

| path | what |
|---|---|
| `/var/lib/wl-cast/tls/cert.pem`, `key.pem` | the certificate the server serves (key readable by group users) |
| `/var/lib/wl-cast/tls/name`, `status` | its name and the last result |
| `/var/lib/wl-cast/letsencrypt/` | certbot's account and certificates |
| `/var/log/wl-cast-cert.log` | every result |

With no `STREAM_DOMAIN`, wl-cast-cert removes the redirect and the server
goes back to its own certificate.
