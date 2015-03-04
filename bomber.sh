#!/bin/bash

#set api-key
APIKEY="XXX"

#set folders and files
NAMES="$HOME/.bomber/names"
URLS="$HOME/.bomber/urls"
XML="$HOME/.bomber/xml"
VIDEOS="$HOME/.bomber/videos/"
VIDEONAMES="$HOME/.bomber/videonames"
VIDEOFILES="$HOME/.bomber/videofiles"

#set defaults
OFFSET=0

#check for api-key
if [ $APIKEY == "XXX" ]; then
   echo "Please set your api-key in the script file."
   echo "You can find your api-key on http://giantbomb.com/api while logged in."
   exit
fi

#parse options
OPTIND=2
while getopts ":o:" opt; do
   case $opt in
      o)
         OFFSET=$OPTARG
         ;;
      \?)
         echo "Invalid"
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
      echo $DOWNLOAD | sed 's/.*\///' >> $VIDEOFILES
      sed "$2!d" $NAMES >> $VIDEONAMES
      cd $VIDEOS && { curl -O $DOWNLOAD ; cd - ; }
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
   "have")
      less -N -I $VIDEONAMES
      ;;
   "watch")
      mpv $VIDEOS`sed "$2!d" $VIDEOFILES`
      ;;
   "remove")
      rm $VIDEOS`sed "$2!d" $VIDEOFILES`
      sed -i "$2d" $VIDEONAMES
      sed -i "$2d" $VIDEOFILES
      ;;
   "")
      echo "Please specify a command."
      ;;
   *)
      echo "$1 is not a valid command."
      ;;
esac
