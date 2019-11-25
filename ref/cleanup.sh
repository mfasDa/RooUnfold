grep -q Verkerke $1
if [ $? -eq 0 ]; then
    sed -e '1,5d' $1 > tmp
    mv tmp $1
fi
