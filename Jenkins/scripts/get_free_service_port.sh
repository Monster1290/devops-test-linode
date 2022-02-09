#!/bin/bash

# this script searches first free port in range [1025 : 32767] starting with random port in that range.
# if port was found then it's echoed, otherwise returned exit code 1 with echoed error message.

# 1 - 1024 -- well-known ports range
# 32768 - 60999 -- Linux ephemeral port range
# 49152 – 65535 -- IANA RFC 6335 ephemeral port range
MIN_PORT=1025
MAX_PORT=32767
port_range=$((MAX_PORT - MIN_PORT))

# get port number as port_in_use_index number in list of usable ports [1025, 1026, ... , 32767]
random_service_port=$((MIN_PORT + RANDOM % port_range))

# get list of ports already in use in system with following steps:
# get listening ports | filter with 'LISTEN' state | get 'Local Address:Port' column | filter port number | sort unique
mapfile -t ports_in_use < <(ss -tuln | grep LISTEN | awk '{print $5}' | grep -o '[0-9]*$' | sort -ug)

if [[ ${#ports_in_use[@]} -eq 0 ]]; then
  echo "$random_service_port"
  exit
fi

usable_port_in_use=()

# filter ports in use with port in range [MIN_PORT : MAX_PORT]
for port in "${ports_in_use[@]}"; do
  if [[ $port -ge $MIN_PORT ]] || [[ $port -le $MAX_PORT ]]; then
    usable_port_in_use+=("$port")
  fi
done

usable_port_in_use_last=${usable_port_in_use[ ${#usable_port_in_use[@]} - 1 ]}

if [[ ${#usable_port_in_use[@]} -eq 0 ]] || [[ $random_service_port -gt $usable_port_in_use_last ]]; then
  echo "$random_service_port"
  exit
elif [[ ${#usable_port_in_use[@]} -eq "$port_range" ]]; then
  echo "Unable to find free service port"
  exit 1
fi

# Search if $random_service_port is in use already.
# If it is, then save port_in_use_index, otherwise return $random_service_port as result.
port_in_use_index=0
for port_in_use in "${usable_port_in_use[@]}"; do

  if [[ $port_in_use -eq $random_service_port ]]; then
    break
  elif [[ $port_in_use -gt $random_service_port ]]; then
    echo "$random_service_port"
    exit
  fi
  ((port_in_use_index=port_in_use_index+1))

done

# choose initial walk direction randomly
is_forward_direction=$(( RANDOM % 2 ))

max_i=$(( ${#usable_port_in_use[@]} - 1 ))

# search for first free port in both directions
# walk in opposite direction occurs if in current direction no free ports
for _ in {1..2}; do

  i=$port_in_use_index
  if [[ $is_forward_direction -eq 0 ]]; then

    while [[ $i -lt $max_i ]]; do

      if [[ $(( ${usable_port_in_use[$i]} + 1 )) -ne ${usable_port_in_use[$i+1]} ]]; then
        echo "$(( ${usable_port_in_use[$i]} + 1 ))"
        exit
      fi
      ((i=i+1))

    done

    if [[ ${usable_port_in_use[$i]} -lt $MAX_PORT ]]; then
      echo "$(( ${usable_port_in_use[$i]} + 1 ))"
      exit
    fi

  else

    while [[ $i -gt 0 ]]; do

      if [[ $(( ${usable_port_in_use[$i]} - 1 )) -ne ${usable_port_in_use[$i-1]} ]]; then
        echo "$(( ${usable_port_in_use[$i]} - 1 ))"
        exit
      fi
      ((i=i-1))

    done

    if [[ ${usable_port_in_use[0]} -gt $MIN_PORT ]]; then
      echo "$(( ${usable_port_in_use[$i]} - 1 ))"
      exit
    fi

  fi

  ((is_forward_direction=1-is_forward_direction))

done