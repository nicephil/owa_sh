#!/bin/bash

read -r -p "ACCOUNT(domain\user): " USER
echo ""
read -r -s -p "PASSWORD: " PASSWD
echo ""

# please add your webmail site (https://webmail.xxx.com/)here
SITE_NAME=xxx

MAILLIST="maillist.txt"

UA="Opera/9.80 (X11; Linux i686; U; en) Presto/2.10.229 Version/11.60"

REFER="https://webmail.${SITE_NAME}.com/Exchweb/bin/auth/owalogon.asp?url=https://webmail.${SITE_NAME}.com/Exchange&reason=0"

AUTH_URL="https://webmail.${SITE_NAME}.com/Exchweb/bin/auth/owaauth.dll"

COOKIES="cookies.txt"


RESULT=`curl -s -L -A $UA -c $COOKIES -b $COOKIES -d "destination=https://webmail.${SITE_NAME}.com/Exchange&flags=0&trusted=4&username=$USER&password=$PASSWD" $AUTH_URL`

#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#echo "$RESULT"
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

EXCHANGE_URL=`echo $RESULT | sed -n 's/^.*"\(https[^ <>"]*\)\/".*$/\1/gp'`
if [[ "$EXCHANGE_URL" != "" ]]
then
    echo "PHASE1 - Auth OK!"
else
    echo "PHASE1 - Auth FAILED!"
    echo "$RESULT"
    exit -1
fi

RESULT=`curl -s -A $UA -b $COOKIES -c COOKIES -L -e $REFER -G "$EXCHANGE_URL/Inbox/?Cmd=contents&Page=1&View=%E9%82%AE%E4%BB%B6"`

##echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#echo "$RESULT"
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

LIST=`echo "$RESULT" | sed -n 's/EML/EML\n/gp' | sed -n 's/^.*"Inbox\/\([^ "<>]*EML\)$/\1/gp' | awk '!aa[$0]++'`
if [[ "$LIST" != "" ]]
then
    echo "PHASE2 - Fetch Mail List DONE!"
else
    echo "PHASE2 - Fetch Mail List FAILED!"
    echo "$RESULT"
    exit -2
fi

#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$LIST" | tee $MAILLIST | nl | sed 's/%20/_/g'
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

read -p "Which Mail Fetched? " NUM
echo ""

EML=`sed -n "${NUM}p" $MAILLIST`

RESULT=`curl -s -A $UA -b $COOKIES -c COOKIES -L -e $REFER -G "${EXCHANGE_URL}/Inbox/${EML}/?Cmd=open"`

#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$RESULT" | sed '1,/Microsoft/d' | tee ${NUM}_${EML}.html
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "elinks ${NUM}_${EML}.html"
#w3m ${NUM}_${EML}.html




