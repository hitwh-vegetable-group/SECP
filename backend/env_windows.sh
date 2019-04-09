# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

set -o errexit

# Delete redundant spaces
sed 's/ *\= /\=/g' env_windows.sh | sed 's/^exit$//g' | sed '/^bash/d' | sed '/^sed/d' > env_windows.sh_sed
bash env_windows.sh_sed
exit

# Export
export SECP                         = /f/\[Github\]Projects/SECP

export SECP_BACKEND                 = $SECP/backend
export SECP_BACKEND_DEP             = $SECP_BACKEND/secp_deployment-x86_64
export SECP_BACKEND_DEP_COMPONENTS  = $SECP_BACKEND_DEP/dep-components
export SECP_BACKEND_DEP_SERVICES    = $SECP_BACKEND_DEP/dep-services
export SECP_BACKEND_DEP_SHELLS      = $SECP_BACKEND_DEP/dep-shells

export SECP_COMPONENTS_DOCKER       = $SECP_BACKEND_DEP_COMPONENTS/docker
export SECP_COMPONENTS_DOCKER_DEB   = $SECP_COMPONENTS_DOCKER/debs
export SECP_COMPONENTS_DOCKER_IMG   = $SECP_COMPONENTS_DOCKER/images

export SECP_LNMP                    = $SECP_BACKEND_DEP_SERVICES/lnmp
export SECP_UBUNTU                  = $SECP_COMPONENTS_DOCKER_IMG/ubuntu-with_updates_and_sources

# Clean
rm -f env_windows.sh_sed

# Check status
env | grep SECP