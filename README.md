# Test case for Traefik - Wrong handling of SNI vs. specific wildcard certificate

This is a Docker Compose stack with helper script to generate usable certificate
to test [Traefik](https://traefik.io) behavior in the case where one wildcard
certificate exists as default SNI certificate, but also a more specific wildcard
certificate handling a subdomain part.

## Usage

Run `./generate_certificates.sh` to generate the following certificates:

-   A "Test CA" certificate that will sign the two other certificates (for IRL
    completeness) in `ca/`.
-   A certificate that is signed with CN `traefik.localhost`, SAN `*.traefik.localhost`
    in `certs/default/`.
-   A certificate that is signed with CN `sub.traefik.localhost`, SAN
    `*.sub.traefik.localhost` in `certs/specific/`.

After running this, boot up the Docker Compose stack with `docker-compose up -d`.
This will run Traefik 2.2 and two test containers to be published through Traefik
via https://whoami.traefik.localhost and https://nginx.sub.traefik.localhost.

Test against these URLs with:

    openssl s_client -connect localhost:443 -showcerts -servername whoami.traefik.localhost
    openssl s_client -connect localhost:443 -showcerts -servername nginx.sub.traefik.localhost

Or use any browser to check the certificate by connecting to these URLs and using the
respective Debugging/Security tool.

## Expected results

-   https://whoami.traefik.localhost and any other subdomain matching
    `*.traefik.localhost` (but NOT `*.sub.traefik.localhost`) uses the
    `CN=traefik.localhost` certificate.
-   https://nginx.sub.traefik.localhost and any other subdomain matching
    `*.sub.traefik.localhost` uses the `CN=sub.traefik.localhost` certificate.

## Actual results

-   https://whoami.traefik.localhost does use the correct certificate.
-   https://nginx.sub.traefik.localhost does NOT use the correct certificate, and
    neither does any subdomain matching `*.sub.traefik.localhost`.

