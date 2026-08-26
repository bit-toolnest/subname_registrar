# Subname Registrar

## Overview

`subname_registrar` is the central-server component used to expose a user's local service through the Bitone tunnel infrastructure.

The current design keeps the existing reverse-SSH tunnel model and dynamically creates Nginx routes for each registered user.

The primary public route is:

```text
https://<user>.bitone.in
```

The user is mapped to a dedicated localhost port on the central server. Nginx proxies the user's hostname to that port, and the reverse SSH tunnel forwards the traffic to the user's local service.

```text
Browser
   |
   | https://alice.bitone.in
   v
Nginx
   |
   | proxy_pass http://127.0.0.1:<allocated-port>
   v
Central tunnel port
   |
   | Reverse SSH
   v
User machine :8080
```

---

## Installation

The normal installation entry point is:

```bash
./gradlew install
```

The installation flow is:

```text
./gradlew install
        |
        v
Gradle installs dependencies
        |
        v
source set_env.sh
        |
        v
src/install.sh                 # router only
        |
        | sudo + required environment
        v
src/main/install.sh            # actual installer
```

### Environment

`set_env.sh` provides the common exported environment used by the Gradle installation flow. In particular, `DOMAIN` is resolved before the router is called.

`src/install.sh` does not source `set_env.sh` and does not resolve the domain. It only locates and invokes `src/main/install.sh`.

The required `DOMAIN` value is passed through the `sudo` environment to the main installer.

---

## Installer Responsibilities

`src/main/install.sh` performs the privileged installation work, including:

- OS package installation/checks
- Python virtual environment setup
- Flask installation
- SSH Certificate Authority setup
- Token store initialization
- User-port mapping initialization
- Installation of `sign_service.py`
- Installation and activation of `sign_service.service`
- Installation of administrator scripts
- Nginx site configuration
- Nginx configuration validation and reload
- Post-install verification

The main installer is intentionally run with `sudo` from the router so that privileged operations can remain in the main installer.

---

## Installed Administrative Commands

The installer places the administration scripts under `/usr/local`.

```text
/usr/local/sbin/add_token.sh
/usr/local/sbin/revoke_token.sh
/usr/local/sbin/alloc_user_port.sh
/usr/local/sbin/remove_user_port.sh
/usr/local/bin/regen_nginx_routes.sh
```

The signing service is installed as:

```text
/usr/local/bin/sign_service.py
/etc/systemd/system/sign_service.service
```

---

## Registering a User

The main administrator command is:

```bash
sudo /usr/local/sbin/add_token.sh "alice" "bitresearch" 3600
```

Arguments are:

```text
add_token.sh <username> <principal> <max_ttl_seconds>
```

Example:

```bash
sudo /usr/local/sbin/add_token.sh "alice" "bitresearch" 3600
```

This creates a token for `alice` with:

- SSH principal: `bitresearch`
- maximum certificate TTL: `3600` seconds
- active status: `true`
- an allocated central tunnel port

### Internal registration flow

`add_token.sh` is responsible for the complete registration sequence. It calls the port allocator and then regenerates the Nginx routes:

```text
add_token.sh
    |
    +--> alloc_user_port.sh
    |       |
    |       +--> allocate/reuse user port
    |
    +--> save token + user + principal + TTL + port
    |
    +--> regen_nginx_routes.sh
            |
            +--> generate Nginx route
            +--> validate nginx configuration
            +--> reload nginx only after successful validation
```

Therefore, the administrator normally needs to run only `add_token.sh`; there is no need to manually run `alloc_user_port.sh` or `regen_nginx_routes.sh` for normal user registration.

A successful command prints the generated token. The token should be supplied to the client through the intended secure channel.

---

## Port Allocation

`alloc_user_port.sh` maintains:

```text
/etc/tunnel/user_ports.json
```

The default allocation range is:

```text
9001 - 9100
```

The same username receives its existing port if it is already present. Otherwise, the first free port in the configured range is allocated.

A lock is used to prevent concurrent allocation operations from assigning the same port.

---

## Token Store

Tokens are stored in:

```text
/etc/tunnel/tunnel_tokens.json
```

A token entry contains the user name, allowed SSH principals, maximum certificate TTL, allocated port, and active state.

Conceptually:

```json
{
  "tokens": {
    "<token>": {
      "name": "alice",
      "principals": ["bitresearch"],
      "max_ttl": 3600,
      "port": 9001,
      "active": true
    }
  }
}
```

---

## Dynamic Nginx Routing

`regen_nginx_routes.sh` reads:

```text
/etc/tunnel/user_ports.json
```

and generates per-user Nginx configuration under:

```text
/etc/nginx/conf.d/
```

For example:

```text
/etc/nginx/conf.d/alice.conf
```

The generated route maps the user hostname to the allocated localhost port:

```nginx
server {
    server_name alice.bitone.in;

    location / {
        proxy_pass http://127.0.0.1:9001;
    }
}
```

The username is sanitized before it is used in the generated filename and hostname.

### Safe regeneration

The route generator:

1. Reads the current user-to-port mapping.
2. Generates the required user configuration files.
3. Removes stale generated configurations.
4. Updates the subdomain list.
5. Runs `nginx -t`.
6. Reloads Nginx only when the configuration test succeeds.

A failed Nginx configuration test returns a non-zero status and does not reload Nginx.

---

## Reverse SSH Tunnel

After registration, the client uses the assigned port to establish the reverse tunnel.

The general form is:

```bash
ssh -N -R 127.0.0.1:<allocated_port>:localhost:8080 <principal>@bitone.in
```

For example, if Alice receives port `9001`:

```bash
ssh -N -R 127.0.0.1:9001:localhost:8080 bitresearch@bitone.in
```

The service on the user's machine remains on its local port, while the central server exposes it through the user's Nginx route.

---

## Revoking a User

Use:

```bash
sudo /usr/local/sbin/revoke_token.sh <token>
```

Revocation disables the token and removes the associated user routing/port mapping according to the installed administration scripts.

---

## Removing a User Port

A user-to-port mapping can be removed directly with:

```bash
sudo /usr/local/sbin/remove_user_port.sh <username>
```

The route configuration should then be regenerated so that the user's generated Nginx route is removed.

---

## Useful Manual Commands

Regenerate routes manually:

```bash
sudo /usr/local/bin/regen_nginx_routes.sh
```

Check Nginx configuration:

```bash
sudo nginx -t
```

Check the signing service:

```bash
sudo systemctl status sign_service.service --no-pager
```

---

## Uninstallation

The normal Gradle command is:

```bash
./gradlew uninstall
```

The Gradle uninstallation flow invokes the current tool's uninstaller and then handles the configured dependencies.

---

## Project Structure

```text
subname_registrar/
├── build.gradle
├── deps.gradle
├── settings.gradle
├── set_env.sh
├── README.md
└── src/
    ├── install.sh
    └── main/
        ├── add_token.sh
        ├── alloc_user_port.sh
        ├── create_ca.sh
        ├── domain.in
        ├── install.sh
        ├── regen_nginx_routes.sh
        ├── remove_user_port.sh
        ├── revoke_token.sh
        ├── sign_service.py
        ├── sign_service.service
        └── uninstall.sh
```

---

## Current Operational Workflow

The intended administrator workflow is:

```text
1. Install
   ./gradlew install

2. Register a user
   sudo /usr/local/sbin/add_token.sh "alice" "bitresearch" 3600

3. Use the returned token on the client

4. Establish the reverse SSH tunnel using the allocated port

5. Access the service through
   https://alice.bitone.in

6. Revoke when access is no longer required
   sudo /usr/local/sbin/revoke_token.sh <token>
```

### Short form

For normal user registration, this is the command to use:

```bash
sudo /usr/local/sbin/add_token.sh "alice" "bitresearch" 3600
```

`add_token.sh` calls `alloc_user_port.sh` and `regen_nginx_routes.sh` as part of the registration workflow.
