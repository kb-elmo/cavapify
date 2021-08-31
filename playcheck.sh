#!/bin/bash

img_url=""

while :
do
   new_img_url=$(playerctl metadata mpris:artUrl 2>/dev/null | sed s/open.spotify.com/i.scdn.co/)
   if [[ "$new_img_url" != "$img_url" ]]
   then
      linktype=$(echo "$new_img_url" | awk -F "://" '{print$1}')
      if [[ "$linktype" == "file" ]]
      then
         direct_file=$(echo "$new_img_url" | sed 's/file\:\/\///')
         img="$direct_file"
      else
         img=$(mktemp)
         wget "$new_img_url" -O $img -q
      fi
      numcol=6
      fuzz=30

      hex="#FFFFFF"
      while [[ "$hex" == "#FFFFFF" && "$fuzz" != "60" ]]
      do
         thresh=$((100-fuzz))
         sortedfinalcolors=$(convert "$img" -scale 50x50! -depth 8 \
         \( -clone 0 -colorspace HSB -channel gb -separate +channel -threshold $thresh% \
         -compose multiply -composite \) \
         -alpha off -compose copy_opacity -composite sparse-color:- |\
         convert -size 50x50 xc: -sparse-color voronoi '@-' \
         +dither -colors $numcol -depth 8 -format "%c" histogram:info: |\
         sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\1,#\2/p' | sort -r -n -k 1 -t ",")
         hex=`echo "$sortedfinalcolors" | head -n 1 | cut -d, -f2`
         ((fuzz+=10))
      done
      sed -i "s/foreground.*/foreground = \'$hex\'/" $HOME/.config/cava/config
      pkill -USR2 cava
      if [[ "$linktype" != "file" ]]
      then
         rm "$img"
      fi
   fi
   img_url=$new_img_url
   sleep 1
done
