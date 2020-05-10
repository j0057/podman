# gs45.net buildah/podman infrastructure

## certbot

First, use `init` subcommand. Needs a volume `/srv/cert.[name]` to store the
resulting certificates. Create it beforehand and use `setfacl` to grant other
containers access to the directory (`u::`) and any things created within
(`d:u:...`):

    mkdir /srv/cert.[name]
    setfacl -m u::rwx,u:10000:rwx,g::-,o::-,m::rwx,d:u::rw,d:u:10000:r,d:g::r,d:m::rw,d:o::- /srv/cert.[name]

Then use the `create` subcommand to create the container that will do the
periodic renewals.

Then `podman@letsencrypt-[name].service` should be ran from a systemd timer.
