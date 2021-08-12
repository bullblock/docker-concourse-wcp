# prepare pipeline repo
pipeline-repo-prepare () {
  cd $CURRENT_DIR
  if [ ! -d $WORK_DIR/vmware-tanzu-wcp-operation-pipeline ] then;
     cd $WORK_DIR
     git clone $PIPELINE_REPOSITORY
     sleep 30
     sed -i "s/#WCP_API_SERVER_URI#/$WCP_API_SERVER_URI/g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
     sed -i "s/#NAMESPACE#/$NAMESPACE/g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
     sed -i "s/#NS_USERNAME#/$NS_USERNAME/g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
     sed -i "s/#NS_USERNAME_PASSWORD#/$NS_USERNAME_PASSWORD/g" $WORK_DIR/vmware-tanzu-wcp-operation-pipeline/vars.yaml
  fi
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
  fly -t $PIPELINE_TARGET_NAME login -c https://$CONCOURSE_ACESS_URI -u $CONCOURSE_OWNER -p $CONCOURSE_OWNER_PASSWORD
  fly -t $PIPELINE_TARGET_NAME sp -c pipeline.yml -l vars.yaml -n 
}
