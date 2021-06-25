#! /bin/sh

for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13; do 
  ( ./demo1.updater.main.sh $i >/dev/null 2>&1 &);
done
