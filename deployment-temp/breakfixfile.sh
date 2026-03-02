#!/bin/bash

i=1
cd /var/www/html
echo "test" > index.html
while(true)
do
mkdir linkedpages
mkdir -p imagedir$i/webimage$i/image$i.png
mkdir -p webpage$i/imageweb$i/web$i.html
touch imagedir$i/image$i.png
touch webpage$i/web$i.html
touch image$i.png
touch web$i.html
mkdir -p secondimagedir$i/webimage$i/image$i.png
mkdir -p secondwebpage$i/imageweb$i/web$i.html
touch secondimagedir$i/image$i.png
touch secondwebpage$i/web$i.html
ln -s secondwebpage$i/web$i.html linkedpages/secondlink$i.html
ln -s webpage$i/web$i.html linkedpages/firstlink$i.html
((i=i+1))
done
