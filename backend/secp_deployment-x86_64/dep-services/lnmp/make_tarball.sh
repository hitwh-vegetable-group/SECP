# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh
#set -o errexit

tar -zcvf ./lnmp1.5-full.tgz ./lnmp1.5-full

echo "Calculating SHA256 Checksums..."
sha256sum ./lnmp1.5-full.tgz > lnmp1.5-full.sha256

echo "All Done."

find /usr/local/mysql -type f -exec touch {} \; && service mysql start