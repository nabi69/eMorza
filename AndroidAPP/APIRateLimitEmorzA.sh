#!/bin/bash
#Rate Limit is for any service security check.
#Backend server also need a way to remove Blocked IP or Unrestrict valid client.
#Bellow is for an example API from Xp Group INC.
#Before UN Comments 147.28 call me.
#Others your network will be BLOCK.
#You can try also from Android APP.
#https://drive.google.com/file/d/147x7sy0Pg90_-cXkwkk7PuamTVJz8OIE/view?usp=sharing
#URL="http://147.28.87.212:3000/api/getData"
#This is for Morzaa
URL="https://api.morzaa.com:5005/api/admin/galleries"
LOG="APIRateLimitEmorzaA.log"

echo "=== RATE LIMIT TEST START ===" > $LOG
echo "Testing $URL" >> $LOG

for i in {1..14}
do
    echo "" >> $LOG
    echo "--- Request $i ---" >> $LOG
    curl -v $URL >> $LOG 2>&1
    echo "" >> $LOG
    sleep 1
done

echo "=== RATE LIMIT TEST COMPLETE ===" >> $LOG

echo "Done. Check APIRateLimitEmorzaA.log"
echo "EnjoY.............................."

