#!/bin/bash
# set -ex

# Input values for test purpose
# export UNUSED_MARKER="$"
# export UPDATE_AVAILABLE_MARKER="#"
# export MAIN_VERSION_AVAILABLE_MARKER="@"

echo "Building Stats: "
echo "- Unused Marker: ${UNUSED_MARKER}"
echo "- Update Available Marker: ${UPDATE_AVAILABLE_MARKER}"
echo "- Main Version Update Marker: ${MAIN_VERSION_AVAILABLE_MARKER}"

function markOldPods() {
    local LINES=$(echo "$STATS" | wc -l)
    local PATTERN='[0-9][^`) ]*'
    local MAIN_PATTERN='[^.]*'
    echo "$STATS" | while true; do
        read POD
        if [[ -z ${POD}  && ${LINES} -lt 1 ]]; then
            echo "$STATS"
            break;
        fi
        LINES=$LINES-1
        VERSIONS=($(echo "$POD" | grep -Eo "$PATTERN"))
        if [ -z ${VERSIONS} ]; then
            continue
        fi
        if [ -z ${VERSIONS[0]} ]; then
            continue
        fi

        # If main version gets updated
        if [ ! -z ${VERSIONS[2]} ] && [ ${VERSIONS[0]} != ${VERSIONS[2]} ]; then
            EXISTING_MAIN_VERSION=($(echo "${VERSIONS[0]}" | grep -Eo "$MAIN_PATTERN"))
            LATEST_MAIN_VERSION=($(echo "${VERSIONS[2]}" | grep -Eo "$MAIN_PATTERN"))
            if [ ${LATEST_MAIN_VERSION} != ${EXISTING_MAIN_VERSION} ]; then
                STR="${POD}"
                STR_WITH="${POD} ${MAIN_VERSION_AVAILABLE_MARKER}"
                STATS="${STATS//$STR/$STR_WITH}"
                continue
            fi
        fi
        
        if [ -z ${VERSIONS[1]} ]; then
            continue
        fi
        # If minor version gets updated
        if [ ${VERSIONS[0]} != ${VERSIONS[1]} ] || [ ${VERSIONS[0]} != ${VERSIONS[2]} ]; then
            STR="${POD}"
            STR_WITH="${POD} ${UPDATE_AVAILABLE_MARKER}"
            STATS="${STATS//$STR/$STR_WITH}"
        fi
    done
}

function generatePodsStats() {
    # local OUTPUT=$(bundle exec pod outdated)
    local OUTPUT="The following pod updates are available:
- DateToolsSwift 4.0.0 -> 4.0.0 (latest version 5.0.0)
- ECKit-Utils 1.2.2 -> 1.2.2 (latest version 3.1.0)
- ECNetworking 0.8.1 -> 0.8.1 (latest version 2.0.1)
- Firebase 8.0.0 -> (unused) (latest version 8.11.0)
- FirebaseABTesting 8.8.0 -> 8.11.0 (latest version 8.11.0)
- FirebaseAnalytics 8.0.0 -> 8.0.0 (latest version 8.11.0)
- FirebaseCore 8.0.0 -> 8.0.0 (latest version 8.11.0)
- FirebaseCoreDiagnostics 8.8.0 -> 8.11.0 (latest version 8.11.0)
- FirebaseCrashlytics 8.0.0 -> 8.0.0 (latest version 8.11.0)
- FirebaseInstallations 8.8.0 -> 8.11.0 (latest version 8.11.0)
- FirebasePerformance 8.0.0 -> 8.0.0 (latest version 8.11.0)
- FirebaseRemoteConfig 8.0.0 -> 8.0.0 (latest version 8.11.0)
- GoogleAppMeasurement 8.0.0 -> 8.0.0 (latest version 8.11.0)
- GoogleDataTransport 9.1.0 -> 9.1.2 (latest version 9.1.2)
- GoogleUtilities 7.5.2 -> (unused) (latest version 7.7.0)
- KeychainAccess 3.1.1 -> 3.1.1 (latest version 4.2.2)
- OHHTTPStubs 6.1.0 -> (unused) (latest version 9.1.0)
- PromisesObjC 1.2.12 -> 1.2.12 (latest version 2.0.0)
- Protobuf 3.18.0 -> 3.19.4 (latest version 4.0.0-rc1)
- RAnalytics 5.3.0 -> 5.3.0 (latest version 9.1.1)
- RInAppMessaging 4.0.1 -> 4.0.1 (latest version 6.0.0)
- RLogger 1.2.1 -> 1.2.1 (latest version 2.0.0)
- RPushPNP 2.1.0 -> 2.1.0 (latest version 5.1.0)
- SDWebImage 5.0.2 -> 5.0.2 (latest version 5.12.3)
- SnapshotTesting 1.8.2 -> 1.8.2 (latest version 1.9.0)
- SwiftLint 0.41.0 -> 0.46.2 (latest version 0.46.2)
- Swinject 2.8.0 -> 2.8.0 (latest version 2.8.1)
- XMLMapper 1.6.1 -> 2.0.0 (latest version 2.0.0)"
    local SEARCH_STRING="Analyzing dependencies"
    local STATS=${OUTPUT#*$SEARCH_STRING}

    local STR='(unused)'
    local STR_WITH="${UNUSED_MARKER}"
    STATS=$(echo "${STATS//$STR/$STR_WITH}")

    STR=')'
    STR_WITH='`)'
    STATS=$(echo "${STATS//$STR/$STR_WITH}")

    STR='latest version '
    STR_WITH='latest version `'
    STATS=$(echo "${STATS//$STR/$STR_WITH}")

    STR=' ('
    STR_WITH='` ('
    STATS=$(echo "${STATS//$STR/$STR_WITH}")

    STR="${UNUSED_MARKER}\` "
    STR_WITH="\` ${UNUSED_MARKER} "
    STATS=$(echo "${STATS//$STR/$STR_WITH}")

    STATS=$(echo "$STATS" | sed -e 's/\([a-zA-Z][a-zA-Z]* \)\([0-9]\)/\1`\2/g')

    STATS=$(markOldPods "$STATS")
    STATS="${UNUSED_MARKER} = Unused library used
${UPDATE_AVAILABLE_MARKER} = New version available
${MAIN_VERSION_AVAILABLE_MARKER} = New main version available (Recomend Update)

    $STATS"
    echo "$STATS"
}
STATS=$(generatePodsStats)
echo "$STATS"
envman add --key PODS_USED_STATUSa --value "${STATS}"
