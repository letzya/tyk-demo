#!/bin/bash

function bootstrap_progress {
  dot_count=$((dot_count+1))
  dots=$(printf "%-${dot_count}s" ".")
  echo -ne "  Bootstrapping $deployment ${dots// /.} \r"
}

function log_http_result {
  if [ "$1" = "200" ] || [ "$1" = "201" ]
  then 
    log_ok
  else 
    log_message "  ERROR: $1"
    touch .bootstrap_error_occurred
  fi
}

function log_json_result {
  status=$(echo $1 | jq -r '.Status')
  if [ "$status" = "OK" ] || [ "$status" = "Ok" ]
  then
    log_ok
  else
    log_message "  ERROR: $(echo $1 | jq -r '.Message')"
    touch .bootstrap_error_occurred
  fi
}

function log_ok {
  log_message "  Ok"
}

function log_message {
  echo "$(date -u) $1" >> bootstrap.log
}

function log_start_deployment {
  log_message "START ▶ $deployment deployment bootstrap"
}

function log_end_deployment {
  log_message "END ▶ $deployment deployment bootstrap"
}

function set_docker_environment_value {
  setting_current_value=$(grep "$1" .env)
  setting_desired_value="$1=$2"
  if [ "$setting_current_value" == "" ]
  then
    log_message "Adding Docker environment variable: $setting_desired_value"
    echo "$setting_desired_value" >> .env
    
  else
    if [ "$setting_current_value" != "$setting_desired_value" ]
    then
      log_message "Updating Docker environment variable: $setting_desired_value"
      sed -i.bak 's/'"$setting_current_value"'/'"$setting_desired_value"'/g' .env
      rm .env.bak
    fi
  fi
}