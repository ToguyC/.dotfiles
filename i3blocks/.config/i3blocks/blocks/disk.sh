#!/bin/bash

left=$(df -h / | awk 'NR==2 {print $4}')

echo "<span bgcolor='#283593'> R: $left </span>"

exit 0