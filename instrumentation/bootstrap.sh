#!/bin/bash

echo "Begin instrumentation bootstrap" >>bootstrap.log

function bootstrap_progress {
  dot_count=$((dot_count+1))
  dots=$(printf "%-${dot_count}s" ".")
  echo -ne "  Bootstrapping Graphite ${dots// /.} \r"
}

echo "Check instrumentation env var is set correctly" >>bootstrap.log
instrumentation_setting=$(grep "INSTRUMENTATION_ENABLED" .env)
instrumentation_setting_desired="INSTRUMENTATION_ENABLED=1"

if [[ $instrumentation_setting != $instrumentation_setting_desired ]]
then
     # if missing
     if [ ${#instrumentation_setting} == 0 ]
     then
          echo "Add instrumentation docker env var" >>bootstrap.log
          echo $instrumentation_setting_desired >> .env
     else
          echo "Replace instrumentation docker env var" >>bootstrap.log
          sed -i.bak 's/'"$instrumentation_setting"'/'"$instrumentation_setting_desired"'/g' ./.env
          rm .env.bak
     fi
     bootstrap_progress

     echo "Restart tyk containers to take effect" >>bootstrap.log
     docker-compose restart 2> /dev/null
     bootstrap_progress
fi

echo "End instrumentation bootstrap" >>bootstrap.log

echo -e "\033[2K          Graphite
               URL : http://localhost:8060
"