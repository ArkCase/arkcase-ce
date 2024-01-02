#/!bin/bash

# add support for parameters

say() {
	echo -e "${@}"
}

err() {
	say "ERROR: ${@}" 1>&2
}

fail() {
	say "${@}" 1>&2
	exit 1
}

_app_user=${_zookeeper_user}
_app_group=${_zookeeper_group}
_app_log4j_dir=${_zookeeper_log4j_dir}
_app_log4j_lib_check=${_zookeeper_log4j_lib_check}
_app_systemctl_unit=${_zookeeper_systemctl_unit}

check_and_fix_log4j12() {
  if [[ -d ${_app_log4j_dir} ]] ; then
    say "checking ${_app_log4j_dir} for ${_app_log4j_lib_check}..."
    if [[ -f ${_app_log4j_dir}/${_app_log4j_lib_check} ]] ; then
      say "found ${_app_log4j_dir}/${_app_log4j_lib_check}... will attempt to remediate..."
      # stop the process if is running - need to add checks later on for improvement
      systemctl stop ${_app_systemctl_unit} || fail "failed to stop ${_app_systemctl_unit} service... update will not be made..."
      rm -f ${_app_log4j_dir}/${_app_log4j_lib_check} 

      \cp -vpf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar ${_app_log4j_dir} 
      \cp -vpf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar ${_app_log4j_dir}
      \cp -vpf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar ${_app_log4j_dir}
      chown -v ${_app_user}:${_app_group} ${_app_log4j_dir}/log4j-*
      chmod -v 644 ${_app_log4j_dir}/log4j-*

      # specific to Zookeeper
      _zookeeper_env_script=${_app_log4j_dir}/../bin/zkCli.sh
      if [[ -f ${_zookeeper_env_script} ]] ; then
        if [[ -z $(grep "^JVMFLAGS=" ${_zookeeper_env_script}) ]] ; then 
          sed -i '/ZOO_LOG_FILE=.*$/aJVMFLAGS="$JVMFLAGS -Dlog4j.configuration=/opt/arkcase/app/zookeeper/conf/log4j.properties"' ${_zookeeper_env_script} 
        else
          sed -i 's|^JVMFLAGS=.*$|JVMFLAGS="$JVMFLAGS -Dlog4j.configuration=/opt/arkcase/app/zookeeper/conf/log4j.properties"|g' ${_zookeeper_env_script}
        fi
      fi

      # start the service
      systemctl start ${_app_systemctl_unit} || fail "failed to start ${_app_systemctl_unit} service... check for errors..."
      sleep 3;
      systemctl status ${_app_systemctl_unit} | tail -8
    fi
  fi
}

#set -euo pipefail

say "Running some pre-flight checks for $0 ... "
[[ -z $(which zip) ]] && fail "The zip utility is needed for this script $0"
[[ -z $(which unzip) ]] && fail "The unzip utility is needed for this script $0"
[[ -z $(which jar) ]] && fail "The Java jar utility is needed for this script $0; install Java or add your Java bin directory to your path"
[[ -z $(which tar) ]] && fail "The tar utility is needed for this script $0"

_log4j2_release=2.22.0
_log4j2_archive_bundle=apache-log4j-${_log4j2_release}-bin
_log4j2_archive=${_log4j2_archive_bundle}.zip
_log4j2_archive_dir=/root
_log4j2_archive_bundle_path=${_log4j2_archive_dir}/${_log4j2_archive_bundle}
_log4j2_archive_path=/${_log4j2_archive_dir}/${_log4j2_archive}
_log4j2_download_url=https://dlcdn.apache.org/logging/log4j/${_log4j2_release}/${_log4j2_archive}

cd ${_log4j2_archive_dir} || fail "failed to change directory, ${_log4j2_archive_dir} for downloading ${_log4j2_archive}..."
if [[ ! -d ${_log4j2_archive_bundle} ]] ; then 
  mkdir ${_log4j2_archive_bundle_path}
  cd ${_log4j2_archive_bundle_path}
  curl -k -L "${_log4j2_download_url}" -o "${_log4j2_archive}" || fail "failed to download ${_log4j2_archive} from ${_log4j2_download_url} to ${_log4j2_archive_dir}..."
  unzip ${_log4j2_archive} || fail "failed to unzip ${_log4j2_archive} under ${_log4j2_archive_dir}..."
fi

if [[ -d /opt/arkcase/app/snowbound ]] ; then
  if [[ -f /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5/WEB-INF/lib/log4j-1.2.17.jar ]] ; then
    systemctl stop snowbound
    rm -f /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5/WEB-INF/lib/log4j-1.2.17.jar 
    cp -vpf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5/WEB-INF/lib/
    cp -vpf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5/WEB-INF/lib/
    cp -vpf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5/WEB-INF/lib/
    chown snowbound: /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5/WEB-INF/lib/log4j-*
    chmod 640 /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5/WEB-INF/lib/log4j-*
    cd /opt/arkcase/app/snowbound/webapps/
    zip -d VirtualViewerJavaHTML5.war WEB-INF/lib/log4j-1.2.17.jar
    cd VirtualViewerJavaHTML5/
    zip -u ../VirtualViewerJavaHTML5.war WEB-INF/lib/log4j-*.jar
    fapolicyd-cli --file add /opt/arkcase/app/snowbound --trust-file snowbound
    fapolicyd-cli --update
  fi

  if [[ -d /opt/arkcase/tmp/snowbound ]] ; then
    cd /opt/arkcase/tmp/snowbound
    zip -d snowbound-integration-5.6.2.war WEB-INF/lib/log4j-1.2.17.jar || say "snowbound-integration-5.6.2.war does not contain WEB-INF/lib/log4j-1.2.17.jar"
    cd /opt/arkcase/app/snowbound/webapps/VirtualViewerJavaHTML5
    zip -u /opt/arkcase/tmp/snowbound/snowbound-integration-5.6.2.war WEB-INF/lib/log4j-*.jar
  fi

  systemctl start snowbound
  sleep 3;
  systemctl status snowbound | tail -8
fi


if [[ -d /opt/arkcase/app/activemq ]] ; then
  systemctl stop activemq

  cd /opt/arkcase/app/activemq
  rm -f /opt/arkcase/app/activemq/lib/optional/log4j-1.2.17.jar /opt/app/old-log4j//opt/arkcase/app/activemq/lib/optional/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar lib/optional/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar lib/optional/
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar lib/optional/
  chown activemq: lib/optional/log4j-*

  chmod 644 lib/optional/log4j-*

  fapolicyd-cli --file add /opt/arkcase/app/activemq/ --trust-file activmeq
  fapolicyd-cli --update

  systemctl start activemq
  sleep 3;
  systemctl status activemq | tail -8

fi


if [[ -d /opt/arkcase/app/alfresco7 ]] ; then
  systemctl stop alfresco7

  rm -f /opt/arkcase/app/alfresco7/webapps/share/WEB-INF/lib/log4j-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/share/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/share/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/share/WEB-INF/lib/
  chown alfresco7: /opt/arkcase/app/alfresco7/webapps/share/WEB-INF/lib/log4j-*
  chmod 640 /opt/arkcase/app/alfresco7/webapps/share/WEB-INF/lib/log4j-*
  cd /opt/arkcase/app/alfresco7/webapps/
  zip -d share.war WEB-INF/lib/log4j-1.2.17.jar
  cd share/
  zip -u ../share.war WEB-INF/lib/log4j-*
  cd ../
  chown alfresco7: share.war

  rm -f /opt/arkcase/app/alfresco7/webapps/alfresco/WEB-INF/lib/log4j-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/alfresco/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/alfresco/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/alfresco/WEB-INF/lib/
  chown alfresco7: /opt/arkcase/app/alfresco7/webapps/alfresco/WEB-INF/lib/log4j-*
  chmod 640 /opt/arkcase/app/alfresco7/webapps/alfresco/WEB-INF/lib/log4j-*
  cd /opt/arkcase/app/alfresco7/webapps/
  zip -d alfresco.war WEB-INF/lib/log4j-1.2.17.jar
  cd alfresco/
  zip -u ../alfresco.war WEB-INF/lib/log4j-*
  cd ../
  chown alfresco7: alfresco.war

  rm -f /opt/arkcase/app/alfresco7/webapps/_vti_bin/WEB-INF/lib/log4j-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/_vti_bin/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/_vti_bin/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/alfresco7/webapps/_vti_bin/WEB-INF/lib/
  chown alfresco7: /opt/arkcase/app/alfresco7/webapps/_vti_bin/WEB-INF/lib/log4j-*
  chmod 640 /opt/arkcase/app/alfresco7/webapps/_vti_bin/WEB-INF/lib/log4j-*
  cd /opt/arkcase/app/alfresco7/webapps/
  zip -d _vti_bin.war WEB-INF/lib/log4j-1.2.17.jar
  cd _vti_bin/
  zip -u ../_vti_bin.war WEB-INF/lib/log4j-*
  cd ../
  chown alfresco7: _vti_bin.war

  fapolicyd-cli --file add /opt/arkcase/app/alfresco7 --trust-file alfresco7
  fapolicyd-cli --update

  systemctl start alfresco7
  sleep 3;
  systemctl status alfresco7 | tail -8
fi

if [[ -d /opt/arkcase/app/alfresco-search ]] ; then
  systemctl stop alfresco-search

  rm -f /opt/arkcase/app/alfresco-search/alfresco-search-services/solr/server/lib/ext/log4j-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco-search/alfresco-search-services/solr/server/lib/ext/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/alfresco-search/alfresco-search-services/solr/server/lib/ext/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/alfresco-search/alfresco-search-services/solr/server/lib/ext/
  chown alfresco-search: /opt/arkcase/app/alfresco-search/alfresco-search-services/solr/server/lib/ext/log4j-*
  chmod 644 /opt/arkcase/app/alfresco-search/alfresco-search-services/solr/server/lib/ext/log4j-*

  fapolicyd-cli --file add /opt/arkcase/app/alfresco-search --trust-file alfresco-search
  fapolicyd-cli --update

  systemctl start alfresco-search
  sleep 3;
  systemctl status alfresco-search | tail -8
fi

if [[ -d /opt/arkcase/app/pentaho ]] ; then
  systemctl stop pentaho
         
  rm -f /opt/arkcase/app/pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/lib/log4j-1.2.17.jar
  rm -f /opt/arkcase/app/pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/lib/apache-log4j-extras-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/lib/
  chown pentaho: /opt/arkcase/app/pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/lib/log4j-*
  chmod 600 /opt/arkcase/app/pentaho/pentaho-server/tomcat/webapps/pentaho/WEB-INF/lib/log4j-*

  rm -f /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/hdp30/lib/client/log4j-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/hdp30/lib/client/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/hdp30/lib/client/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/hdp30/lib/client/
  chown pentaho: /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/hdp30/lib/client/log4j-*
  chmod 600 /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/hdp30/lib/client/log4j-*

  rm -f /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/emr511/lib/client/log4j-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/emr511/lib/client/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/emr511/lib/client/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/emr511/lib/client/
  chown pentaho: /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/emr511/lib/client/log4j-*
  chmod 600 /opt/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/kettle/plugins/pentaho-big-data-plugin/hadoop-configurations/emr511/lib/client/log4j-*

  rm -f /opt/arkcase/app/pentaho/jdbc-distribution/lib/log4j-1.2.17.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/jdbc-distribution/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/jdbc-distribution/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/pentaho/jdbc-distribution/lib/
  chown pentaho: /opt/arkcase/app/pentaho/jdbc-distribution/lib/log4j-*
  chmod 600 /opt/arkcase/app/pentaho/jdbc-distribution/lib/log4j-*

  rm -f /opt/arkcase/app/pentaho/license-installer/lib/log4j-1.2.14.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/license-installer/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /opt/arkcase/app/pentaho/license-installer/lib/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /opt/arkcase/app/pentaho/license-installer/lib/
  chown pentaho: /opt/arkcase/app/pentaho/license-installer/lib/log4j-*
  chmod 600 /opt/arkcase/app/pentaho/license-installer/lib/log4j-*

_app_user=pentaho
_app_group=${_app_user}
_app_log4j_lib_check=log4j-1.2.14.jar
_app_log4j_dir=/opt/arkcase/app/pentaho-pdi/data-integration/lib
  if [[ -f ${_app_log4j_dir}/${_app_log4j_lib_check} ]] ; then
    say "${_app_user}, remediating ${_app_log4j_dir}/${_app_log4j_lib_check}..."
    \rm -vf ${_app_log4j_dir}/${_app_log4j_lib_check}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar ${_app_log4j_dir}
    chown -v ${_app_user}:${_app_group} ${_app_log4j_dir}/log4j-*
    chmod -v 600 ${_app_log4j_dir}/log4j-*
  fi

_app_log4j_lib_check=log4j-1.2.17.jar
_app_log4j_dir=/opt/arkcase/app/pentaho-pdi/data-integration/plugins/pentaho-big-data-plugin/hadoop-configurations/hdp30/lib/client
  if [[ -f ${_app_log4j_dir}/${_app_log4j_lib_check} ]] ; then
    say "${_app_user}, remediating ${_app_log4j_dir}/${_app_log4j_lib_check}..."
    \rm -vf ${_app_log4j_dir}/${_app_log4j_lib_check}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar ${_app_log4j_dir}
    chown -v ${_app_user}:${_app_group} ${_app_log4j_dir}/log4j-*
    chmod -v 600 ${_app_log4j_dir}/log4j-*
  fi

_app_log4j_lib_check=log4j-1.2.14.jar
_app_log4j_dir=/opt/arkcase/app/pentaho-pdi/license-installer/lib
  if [[ -f ${_app_log4j_dir}/${_app_log4j_lib_check} ]] ; then
    say "${_app_user}, remediating ${_app_log4j_dir}/${_app_log4j_lib_check}..."
    \rm -vf ${_app_log4j_dir}/${_app_log4j_lib_check}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar ${_app_log4j_dir}
    chown -v ${_app_user}:${_app_group} ${_app_log4j_dir}/log4j-*
    chmod -v 600 ${_app_log4j_dir}/log4j-*
  fi

_app_log4j_lib_check=log4j-1.2.17.jar
_app_log4j_dir=/opt/arkcase/app/pentaho-pdi/data-integration/plugins/kettle5-log4j-plugin/lib
  if [[ -f ${_app_log4j_dir}/${_app_log4j_lib_check} ]] ; then
    say "${_app_user}, remediating ${_app_log4j_dir}/${_app_log4j_lib_check}..."
    \rm -vf ${_app_log4j_dir}/${_app_log4j_lib_check}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar ${_app_log4j_dir}
    chown -v ${_app_user}:${_app_group} ${_app_log4j_dir}/log4j-*
    chmod -v 600 ${_app_log4j_dir}/log4j-*
  fi


_app_log4j_lib_check=log4j-1.2.17.jar
_app_log4j_dir=/opt/arkcase/app/pentaho-pdi/data-integration/plugins/pentaho-big-data-plugin/hadoop-configurations/emr511/lib/client
  if [[ -f ${_app_log4j_dir}/${_app_log4j_lib_check} ]] ; then
    say "${_app_user}, remediating ${_app_log4j_dir}/${_app_log4j_lib_check}..."
    \rm -vf ${_app_log4j_dir}/${_app_log4j_lib_check}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar ${_app_log4j_dir}
    chown -v ${_app_user}:${_app_group} ${_app_log4j_dir}/log4j-*
    chmod -v 600 ${_app_log4j_dir}/log4j-*
  fi

_app_log4j_lib_check=log4j-1.2.17.jar
_app_log4j_dir=/opt/arkcase/app/pentaho-pdi/jdbc-distribution/lib
  if [[ -f ${_app_log4j_dir}/${_app_log4j_lib_check} ]] ; then
    say "${_app_user}, remediating ${_app_log4j_dir}/${_app_log4j_lib_check}..."
    \rm -vf ${_app_log4j_dir}/${_app_log4j_lib_check}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar ${_app_log4j_dir}
    \cp -vf ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar ${_app_log4j_dir}
    chown -v ${_app_user}:${_app_group} ${_app_log4j_dir}/log4j-*
    chmod -v 600 ${_app_log4j_dir}/log4j-*
  fi

  fapolicyd-cli --file add /opt/arkcase/app/pentaho/ --trust-file pentaho
  fapolicyd-cli --update

  systemctl start pentaho
  sleep 3;
  systemctl status pentaho | tail -8
fi

_zookeeper_user=zookeeper
_zookeeper_group=${_zookeeper_user}
_zookeeper_log4j_dir=/opt/arkcase/app/zookeeper/lib
_zookeeper_log4j_lib_check=log4j-1.2.17.jar
_zookeeper_systemctl_unit=zookeeper

_app_user=${_zookeeper_user}
_app_group=${_zookeeper_group}
_app_log4j_dir=${_zookeeper_log4j_dir}
_app_log4j_lib_check=${_zookeeper_log4j_lib_check}
_app_systemctl_unit=${_zookeeper_systemctl_unit}
check_and_fix_log4j12

if [[ -d /usr/share/java/confluent-hub-client ]] ; then

  rm -f /usr/share/java/confluent-hub-client/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/confluent-hub-client/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/confluent-hub-client/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/confluent-hub-client/
  chown root: /usr/share/java/confluent-hub-client/log4j-*
  chmod 644 /usr/share/java/confluent-hub-client/log4j-*

fi

if [[ -d /usr/share/java/confluent-metadata-service ]] ; then

  rm -f /usr/share/java/confluent-metadata-service/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/confluent-metadata-service/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/confluent-metadata-service/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/confluent-metadata-service/
  chown root: /usr/share/java/confluent-metadata-service/log4j-*
  chmod 644 /usr/share/java/confluent-metadata-service/log4j-*

fi

if [[ -d /usr/share/java/confluent-kafka-mqtt ]] ; then

  rm -f /usr/share/java/confluent-kafka-mqtt/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/confluent-kafka-mqtt/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/confluent-kafka-mqtt/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/confluent-kafka-mqtt/
  chown root: /usr/share/java/confluent-kafka-mqtt/log4j-*
  chmod 644 /usr/share/java/confluent-kafka-mqtt/log4j-*

fi

if [[ -d /usr/share/java/confluent-rebalancer ]] ; then

  rm -f /usr/share/java/confluent-rebalancer/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/confluent-rebalancer/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/confluent-rebalancer/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/confluent-rebalancer/
  chown root: /usr/share/java/confluent-rebalancer/log4j-*
  chmod 644 /usr/share/java/confluent-rebalancer/log4j-*

fi

if [[ -d /usr/share/java/ksqldb ]] ; then

  rm -f /usr/share/java/ksqldb/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/ksqldb/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/ksqldb/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/ksqldb/
  chown root: /usr/share/java/ksqldb/log4j-*
  chmod 644 /usr/share/java/ksqldb/log4j-*

  systemctl restart confluent-ksql
  sleep 3;
  systemctl status confluent-ksql | tail -8

fi

if [[ -d /usr/share/java/confluent-control-center ]] ; then

  rm -f /usr/share/java/confluent-control-center/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/confluent-control-center/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/confluent-control-center/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/confluent-control-center/
  chown root: /usr/share/java/confluent-control-center/log4j-*
  chmod 644 /usr/share/java/confluent-control-center/log4j-*

  systemctl restart confluent-control-center
  sleep 3;
  systemctl status confluent-control-center | tail -8

fi

if [[ -d /usr/share/java/schema-registry ]] ; then

  rm -f /usr/share/java/schema-registry/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/schema-registry/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/schema-registry/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/schema-registry/
  chown root: /usr/share/java/schema-registry/log4j-*
  chmod 644 /usr/share/java/schema-registry/log4j-*

  systemctl restart confluent-schema-registry
  sleep 3;
  systemctl status confluent-schema-registry | tail -8

fi

if [[ -d /usr/share/java/kafka-rest-lib ]] ; then

  rm -f /usr/share/java/kafka-rest-lib/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/kafka-rest-lib/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/kafka-rest-lib/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/kafka-rest-lib/
  chown root: /usr/share/java/kafka-rest-lib/log4j-*
  chmod 644 /usr/share/java/kafka-rest-lib/log4j-*
  systemctl restart confluent-kafka-rest
  sleep 3;
  systemctl status confluent-kafka-rest | tail -8

fi

if [[ -d /usr/share/java/kafka-connect-replicator ]] ; then

  rm -f /usr/share/java/kafka-connect-replicator/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/kafka-connect-replicator/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/kafka-connect-replicator/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/kafka-connect-replicator/
  chown root: /usr/share/java/kafka-connect-replicator/log4j-*
  chmod 644 /usr/share/java/kafka-connect-replicator/log4j-*

  systemctl restart confluent-kafka-connect
  sleep 3;
  systemctl status confluent-kafka-connect | tail -8

fi

if [[ -d /usr/share/java/kafka ]] ; then

  rm -f /usr/share/java/kafka/confluent-log4j-1.2.17-cp2.2.jar
  cp ${_log4j2_archive_bundle_path}/log4j-1.2-api-${_log4j2_release}.jar /usr/share/java/kafka/
  cp ${_log4j2_archive_bundle_path}/log4j-api-${_log4j2_release}.jar /usr/share/java/kafka/
  cp ${_log4j2_archive_bundle_path}/log4j-core-${_log4j2_release}.jar /usr/share/java/kafka/
  chown root: /usr/share/java/kafka/log4j-*
  chmod 644 /usr/share/java/kafka/log4j-*

  systemctl restart confluent-kafka
  sleep 3;
  systemctl status confluent-kafka | tail -8

fi

if [[ -d /opt/arkcase/install ]] ; then

  cd /opt/arkcase/install
  _password=password
  for _d in $(find . -type d | tail -n +2) ; do zip -P ${_password} -v -r stuff.zip ${_d} ; done && for _d in $(find . -type d | tail -n +2) ; do rm -rf ${_d} ; done

fi