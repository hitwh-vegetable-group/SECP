# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh

echo "Dealing overlay2 problems about MySQL in Docker"
find /usr/local/mysql -type f -exec touch {} \;

echo "Restarting LNMP Environment..."
lnmp restart