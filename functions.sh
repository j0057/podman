:() { echo -e "\e[1;36m[+] $@\e[0m" >&2; "$@"; }

_latest() {
    case $CONTAINER_IMAGE in
        localhost/*)
            podman image ls 2>/dev/null \
                | awk '$1==N && $2>T {T=$2} END {print N ":" T}' N=$CONTAINER_IMAGE
            ;;
        docker.io/*|j0057.azurecr.io/*)
            skopeo list-tags docker://$CONTAINER_IMAGE \
                | jq -r '.Tags[]' \
                | awk '$1>T {T=$1} END {print N ":" T}' N=$CONTAINER_IMAGE
            ;;
    esac
}

CONTAINER_SUBUIDNAME="${CONTAINER_SUBUIDNAME:-$CONTAINER_NAME}"

TAG=$(date '+%y%m%d%H%M')

UIDMAP="$(awk '$1==CN { print "0:" $2 ":" $3}' FS=':' CN="$CONTAINER_SUBUIDNAME" conf/subuid)"
GIDMAP="$UIDMAP"
SUBUID="$(awk '$1==CN { print $2 }' FS=':' CN="$CONTAINER_NAME" conf/subuid)"
SUBGID="$SUBUID"

PODMAN_ARGS="${PODMAN_ARGS:-}"

cmd="${1:-}"
case "$cmd" in
    run)
        : podman $PODMAN_ARGS container run \
            --name $CONTAINER_NAME \
            --rm --interactive --tty \
            --uidmap $UIDMAP \
            --gidmap $GIDMAP \
            ${CONTAINER_ARGS[@]} \
            $(_latest)
        ;;

    create)
        : podman $PODMAN_ARGS container create \
            --name $CONTAINER_NAME \
            --conmon-pidfile /run/podman/$CONTAINER_NAME.pid --log-driver journald --log-opt 'tag={{.ImageName}}' \
            --uidmap $UIDMAP \
            --gidmap $GIDMAP \
            ${CONTAINER_ARGS[@]} \
            $(_latest)
        ;;

    destroy)
        : podman $PODMAN_ARGS container rm $CONTAINER_NAME
        ;;

    recreate)
        $0 destroy || true
        $0 create
        ;;

    start|stop|enable|disable|is-enabled|is-active|status)
        : systemctl $1 podman@${CONTAINER_NAME}.service
        ;;

    *)
        if [ "$(type -t "cmd_$cmd")" = "function" ]; then
            cmd_$1
        else
            echo "error: unknown command '$cmd'" >&2
            exit 1
        fi
esac
