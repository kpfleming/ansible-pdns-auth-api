#!/usr/bin/env -S bash -e

root=$(dirname ${BASH_SOURCE[0]})

image=quay.io/kpfleming/apaz-test-images:pdns4.3-python3

c=$(buildah from debian:buster)

buildah run ${c} -- apt update
buildah run ${c} -- apt install --yes gnupg python3 python3-venv git sqlite3

buildah add ${c} ${root}/apt-repo-pdns-auth-43.list /etc/apt/sources.list.d
buildah add ${c} ${root}/apt-pref-pdns /etc/apt/preferences.d
curl https://repo.powerdns.com/FD380FBB-pub.asc | buildah run ${c} -- apt-key add
buildah run ${c} -- apt update
buildah run ${c} -- apt install --yes pdns-server pdns-backend-sqlite3
buildah run ${c} -- apt purge --yes pdns-backend-bind
buildah run ${c} -- sqlite3 /run/pdns.sqlite3 '.read /usr/share/doc/pdns-backend-sqlite3/schema.sqlite3.sql'

buildah run ${c} -- python3 -m venv /ansible
buildah run ${c} -- /ansible/bin/pip install wheel
buildah run ${c} -- /ansible/bin/pip install ansible
buildah run ${c} -- /ansible/bin/pip install bravado

buildah run ${c} -- rm -rf /var/lib/apt/lists/*
buildah run ${c} -- rm -rf /root/.cache

if buildah images --quiet ${image}; then
    buildah rmi ${image}
fi
buildah commit --squash --rm ${c} ${image}
