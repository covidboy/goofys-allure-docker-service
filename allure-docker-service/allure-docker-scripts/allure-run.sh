#!/bin/bash
BLUE='\033[0;34m'
GREEN='\033[0;32m'
echo -e "${BLUE}entered allure script sleeping for 10 secs"
#echo "entered allure script sleeping for 10 secs"
sleep 10
#su allure
echo -e "${GREEN}slept 10 secs"
bash -c "/app/runAllureDeprecated.sh & /app/runAllureApp.sh & /app/checkAllureResultsFiles.sh"
echo "all 3 scripts executed"