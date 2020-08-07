#!/bin/sh
CSR_IN=$1
REQ_OUT=$2
P7B_OUT=$3
PEM_OUT=$4
CERT_TEMPLATE=$5
ADCS_URL=$6

AUTHENTICATED=`klist -s`
if [ $? -ne 0 ];
then
  echo Please authenticate via kinit a_directory_admin_user_id, then try again
  exit 1
fi

ENCODED=`cat $CSR_IN | hexdump -v -e '1/1 "%02x\t"' -e '1/1 "%_c\n"' |
        LANG=C awk '
        $1 == "20"                      { printf("%s",      "+");   next    }
        $2 ~  /^[a-zA-Z0-9.*()\/-]$/    { printf("%s",      $2);    next    }
                                        { printf("%%%s",    $1)             }'`

curl -k --negotiate -u : -d CertRequest=${ENCODED} -d SaveCert=yes -d Mode=newreq -d CertAttrib=CertificateTemplate:"${CERT_TEMPLATE}" -o ${REQ_OUT} ${ADCS_URL}/certfnsh.asp

APPLICATION_REQUEST_ID=`grep -m 1 ReqID ${REQ_OUT} | sed -e 's/.*ReqID=\(.*\)&amp.*/\1/g'`

if [ "$APPLICATION_REQUEST_ID" == "" ];
then
  echo "Didn't get a request id! View $REQ_OUT to see what happened."
  exit 1
fi

echo waiting for ADCS to do some work...
sleep 15

curl -k -o ${P7B_OUT} -A "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.5) Gecko/2008120122 Firefox/3.0.5" --negotiate -u : "${ADCS_URL}/certnew.p7b?ReqID=${APPLICATION_REQUEST_ID}&Enc=b64"

openssl pkcs7 -print_certs -in ${P7B_OUT}  -out ${PEM_OUT}


