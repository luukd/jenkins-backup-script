#!/bin/bash -xe

##################################################################################
function usage(){
  echo "usage: $(basename $0) /path/to/jenkins_home archive.tar.gz"
}
##################################################################################

readonly JENKINS_HOME=$1
readonly DEST_SHARE=$2
readonly DEST_FILE=$3
readonly SMB_USER=$4
readonly SMB_PASS=$5
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
readonly TMP_DIR="$JENKINS_HOME/jenkins-backup-tmp"
readonly ARC_NAME="jenkins-backup"
readonly ARC_DIR="$TMP_DIR/$ARC_NAME"
readonly TMP_TAR_NAME="$TMP_DIR/archive.tar.gz"
readonly SMB_SHARE_NAME="/mnt/jenkins_backup_share"

if [ -z "$JENKINS_HOME" -o -z "$DEST_FILE" ] ; then
  usage >&2
  exit 1
fi

rm -rf "$ARC_DIR" "$TMP_TAR_NAME"
mkdir -p "$TMP_DIR"
mkdir -p "$ARC_DIR/"{plugins,jobs,users,secrets,userContent,nodes}

cp "$JENKINS_HOME/"*.xml "$ARC_DIR"

cp "$JENKINS_HOME/plugins/"*.[hj]pi "$ARC_DIR/plugins"
hpi_pinned_count=$(find $JENKINS_HOME/plugins/ -name *.hpi.pinned | wc -l)
jpi_pinned_count=$(find $JENKINS_HOME/plugins/ -name *.jpi.pinned | wc -l)
if [ $hpi_pinned_count -ne 0 -o $jpi_pinned_count -ne 0 ]; then
  cp "$JENKINS_HOME/plugins/"*.[hj]pi.pinned "$ARC_DIR/plugins"
fi

if [ -d "$JENKINS_HOME/users/" ] ; then
  cp -R "$JENKINS_HOME/users/"* "$ARC_DIR/users"
fi

if [ -d "$JENKINS_HOME/secrets/" ] ; then
  cp -R "$JENKINS_HOME/secrets/"* "$ARC_DIR/secrets"
fi

if [ -d "$JENKINS_HOME/userContent/" ] ; then
  cp -R "$JENKINS_HOME/userContent/"* "$ARC_DIR/userContent"
fi

if [ -d "$JENKINS_HOME/nodes/" ] ; then
  cd "$JENKINS_HOME/nodes/"
  ls -1 | while read node_name ; do
    mkdir -p "$ARC_DIR/nodes/$node_name/"
	cp -R "$JENKINS_HOME/nodes/$node_name/"* "$ARC_DIR/nodes/$node_name/"
    #find "$JENKINS_HOME/nodes/$node_name/" -maxdepth 1 -name "*.xml" | xargs -I {} cp {} "$ARC_DIR/nodes/$node_name/"
	
  done
  cd -
fi

if [ -d "$JENKINS_HOME/jobs/" ] ; then
  cd "$JENKINS_HOME/jobs/"
  ls -1 | while read job_name ; do
    mkdir -p "$ARC_DIR/jobs/$job_name/"
	cp -R "$JENKINS_HOME/jobs/$job_name/"* "$ARC_DIR/jobs/$job_name/"
    #find "$JENKINS_HOME/jobs/$job_name/" -maxdepth 1 -name "*.xml" | xargs -I {} cp {} "$ARC_DIR/jobs/$job_name/"
	
  done
  cd -
fi

cd "$TMP_DIR"
tar -czvf "$TMP_TAR_NAME" "$ARC_NAME/"*
cd -

sudo mount -t cifs "$DEST_SHARE" "$SMB_SHARE_NAME" -o user="$SMB_USER",password="$SMB_PASS"

sudo mv -f "$TMP_TAR_NAME" "$SMB_SHARE_NAME/$DEST_FILE"

sudo unmount "$SMB_SHARE_NAME"

rm -rf "$ARC_DIR"
rm -rf "$TMP_DIR"

exit 0
