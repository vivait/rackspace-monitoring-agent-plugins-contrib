#!/bin/bash
#
# Description: Custom plugin which checks beanstalk queue stats

# Copyright 2015 Viva IT Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PORT="11300"
HOST="localhost"

while getopts ":p:h:" opt; do
  case $opt in
    p)
      PORT="$OPTARG"
      ;;
    h)
      HOST="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

shift $((OPTIND-1))

# Look for stats on a tube or on everything?
if [ -z $1 ]; then
  COMMAND="stats\r\n"
else
  COMMAND="stats-tube $1\r\n"
fi

echo -e "$COMMAND" | nc $HOST $PORT | \
while read line
do
    output=($line)

    if [ -z ${output[1]} ]; then continue; fi;
    unit=""
    type="uint32"

    case ${output[0]} in
      "OK")
        continue
        ;;
      "version:")
        type="string"
        ;;
      "rusage-utime:")
        type="float"
        ;;
      "rusage-stime:")
        type="float"
        ;;
      "uptime:")
        type="uint64"
        unit="seconds"
        ;;
      "max-job-size:")
        unit="bytes"
        ;;
      "binlog-max-size:")
        type="uint64"
        unit="bytes"
        ;;
      "id:")
        type="string"
        ;;
      "hostname:")
        type="string"
        ;;
    esac

    echo "metric ${output[0]:0:-1} $type ${output[1]} $unit"
done
