#! /bin/bash
cut -f 10 $1 | awk '{if (arr[$0]=="") {print $0; arr[$0]=1;}}' > $2
