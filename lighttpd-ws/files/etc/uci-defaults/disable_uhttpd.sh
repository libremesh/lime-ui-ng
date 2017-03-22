#!/bin/sh
echo "Disabling uhttpd, let's use lighttpd instead"
[ -f /etc/init.d/uhttpd ] && /etc/init.d/uhttpd disable
