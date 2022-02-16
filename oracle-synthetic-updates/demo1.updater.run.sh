#! /bin/sh

for i in `seq 1 3`; do
  ( ./demo1.updater.main.sh $i >/dev/null 2>&1 &);
done
