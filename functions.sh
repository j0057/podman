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

TAG=$(date '+%y%m%d%H%M')

case $1 in
    run)
        : podman container run \
            --name $CONTAINER_NAME \
            --rm --interactive --tty \
            ${CONTAINER_ARGS[@]} \
            $(_latest)
        ;;

    create)
        : podman container create \
            --name $CONTAINER_NAME \
            --conmon-pidfile /run/podman/$CONTAINER_NAME.pid --log-driver journald --log-opt 'tag={{.ImageName}}' \
            ${CONTAINER_ARGS[@]} \
            $(_latest)
        ;;

    destroy)
        : podman container rm $CONTAINER_NAME
        ;;

    recreate)
        $0 destroy || true
        $0 create
        ;;

    start|stop|enable|disable|is-enabled|is-active|status)
        : systemctl $1 podman@${CONTAINER_NAME}.service
        ;;

    *)
        if [ "$(type -t cmd_$1)" = "function" ]; then
            cmd_$1
        else
            echo "error: unknown command $1" >&2
            exit 1
        fi
esac