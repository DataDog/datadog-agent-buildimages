#!/bin/sh
# Fails if the image still trusts any chain of the compromised eMudhra intermediates.
# See https://emudhra.we-have-a-problem.com/
HOSTS="dv-g3b dv-g3c ov-g3b ov-g3c ev-g3b ev-g3c dv-g3b-noct
dv-g3b-aaa dv-g3c-aaa ov-g3b-aaa ov-g3c-aaa ev-g3b-aaa ev-g3c-aaa dv-g3b-aaa-noct"

curl --version | head -1
if ! curl -sS -o /dev/null --max-time 20 https://github.com/; then
    echo "INCONCLUSIVE: control host github.com is unreachable"
    exit 2
fi

trusted=0
for h in $HOSTS; do
    url="https://$h-emudhra.we-have-a-problem.com/"
    curl -s -o /dev/null --max-time 20 "$url" 2>/dev/null
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "TRUSTED   $url"
        trusted=1
    else
        echo "rejected  $url (curl exit $rc)"
    fi
done
exit $trusted
