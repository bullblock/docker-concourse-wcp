# define the git clone function
git-clone-concourse-docker () {
  cd $CURRENT_DIR
  if [ -d $WORK_DIR/concourse-docker ]; then
     cd $WORK_DIR/concourse-docker && git pull
     sleep 30
  else
     cd $WORK_DIR && git clone $CONCOURSE_DOCKER_GIT
     sleep 30
  fi
}

# define concourse key-set generation function
concourse-docker-key-generation () {
  cd $CURRENT_DIR
  if [ ! -e $WORK_DIR/concourse-docker/keys/generate ]; then
     echo "please git clone the concourse-docker repository first"
     exit 1
  else
     cd $WORK_DIR/concourse-docker/keys/ && ./generate
     echo "concourse-docker key-set generation is done..."
  fi
}

# define the self-signed cert generarion function
cert-key-generation () {
  cd $CURRENT_DIR
  if [[ -e $WORK_DIR/concourse-docker/keys/web/concourse-key && -e $WORK_DIRi/concourse-docker/keys/web/concourse-crt ]]; then
     echo "Self-signed key-pair is generated..."
     return 0
  fi
  openssl req -x509 -newkey rsa:4096 -keyout "$WORK_DIR/concourse-docker/keys/web/concourse-key" -out "$WORK_DIR/concourse-docker/keys/web/concourse-crt" -days 3650 -nodes -subj "/CN=$CONCOURSE_ACESS_URI"
  if [ -e etc/web_role_permission ]; then
     cp etc/web_role_permission $WORK_DIR/concourse-docker/keys/web/web_role_permission
     sed -i "s/#CONCOURSE_OWNER#/$CONCOURSE_OWNER/g" $WORK_DIR/concourse-docker/keys/web/web_role_permission
     sed -i "s/#CONCOURSE_MEMBER#/$CONCOURSE_MEMBER/g" $WORK_DIR/concourse-docker/keys/web/web_role_permission
     sed -i "s/#CONCOURSE_OPERATOR#/$CONCOURSE_OPERATOR/g" $WORK_DIR/concourse-docker/keys/web/web_role_permission
     sed -i "s/#CONCOURSE_VIEWER#/$CONCOURSE_VIEWER/g" $WORK_DIR/concourse-docker/keys/web/web_role_permission
  fi
  sudo chown root:root $WORK_DIR/concourse-docker/keys/web/concourse-key
  sudo chown root:root $WORK_DIR/concourse-docker/keys/web/concourse-crt
  sudo chown root:root $WORK_DIR/concourse-docker/keys/web/web_role_permission
  echo "Self-signed key-pair is generated..."
}

# parser docker-compose file
docker-compose-process () {
  cd $CURRENT_DIR
  PROC_DIR=$WORK_DIR/concourse-docker
  USER_LIST=$(echo $CONCOURSE_OWNER:$CONCOURSE_OWNER_PASSWORD,$CONCOURSE_MEMBER:$CONCOURSE_MEMBER_PASSWORD,$CONCOURSE_OPERATOR:$CONCOURSE_OPERATOR_PASSWORD,$CONCOURSE_VIEWER:$CONCOURSE_VIEWER_PASSWORD)
  TEAM_LIST=$(echo $CONCOURSE_OWNER,$CONCOURSE_MEMBER,$CONCOURSE_OPERATOR,$CONCOURSE_VIEWER)
  sed -i "s/#NETWORK_PORTS#/$CONCOURSE_PORT/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#CLUSTER_NAME#/$CONCOURSE_CLUSTER_NAME/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#ACESS_URI#/$CONCOURSE_ACESS_URI/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#USER_LIST#/$USER_LIST/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#TEAM_LIST#/$TEAM_LIST/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#CONCOURSE_TLS_CERT#/\/concourse-keys\/concourse-crt/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#CONCOURSE_TLS_KEY#/\/concourse-keys\/concourse-key/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#CONCOURSE_MAIN_TEAM_CONFIG#/\/concourse-keys\/web_role_permission/g" $PROC_DIR/docker-compose.yml
  sed -i "s/#CONCOURSE_CONTAINER_DNS#/$CONCOURSE_CONTAINER_DNS/g" $PROC_DIR/docker-compose.yml
}


# run docker compose and trigger the concourse process...
run-concourse () {
  cd $CURRENT_DIR
  PROC_DIR=$WORK_DIR/concourse-docker
  cd $PROC_DIR
  docker-compose up -d
  docker container ps
  ss -tupnl
}

# prepare pipeline repo
pipeline-repo-prepare () {
  cd $CURRENT_DIR
  cd $WORK_DIR
  git clone $PIPELINE_REPOSITORY
  sleep 30
  sed -i "s|#WCP_API_SERVER_URI#|$WCP_API_SERVER_URI|g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
  sed -i "s/#NAMESPACE#/$NAMESPACE/g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
  sed -i "s/#NS_USERNAME#/$NS_USERNAME/g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
  sed -i "s/#NS_USERNAME_PASSWORD#/$NS_USERNAME_PASSWORD/g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
  sed -i "s|#CLUSTER_REPOSITORY#|$CLUSTER_REPOSITORY|g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
  echo "pipeline-prepare is ready..."
}

# prepare cluster repo
cluster-repo-prepare () {
  cd $WORK_DIR
  git clone $CLUSTER_REPOSITORY
  sleep 30
}

# pipeline build
pipeline-build () {
  cd $WORK_DIR/vmware-tanzu-wcp-operation-pipeline
  fly -t $PIPELINE_TARGET_NAME login -c https://$CONCOURSE_ACESS_URI -u $CONCOURSE_OWNER -p $CONCOURSE_OWNER_PASSWORD -k
  fly -t $PIPELINE_TARGET_NAME sp -p $PIPELINE_NAME -c pipeline.yml -l vars.yaml -n
}