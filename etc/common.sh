# define the git clone function
git-clone-concourse-docker () {
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
  if [[ -e $WORK_DIR/concourse-docker/keys/web/concourse-key && -e $WORK_DIRi/concourse-docker/keys/web/concourse-crt ]]; then
     echo "Self-signed key-pair is generated..."
     return 0
  fi
  openssl req -x509 -newkey rsa:4096 -keyout "$WORK_DIR/concourse-docker/keys/web/concourse-key" -out "$WORK_DIR/concourse-docker/keys/web/concourse-crt" -days 3650 -nodes -subj "/CN=$CONCOURSE_ACESS_URI"
  cd $CURRENT_DIR
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
  PROC_DIR=$WORK_DIR/concourse-docker
  cd $PROC_DIR
  docker-compose up -d
  docker container ps
  ss -tupnl
}
