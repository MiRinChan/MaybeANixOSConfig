#!/bin/bash

rm -v 32x32/actions/$1
magick 48x48/actions/$1 -verbose -resize 32x 32x32/actions/$1
rm -v 24x24/actions/$1
magick 48x48/actions/$1 -verbose -resize 24x 24x24/actions/$1
rm -v 22x22/actions/$1
magick 48x48/actions/$1 -verbose -resize 22x 22x22/actions/$1
rm -v 16x16/actions/$1
magick 48x48/actions/$1 -verbose -resize 16x 16x16/actions/$1
