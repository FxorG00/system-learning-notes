#!/usr/bin/env bash
# Local-socket-only teaching instance. No sudo, system service, or global config.
set -euo pipefail
umask 077

root=${MYSQL_LAB_ROOT:-"$HOME/.local/share/gpt-infra/mysql-lab"}
runtime="$root/runtime/usr"
socket="$root/mysql.sock"
version=8.0.42-0ubuntu0.20.04.1
export LD_LIBRARY_PATH="$runtime/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

prepare() {
    mkdir -p "$root" "$root/imports"
    if [[ -x "$runtime/sbin/mysqld" && -x "$runtime/bin/mysql" ]]; then
        return
    fi
    local downloads package
    downloads=$(mktemp -d "$root/downloads.XXXXXX")
    (
        cd "$downloads"
        apt-get download "mysql-server-core-8.0=$version" \
            "mysql-client-core-8.0=$version" libaio1 libmecab2 \
            libevent-core-2.1-7 libevent-pthreads-2.1-7 libicu66
        for package in ./*.deb; do
            dpkg-deb -x "$package" "$root/runtime"
        done
    )
    "$runtime/sbin/mysqld" --version
}

client() {
    "$runtime/bin/mysql" --no-defaults --protocol=SOCKET \
        --socket="$socket" -uroot "$@"
}

case "${1:-help}" in
    prepare)
        prepare
        ;;
    start)
        prepare
        if client -N -e 'SELECT 1' >/dev/null 2>&1; then
            printf 'MYSQL LAB ALREADY RUNNING\n'
            exit 0
        fi
        if [[ ! -d "$root/data/mysql" ]]; then
            "$runtime/sbin/mysqld" --no-defaults --basedir="$runtime" \
                --datadir="$root/data" --lc-messages-dir="$runtime/share/mysql" \
                --initialize-insecure --log-error="$root/initialize.log"
        fi
        "$runtime/sbin/mysqld" --no-defaults --basedir="$runtime" \
            --datadir="$root/data" --lc-messages-dir="$runtime/share/mysql" \
            --socket="$socket" --pid-file="$root/mysql.pid" \
            --log-error="$root/mysql.log" --secure-file-priv="$root/imports" \
            --skip-networking --mysqlx=OFF --innodb-buffer-pool-size=64M \
            --daemonize
        client --table -e 'SELECT VERSION(), @@innodb_page_size;'
        ;;
    sql)
        shift
        client --table "$@"
        ;;
    stop)
        if ! client -N -e 'SELECT 1' >/dev/null 2>&1; then
            printf 'MYSQL LAB NOT RUNNING\n'
            exit 0
        fi
        client -e 'SHUTDOWN;'
        for ((attempt=0; attempt<100; ++attempt)); do
            if [[ ! -e "$root/mysql.pid" ]]; then
                printf 'MYSQL LAB STOPPED\n'
                exit 0
            fi
            sleep 0.1
        done
        printf 'Shutdown is still in progress; inspect %s/mysql.log\n' "$root" >&2
        exit 1
        ;;
    *)
        printf 'Usage: bash mysql_lab.sh {prepare|start|sql|stop}\n'
        printf 'Root: %s\n' "$root"
        ;;
esac
