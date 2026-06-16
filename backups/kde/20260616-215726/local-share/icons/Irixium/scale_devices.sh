#!/bin/bash

rm -v 32x32/devices/$1
magick  48x48/devices/$1 -verbose -resize 32x 32x32/devices/$1
rm -v 24x24/devices/$1
magick  48x48/devices/$1 -verbose -resize 24x 24x24/devices/$1
rm -v 22x22/devices/$1
magick  48x48/devices/$1 -verbose -resize 22x 22x22/devices/$1
rm -v 16x16/devices/$1
magick  48x48/devices/$1 -verbose -resize 16x 16x16/devices/$1
