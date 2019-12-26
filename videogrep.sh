#!/bin/bash
#
# videogrep

# Original script at:  http://activearchives.org/wiki/Videogrep
# Updated by sc0ttj:   https://github.com/sc0ttj/videogrep.sh
#
# Usage:
#   ./videogrep <movie_file> <search_term> [padding-start] [padding-end]
#
# The subtitle file to be searched is implicit--it is always named the same
# as the movie file, but with a .sub extension. We convert automatically
# to .sub when another format (right now only .srt) is used.
#
# Padding start and padding end should be given in milliseconds. Values of
# between 0 and 200 are usually good. ( Defaults to 50  90 )
#

if [ ! -f "$1" ] || [ -z "$2" ];then
  echo
  echo "Usage:"
  echo
  echo "videogrep.sh <video-file> <search-term> [padding-start] [padding-end]"
  echo
  exit 1
fi

mkdir -p $HOME/videogrep_output
output_file="$HOME/videogrep_output/${2//|/,}__$(basename "${1}")"
output_file="${output_file%.*}.avi"

rm "$output_file" &>/dev/null

# function to round up to nearest integer
ceil() {
  echo -n $(echo "define ceil (x) {if (x<0) {return x/1} \
    else {if (scale(x)==0) {return x} \
    else {return x/1 + 1 }}} ; ceil($1)" | bc)
}

# get framerate of video (requires mediainfo)
#framerate="$(mediainfo "$1" 2>/dev/null | grep "^Frame rate"| rev | cut -f2 -d' ' | cut -f2 -d'.' | rev)"

# get frame rate using ffprobe
framerate=$(( $(ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate "$1" | sed 's#/# / #g') ))

[ "$framerate" = "0" ] && framerate=25
framerate="${framerate:-25}"

vid="$1"
term="$2"
base="${vid%%.*}"

if [ ! -e "$base.sub" ];then
  if [ -e "$base.srt" ];then
    echo "Dumping '$base.sub' from '$base.srt'..."
    mplayer "$vid" -sub "$base.srt" -dumpmicrodvdsub -endpos 1
    mv dumpsub.sub "$base.sub"
  fi
fi

# look for subtitles as (moviename - ext) + ".sub"
subtitle="${vid%%.*}.sub"

if [ ! -f "$subtitle" ];then
  echo "No subtitle found for '$(basename "$1")'"
  exit 1
fi

# milliseconds to add to the start time (negative = earlier)
dstart="-${3:-50}"
# milliseconds to add to the end time
dend="${4:-90}"

echo
echo "Video file:     $(basename "$vid")"
echo "Subtitle file:  $(basename $subtitle)"
echo "Search term(s): $term"
echo

matching_items="$(cat "$subtitle"  | egrep -i "$2" | grep -v '\-\-' | uniq)"

if [ -z "$matching_items" ];then
  echo "No items matching '$2'"
  exit 1
fi

echo "Speech found:"
echo
echo "${matching_items}"
echo
sleep 1

cat "$subtitle"  | \
  egrep -i "$2" | \
  grep -v '\-\-' | \
  uniq | \
  sed -e 's/{\([[:digit:]]*\)}{\([[:digit:]]*\)}.*/\1 \2/'| \
  awk '{ print (($1 + '$dstart'))" " (($2 + '$dend')) }' | \
  awk '{ print ($1/'$framerate') " " ($2/'$framerate') }' | \
  awk 'BEGIN { cur=0 }
{
  if ($1 > cur) print cur " " $1 " 0"
  cur = $2
}
END { print cur " 10000 0" }
' > videogrep.edl

if [ ! -s videogrep.edl ];then
  echo "Nothing to do"
  rm videogrep.edl &>/dev/null
  exit 0
fi

# get proper video dimensions
video_details="$(ffprobe -v error -show_format -show_streams "$vid" | egrep 'display_aspect_ratio|coded_height')"
video_height="$(echo "$video_details" | head -1 | cut -f2 -d'=')"
aspect_ratio_as_ratio="$(echo "$video_details" | tail -1 | cut -f2 -d'=')"
aspect_ratio_as_sum="$(echo "$aspect_ratio_as_ratio" | sed 's#:# / #')"
aspect_ratio_as_float="$(echo "$aspect_ratio_as_sum" | bc -l)"
# calculate required width, based on height and aspect ratio
video_width="$(echo "$video_height * ($aspect_ratio_as_sum)" | bc -l)"
video_width="$(ceil "$video_width")"


echo
echo '------------------------------------'
echo "Creating: $output_file"
echo '------------------------------------'
echo

mencoder "$vid" \
  -quiet \
  -edl videogrep.edl \
  -oac pcm \
  -ovc copy \
  -vf scale=${video_width:-640}:${video_height:-480} \
  -force-avi-aspect $aspect_ratio_as_float \
  -aspect $aspect_ratio_as_ratio \
  -of avi \
  -o "${output_file}" 1>/dev/null \
|| {
  echo 'Mencoder failed!' && exit 1
}

rm videogrep.edl &>/dev/null

if [ -f "$output_file" ];then
  mplayer "$output_file" &>/dev/null
  exit $?
else
  echo 'No output file created!'
  exit 1
fi

