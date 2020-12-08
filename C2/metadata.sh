#!/bin/bash

echo '{'
for i in $(curl -s http://169.254.169.254/latest/meta-data/)
do
    printf ' "'
    printf $i |  sed 's#/##g' && printf '": '
    output=$(curl -s http://169.254.169.254/latest/meta-data/${i})
    if [[ $output == *$'\n'* ]]
    then
        printf '[ "'
        echo -n "$output" | sed 's#/##g' | sed ':a;N;$!ba;s/\n/", "/g'
        echo '" ],'
    else
        printf '"'
        printf $output | sed 's#/##g' | sed ':a;N;$!ba;s/\n/", "/g'
        printf '",\n'
    fi
done
echo '}'