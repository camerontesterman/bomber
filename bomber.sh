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
UA="cyborgx7bomber"

#set defaults
QUALITY=low_url
OFFSET=0
FILE=false
FILEPATH=""
EDIT=false
RESUME=false

#check for api-key
if [ $APIKEY == "XXX" ]; then
   echo "Please set your api-key in the script file."
   echo "You can find your api-key on http://giantbomb.com/api while logged in."
   exit
fi

#write helptext
HELPTEXT='bomber: download videos from Giant Bomb using the api.
v0.3

Usage: bomber <command> [options] [argument]

Commands:
   update    update the list of videos that are available to download
   premium   same as "update" but only for premium videos
   search    search for videos using the search function provided by the api
   view      view the list of videos available to download generated by "update", "premium" or "search"
   get       download a video
   list      list the videos that have been downloaded
   watch     play a video that has been downloaded, using the mpv player
   remove    remove a downloaded video
   clear     delete all downloaded videos
   p4er      play the Persona 4 Endurance Run

Options:
   -o        specify the offset from the beginning when using "update" and "premium"
   -f        specify where to save a file instead of managing videos internally
   -n        retrieve 1000 instead of 1800 for newer videos
   -r        resume a the download of a partial videofile. Leads to funkyness in the list.'

#parse options
OPTIND=2
while getopts "o:f:nhr" opt; do
   echo $opt
   case $opt in
      o)
         OFFSET=$OPTARG
         ;;
      h)
         echo -e $HELPTEXT
         ;;
      f)
         FILE=true
         FILEPATH=$OPTARG
         ;;
      n)
         EDIT=true
         ;;
      r)
         RESUME=true
         ;;
      \?)
         echo "Invalid $opt"
         ;;
   esac
done
#get command
COMMAND=$1

#shift to arguments
shift $((OPTIND-1))

#define functions
extract () {
   xml sel -t -m //$1 -v name -n $XML > $NAMES
   xml sel -t -m //$1 -v api_detail_url -n $XML > $URLS
   }

download () {
   DETAIL=`sed "$1!d" $URLS`?api_key=$APIKEY
   DOWNLOAD=`curl -A $UA $DETAIL | xml sel -t -m //results -v $QUALITY`
   echo $DOWNLOAD
   if [ "$EDIT" = true ]; then
      DOWNLOAD=`echo $DOWNLOAD| sed -e "s/1800/1000/g"`
   fi
   if [ "$RESUME" = true ]; then
      RES="-C -"
   else
      RES=""
   fi
   if [ "$FILE" = true ]; then
      curl -A $UA $RES -o $FILEPATH $DOWNLOAD"?api_key="$APIKEY
   else
      echo $DOWNLOAD | sed 's/.*\///' >> $VIDEOFILES
      sed "$1!d" $NAMES >> $VIDEONAMES
      cd $VIDEOS && { curl -A $UA $RES -o `echo $DOWNLOAD | sed 's/.*\///'`  $DOWNLOAD"?api_key="$APIKEY ; cd - ; }
   fi
   }

#execute command
case $COMMAND in
   "update")
      curl -A $UA -o $XML "http://www.giantbomb.com/api/videos/?api_key=$APIKEY&offset=$OFFSET"
      extract video
      ;;
   "premium")
      curl -A $UA -o $XML "http://www.giantbomb.com/api/videos/?api_key=$APIKEY&filter=video_type:10&offset=$OFFSET"
      extract video
      ;;
   "get")
      for i in $@; do
         download $i
      done
      ;;
   "view")
      less -N -I $NAMES
      ;;
   "search")
      curl -A $UA -o $XML "http://www.giantbomb.com/api/search/?api_key=$APIKEY&query=$@&resources=video"
      extract video
      ;;
   "list")
      less -N -I $VIDEONAMES
      ;;
   "watch")
      mpv $VIDEOS`sed "$@!d" $VIDEOFILES`
      ;;
   "remove")
      rm $VIDEOS`sed "$@!d" $VIDEOFILES`
      sed -i "$@d" $VIDEONAMES
      sed -i "$@d" $VIDEOFILES
      ;;
   "clear")
      while read file; do
         rm $VIDEOS$file
      done < $VIDEOFILES
      rm $VIDEONAMES
      rm $VIDEOFILES
      ;;
   "p4er")
      mpv http://qlcrew.com/?playlist=P4
      ;;
   "bomb")
      echo "3..."
      sleep 1
      echo "2..."
      sleep 1
      echo "1..."
      sleep 1
      echo "BOOM!!!"
      ;;
   "")
      echo "$HELPTEXT"
      ;;
   *)
      echo "$COMMAND is not a valid command."
      ;;
esac
