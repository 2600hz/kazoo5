# Installing Open Source KAZOO (v5) on Rocky Linux 9

WIP: installing open source KAZOO with its components (CouchDB, RabbitMQ,
FreeSWITCH, Kamailio). Packages are used where possible; otherwise we build
from source.

This assumes you have installed older KAZOO versions before and are comfortable
with Linux administration, so it mostly highlights what differs from the
classic install (OTP via kerl, the dev release build, `/etc/kazoo` configs).

## 1. Environment

KAZOO is picky about host identity, time, and firewalling. Get all of this
right up front or things fail oddly later.

- **Disk space**: ~120 GB covers code, the database, and configs.
- **Hostname**: pick an FQDN, e.g. `aio.kazoo.dev`.

      sudo hostnamectl set-hostname aio.kazoo.dev

  KAZOO's node name becomes the distributed Erlang longname, so the FQDN must
  resolve both ways. Add it to `/etc/hosts` (keep the hostname as the first
  entry, and add your LAN IP for multi-node setups):

      127.0.0.1 aio.kazoo.dev localhost
      <lan-ip> aio.kazoo.dev aio

  Sanity check before building: `erl -name test` should come up as
  `test@<fqdn>`. If epmd reports `noport` or the shell crashes, fix DNS /
  `/etc/hosts` first.

- **Time**: Kazoo requires UTC.

      sudo timedatectl set-timezone UTC
      sudo systemctl enable --now chronyd

- **Firewall / SELinux**: for dev/AiO boxes it's common to disable both (dev
  boxes are usually behind a datacenter firewall):

      sudo systemctl disable --now firewalld.service
      sudo systemctl mask firewalld.service
      sudo sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config
      # reboot to apply

## 2. System packages

Base toolchain and download helpers:

    sudo dnf install -y epel-release
    sudo dnf config-manager --enable crb      # Rocky 9 CodeReady Builder
    sudo dnf install -y git
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y ncurses-devel

Useful admin tools:

    sudo dnf install -y dnf-utils psmisc nano bash-completion \
        wget bind-utils chrony htop net-tools screen tmux tar

Kazoo build deps (`gcc-toolset*` is EL9's equivalent of the old
`devtoolset`):

    sudo dnf install -y autoconf automake bzip2-devel elfutils expat-devel \
        gcc-c++ gcc git glibc-devel libcurl libcurl-devel libstdc++-devel \
        libxslt make ncurses-devel openssl openssl-devel patch patchutils \
        readline readline-devel unzip wget zip zlib-devel \
        the_silver_searcher jq cpio gcc-toolset* python pip

Runtime deps (fax/media etc. — the classic docs list Debian names like
`libsox-fmt-all`; use the RPM names here):

    # htmldoc isn't in the standard Rocky 9 repos; get it from EPEL endpoints
    wget https://packages.endpointdev.com/rhel/9/main/x86_64/htmldoc-1.9.18-1.ep9.x86_64.rpm
    sudo dnf install htmldoc-1.9.18-1.ep9.x86_64.rpm
    sudo dnf install -y sox ghostscript \
        ImageMagick libreoffice-writer libtiff-tools \
        wxGTK-devel wxGTK-webview zip unzip

### Add 2600Hz Package Repository

(Needed later for the `kazoo-freeswitch` / `kazoo-kamailio` wrapper packages in
§9/§10.)

    cat <<'EOF' > /etc/yum.repos.d/2600Hz.repo
    [2600hz-stable]
    name=2600Hz Stable Repo
    baseurl=https://packages.2600hz.com/rockylinux/$releasever/stable
    enabled=1
    gpgcheck=0
    sslverify=false
    EOF

## 3. Fetch KAZOO source

    sudo mkdir -p /opt/kazoo
    sudo git clone https://github.com/2600hz/kazoo5.git /opt/kazoo

(Or clone to `~/kazoo5`: `export FETCH_AS=git@github.com:` to fetch deps over
SSH.)

## 4. Erlang

The authoritative OTP version for any given tree is `make/erlang_version`
(our checkout pins **26.2**; note `doc/installation.md` still says Erlang 23
for Kazoo 5 — it is stale). Two ways to install it:

### Option A: kerl

    curl -O https://raw.githubusercontent.com/kerl/kerl/master/kerl
    chmod +x kerl
    sudo mv kerl /usr/bin
    kerl update releases
    kerl build 26.2 26.2
    kerl install 26.2 /usr/local/otp-26.2
    . /usr/local/otp-26.2/activate

Add the `activate` line to `~/.bashrc` (or equivalent) so this OTP version is
available in every shell by default.

OpenSSL note: on EL9 the system OpenSSL 3 breaks older OTP builds. If your
Kazoo tree needs OTP 23, build OpenSSL 1.1.1 into `/usr/local/lib/openssl-1.1.1`
and pass `KERL_CONFIGURE_OPTIONS="--with-ssl=/usr/local/lib/openssl-1.1.1"`.

### Option B: asdf-vm

    wget "https://github.com/asdf-vm/asdf/releases/download/v0.16.1/asdf-v0.16.1-linux-amd64.tar.gz"
    tar -xf asdf-v0.16.1-linux-amd64.tar.gz && sudo mv asdf /usr/bin/ && sudo chmod +x /usr/bin/asdf
    # add $HOME/.asdf/shims to PATH in ~/.bash_profile
    asdf plugin add erlang
    asdf install erlang 26.2             # or whatever make/erlang_version says
    asdf set erlang 26.2                 # in the repo dir; check with cat .tool-versions

## 5. Build KAZOO (dev release)

    export FETCH_AS=https://github.com/
    cd /opt/kazoo
    make
    make build-dev-release

The dev release symlinks the beam files and reloads them on recompile, which is
handy for iterating but not what you'd deploy. For a production box use `make
build-release` instead, or `make build-tar-release` to create a single build
for distribution.

Useful extra make targets: `make kazoo-code-workspace` (VS Code workspace) and
`make erlang-ls` (Erlang LS config). If the dev node runs unprivileged, the
`/opt/kazoo/var/lib/ra` dir may need opening up (`chmod -R 777
/opt/kazoo/var/lib/ra`) — this bites if you build as root and then run as a
regular user.

### SUP tooling

    sudo ln -s /opt/kazoo/core/sup/priv/sup /usr/bin/sup
    sudo make sup_completion           # from repo root; creates sup.bash
    sudo cp sup.bash /etc/bash_completion.d/

If the path to KAZOO isn't right in the symlink, set `KAZOO_ROOT=/opt/kazoo`
(alias) instead.

## 6. KAZOO configs

Clone the configs into `/etc/kazoo` (same layout as KAZOO 4):

    sudo git clone https://github.com/2600hz/kazoo-configs-core/ /etc/kazoo

Then write `/etc/kazoo/core/config.ini`. Single-node AIO example:

```
[amqp]
uri = "amqp://guest:guest@127.0.0.1:5672"

[data]
config = couchdb3

[couchdb3]
ip = "127.0.0.1"
port = 5984
username = admin
password = admin

[kazoo_apps]
cookie = change_me

[ecallmgr]
cookie = change_me

[log]
syslog = debug
console = info
file = error
```

Multi-node setups use one `[zone]` + `[kazoo_apps]` block per node:

```
[zone]
name = "z1"
uri = "amqp://guest:guest@r1.kazoo.aio:5672?channel_max=0"

[couchdb3]
ip = "db1.kazoo.aio"
port = 5984
username = kazoo
password = kazoo

[kazoo_apps]
cookie = change_me
zone = "z1"
host = "k1.kazoo.aio"
```

On the 5984/5986 question: modern single-node CouchDB talks to Kazoo on 5984.
5986 was the old BigCouch cluster-mgmt port (HAProxy fronted 15984/15986); you
don't need it with CouchDB 2/3 unless you're running BigCouch-compat setups.

FreeSWITCH needs an env file at `/etc/kazoo/freeswitch/env` when you get to
§9:

```
export KZ_AMQP_HOST=127.0.0.1
export KZ_AMQP_PORT=5672
export KZ_AMQP_USER=guest
export KZ_AMQP_PASS=guest
```

## 7. CouchDB and RabbitMQ

### RabbitMQ: vanilla package

    sudo dnf install -y rabbitmq-server
    sudo rabbitmq-plugins enable rabbitmq_consistent_hash_exchange

### CouchDB admin setup

CouchDB won't run without an admin, and it must bind `0.0.0.0`. Create
`/opt/couchdb/etc/local.d/10-admins.ini` (or edit `local.ini`):

```
[admins]
admin = admin

[chttpd]
bind_address = 0.0.0.0

[couchdb]
default_security = everyone

[cluster]
q=1
n=1
r=1
w=1
```

    sudo chown couchdb:couchdb /opt/couchdb/etc/local.d/10-admins.ini
    sudo chmod u=rwx,g=rx,o=rx /opt/couchdb/etc/local.d/10-admins.ini
    sudo systemctl enable --now couchdb
    sudo systemctl restart couchdb

Then go to `http://<ip>:5984/_utils/` → **Setup** → configure it as a single
node using the admin credentials above. On multi-node setups, spin up CouchDB
on each DB node first (each with its own `10-admins.ini`), then use the UI to
join them; nodes must resolve each other by hostname (`/etc/hosts` or DNS), and
match the zone names in `config.ini`.

Start RabbitMQ:

    sudo systemctl enable --now rabbitmq-server

(2600Hz also publishes `kazoo-*` wrapper packages for RabbitMQ/FreeSWITCH/
Kamailio in its yum repo that ship tuned systemd units and configs; if you use
those, mask the vanilla units. See §9/§10.)

## 8. Start KAZOO and verify

    cd /opt/kazoo/
    make release

In the Erlang shell, confirm the node sees the rest of the cluster:

    kz_nodes:status().

With CouchDB, RabbitMQ, and KAZOO all running, `epmd -names` should list all
the node names registered; a missing name means a service didn't finish
starting.

Then bring up the media layer and its extensions:

    kapps_controller:start_app(ecallmgr_extension).
    kapps_controller:start_app(ecallmgr).

Post-install housekeeping:

    # System media prompts, then import (or install a kazoo-sounds package)
    git clone git@github.com:2600hz/kazoo-sounds.git ~/kazoo-sounds
    sudo sup kazoo_media_maintenance import_prompts ~/kazoo-sounds/kazoo-core/en/us/

    # It can be a good idea to refresh the installed DBs afterwards
    sudo sup kapps_maintenance refresh

    # Master account + admin user for Monster-UI (replace the braced fields)
    sudo sup crossbar_maintenance create_account \
        {ACCOUNT_NAME} {ACCOUNT_REALM} {ADMIN_USER} {ADMIN_PASS}

## 9. FreeSWITCH

    sudo dnf install -y freeswitch

(kazoo-freeswitch from the 2600Hz repo is a drop-in wrapper with tuned config;
if you use it, `systemctl disable --now freeswitch && systemctl mask
freeswitch` and use `kazoo-freeswitch` for everything.)

`mod_kazoo` is what connects FreeSWITCH to the AMQP broker. Point it at
RabbitMQ via `/etc/kazoo/freeswitch/env` (see §6), then:

    sudo systemctl enable --now freeswitch
    sudo kazoo-freeswitch status      # if using the wrapper
    sudo netstat -tunlp | grep freeswitch

Notes:
- `mod_sofia` isn't loaded on boot; Kazoo controls routing, and FreeSWITCH is
  auto-discovered by ecallmgr once both are up. Check the link with
  `fs_cli -x 'erlang status'`.
- If ecallmgr doesn't auto-add it: `sup ecallmgr_maintenance add_fs_node freeswitch@${_HOSTNAME}`
- Useful log-parsing tool:

      sudo curl -o /usr/bin/sipify.sh \
          https://raw.githubusercontent.com/2600hz/community-scripts/master/FreeSWITCH/sipify.sh
      sudo chmod 755 /usr/bin/sipify.sh

## 10. Kamailio

The 2600Hz repo provides the Kazoo-patched kamailio packages:

    sudo dnf install -y kamailio-kazoo kamailio-outbound kamailio-uuid kamailio-tcpops kamailio-presence

The official Kamailio configs live at `/etc/kazoo/kamailio/` (clone
`kazoo-configs-kamailio` there if installing from source). Before starting, fix
hostname/IP in the config:

    sudo cp /etc/kazoo/kamailio/local.cfg /etc/kazoo/kamailio/local.cfg.orig
    sudo sed -i "s/kamailio\.2600hz\.com/$HOSTNAME/g" /etc/kazoo/kamailio/local.cfg
    sudo sed -i "s/127\.0\.0\.1/$IP_ADDR/g" /etc/kazoo/kamailio/local.cfg

Initialize the Kamailio/KAZOO database, then start:

    kazoo-kamailio prepare
    sudo systemctl enable --now kamailio

If you use the `kazoo-kamailio` wrapper package from the 2600Hz repo instead,
mask the vanilla unit first:

    sudo systemctl disable --now kamailio
    sudo systemctl mask kamailio
    sudo systemctl enable --now kazoo-kamailio

    sudo kazoo-kamailio status        # also: sudo netstat -tunlp | grep kamailio

Add Kamailio to ecallmgr's SBC ACLs once Kazoo is up:

    sup ecallmgr_maintenance allow_sbc kam1 ${IP_ADDR}

`kazoo-kamailio status` will show `No Destination Sets` until FreeSWITCH is
auto-discovered — that's expected.

## 11. Monster-UI (optional)

Monster-UI is open source (github.com/2600hz/monster-ui); package or build it,
then:

    # point Monster at Crossbar
    sed -i "/define({/a \ \ \ \ api: { 'default': 'http://${IP_ADDR}:8000/v2/' }," /var/www/html/monster-ui/js/config.js

    # register the UI apps in Kazoo
    sudo sup crossbar_maintenance init_apps \
        /var/www/html/monster-ui/apps \
        http://${IP_ADDR}:8000/v2

Serve `/var/www/html/monster-ui` with httpd/nginx. Log in with the credentials
from the `create_account` step in §8. Verify Crossbar responds:
`curl http://${IP_ADDR}:8000/v2` (a 401 `invalid_credentials` is success).

## Open items / TODO

- Verify the OTP version for the exact Kazoo release being installed.
- Confirm whether `kazoo-kamailio prepare` is still required (current wrapper-
  based installs may not need it).
- HAProxy config for production CouchDB clusters (15984/15986 listeners).
