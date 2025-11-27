#!/bin/bash

if [ "$vncpassword" = "" ]
then
    vncpassword="insecure"
fi

printf "$vncpassword\n$vncpassword\n\n" | vncserver :1
/.novnc/utils/novnc_proxy --vnc localhost:5901
