LS_COLORS=$LS_COLORS:'di=0;35:' ; export LS_COLORS

function list () {
cd "$@" && ls -l
}

function uu () {
sudo apt update && sudo apt upgrade
}

function runrabbit() {
sudo run-parts /etc/update-motd.d/
}

function pssh () {
parallel-ssh -h ~/"multi-ssh.txt" -i "$1"
}

###
# Kubernetes
###
alias kb='kubectl'
 
function kbn () {
  kubectl get ns ; echo
  if [[ "$#" -eq 1 ]]; then
    kubectl config set-context --current --namespace $1 ; echo
  fi
  echo "Current namespace [ $(kubectl config view --minify | grep namespace | cut -d " " -f6) ]"
}