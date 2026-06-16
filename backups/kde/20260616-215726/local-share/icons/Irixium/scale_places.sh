#!/bin/bash

rm -v 32x32/places/$1
magick 48x48/places/$1 -verbose -resize 32x 32x32/places/$1
rm -v 24x24/places/$1
magick 48x48/places/$1 -verbose -resize 24x 24x24/places/$1
rm -v 22x22/places/$1
magick 48x48/places/$1 -verbose -resize 22x 22x22/places/$1
rm -v 16x16/places/$1
magick 48x48/places/$1 -verbose -resize 16x 16x16/places/$1
