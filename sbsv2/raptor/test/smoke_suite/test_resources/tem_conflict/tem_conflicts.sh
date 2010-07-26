i=0
while [ $i -lt 50 ]
do
    echo abcdefghijklmnopqrstuvwxyz > $EPOCROOT/A
    cp $EPOCROOT/A $EPOCROOT/B
    rm $EPOCROOT/A
    rm $EPOCROOT/B
    i=$[i + 1]
done

