#!/bin/bash


#set defaults
OFFSET=0
NAMES="$HOME/.bomber/names"
URLS="$HOME/.bomber/urls"
XML="$HOME/.bomber/xml"
APIKEY="XXX"


#parse options
OPTIND=2
while getopts ":o:" opt; do
   case $opt in
      o)
         echo "o was triggered $OPTARG" >&2
         OFFSET=$OPTARG
         ;;
      \?)
         echo "Invalid" >&2
         ;;
   esac
done


#define functions
extract () {
   xml sel -t -m //$1 -v name -n $XML > $NAMES
   xml sel -t -m //$1 -v api_detail_url -n $XML > $URLS
   }


#execute command
case $1 in
   "update")
      curl -o $XML "http://www.giantbomb.com/api/videos/?api_key=$APIKEY&offset=$OFFSET"
      extract video
      ;;
   "premium")
      curl -o $XML "http://www.giantbomb.com/api/videos/?api_key=$APIKEY&filter=video_type:10&offset=$OFFSET"
      extract video
      ;;
   "get")
      DETAIL=`sed "$2!d" $URLS`?api_key=$APIKEY
      DOWNLOAD=`curl $DETAIL | xml sel -t -m //results -v low_url`
      curl -O $DOWNLOAD
      ;;
   "list")
      cat $NAMES
      ;;
   "view")
      less -N -I $NAMES
      ;;
   "search")
      curl -o $XML "http://www.giantbomb.com/api/search/?api_key=$APIKEY&query=$2&resources=video"
      extract video
      ;;
   *)
   echo "$1 is not a valid command."
      ;;
esac
