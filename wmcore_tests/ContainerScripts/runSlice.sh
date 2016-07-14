#! /bin/bash

echo Running slice $1 of $2

# Start up services (Couch and MySQL)

source ./env_unittest.sh
$manage start-services

cd /home/dmwm/wmcore_unittest/WMCore/

# Make sure we base our tests on the latest Jenkins-tested master 

/home/dmwm/ContainerScripts/updateGit.sh

export LATEST_TAG=`git tag |grep JENKINS| sort | tail -1`
if [ -z "$3" ]; then
  export COMMIT=$LATEST_TAG
else
  export COMMIT=`git rev-parse "origin/pr/$3/merge^{commit}"`
fi

# First try to merge this PR into the same tag used for the baseline
# Finally give up and just test the tip of the branch
(git checkout $LATEST_TAG && git merge $COMMIT) ||  git checkout -f $COMMIT

# Run tests and watchdog to shut it down if needed

cd /home/dmwm/wmcore_unittest/WMCore/
rm test/python/WMCore_t/REST_t/*_t.py
/home/dmwm/cms-bot/DMWM/TestWatchdog.py &
python setup.py test --buildBotMode=true --reallyDeleteMyDatabaseAfterEveryTest=true --testCertainPath=test/python --testTotalSlices=$2 --testCurrentSlice=$1
 
# Save the results

cp nosetests.xml /home/dmwm/artifacts/nosetests-$1.xml
