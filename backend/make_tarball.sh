# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

#!/bin/sh
#set -o errexit

tar -zcvf ./secp_deployment-x86_64.tgz ./secp_deployment-x86_64

echo "Calculating SHA256 Checksums..."
sha256sum ./secp_deployment-x86_64.tgz > secp_deployment-x86_64.sha256

echo "All Done."