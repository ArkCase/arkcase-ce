#!/bin/bash

NEW_BIND_PWD=$1
FACTS_FILE_NAME=$2

if [ "$NEW_BIND_PWD" == "" ]; then
	echo "update-passwords.sh <new bind user password> <facts file name>"
	exit 1
fi

if [ "$FACTS_FILE_NAME" == "" ]; then
        echo "update-passwords.sh <new bind user password> <facts file name>"
        exit 2
fi

SYMM_KEY=$(openssl rsautl -decrypt -inkey /etc/pki/tls/private/`hostname`.key -in /opt/app/arkcase/common/symmetricKey.encrypted)

ENC_BIND_PWD=$(echo $NEW_BIND_PWD | openssl enc -md sha256 -aes-256-cbc -a -pass pass:$SYMM_KEY)

cp /data/arkcase-ce/vagrant/provisioning/$FACTS_FILE_NAME /data/arkcase-ce/vagrant/provisioning/$FACTS_FILE_NAME.`date +%Y-%m-%dT%H-%M`
cp /opt/app/arkcase/data/arkcase-home/.arkcase/acm/acm-config-server-repo/ldap/ldap-server.yaml /opt/app/arkcase/data/arkcase-home/.arkcase/acm/acm-config-server-repo/ldap/ldap-server.yaml.`date +%Y-%m-%dT%H-%M`
cp /opt/app/arkcase/app/alfresco7/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/ldap1/ldap-ad.properties /opt/app/arkcase/app/alfresco7/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/ldap1/ldap-ad.properties.`date +%Y-%m-%dT%H-%M`
cp /opt/app/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/applicationContext-security-ldap.properties /opt/app/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/applicationContext-security-ldap.properties.`date +%Y-%m-%dT%H-%M`
#cp /opt/app/arkcase/app/arkcase-ldap-authority/server.yml /opt/app/arkcase/app/arkcase-ldap-authority/server.yml.`date +%Y-%m-%dT%H-%M`

sed -i "s|ldap_bind_password: .*|ldap_bind_password: '$NEW_BIND_PWD'|g" $FACTS_FILE_NAME
sed -i "s|      authUserPassword: .*|      authUserPassword: ENC($ENC_BIND_PWD)|g" /opt/app/arkcase/data/arkcase-home/.arkcase/acm/acm-config-server-repo/ldap/ldap-server.yaml
sed -i "s|ldap.synchronization.java.naming.security.credentials=.*|ldap.synchronization.java.naming.security.credentials=$NEW_BIND_PWD|g" /opt/app/arkcase/app/alfresco7/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/ldap1/ldap-ad.properties
sed -i "s|contextSource.password=.*|contextSource.password=$NEW_BIND_PWD|g" /opt/app/arkcase/app/pentaho/pentaho-server/pentaho-solutions/system/applicationContext-security-ldap.properties
#sed -i "s|    manager-password: .*|    manager-password: '$NEW_BIND_PWD'|g" /opt/app/arkcase/app/arkcase-ldap-authority/server.yml

