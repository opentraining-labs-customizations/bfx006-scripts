#!/bin/bash

function print_result() {
    local action=$1
    local scenario=$2
    local rc=$3

    case "$action" in
        start)
            if [ $rc -eq 0 ]; then
                echo "Prepare the system for starting the lab $scenario"
                echo "This may take more than 15 minutes to finish"

                echo "Downloading $scenario scenario files"

                mkdir /home/student/deployment-temp; chown student:student /home/student/deployment-temp >/dev/null 2>&1

                cd

                git clone https://github.com/opentraining-labs-customizations/bfx006-scripts.git

                cp -r /home/student/bfx006-scripts/deployment-temp/* /home/student/deployment-temp/

                echo "Building $scenario scenario"

                echo "student" | sudo -S -u student bash -l -c "oc login -u admin -p redhatocp  https://api.ocp4.example.com:6443; oc create -f /home/student/deployment-temp/namespace.yaml >/dev/null 2>&1"

                echo "student" | sudo -S -u student bash -l -c "oc login -u admin -p redhatocp  https://api.ocp4.example.com:6443; oc create -n breakfix006 -f /home/student/deployment-temp/pvc.yaml >/dev/null 2>&1"

                echo "student" | sudo -S -u student bash -l -c "oc login -u admin -p redhatocp  https://api.ocp4.example.com:6443; oc create -n breakfix006 -f /home/student/deployment-temp/deployment2.yaml >/dev/null 2>&1"

                sleep 60

                pod_name=$(oc get pods -n breakfix006 -o custom-columns=CONTAINER:metadata.name | tail -n1)

                echo "student" | sudo -S -u student bash -l -c "oc cp -n breakfix006 /home/student/deployment-temp/breakfixfile.sh $pod_name:/var/www/html >/dev/null 2>&1"

                echo "student" | sudo -S -u student bash -l -c "oc exec -n breakfix006 -it $pod_name -- /usr/bin/timeout 720 /bin/bash /var/www/html/breakfixfile.sh >/dev/null 2>&1"

                echo "student" | sudo -S -u student bash -l -c "oc delete -n breakfix006 -f /home/student/deployment-temp/deployment2.yaml >/dev/null 2>&1"

                cp /home/student/deployment-temp/deployment.yaml /home/student/deployment.yaml >/dev/null 2>&1

                rm -rf /home/student/deployment-temp/* >/dev/null 2>&1

                echo "student" | sudo -S -u student bash -l -c "oc create -n breakfix006 -f /home/student/deployment.yaml >/dev/null 2>&1"

                touch /tmp/.breakfix006

                echo "$scenario scenario ready"
            else
                echo "Preparing scenario $scenario failed!"
            fi
            ;;
        grade)
            if [ -f "/tmp/.breakfix006" ]; then
                echo -ne "Perform lab grading for $scenario: \n"
                if ! oc get pods -n breakfix006 -o template --template='{{range .items}}{{.status.phase}}{{"\n"}}{{end}}' | grep -q -v "^Running$"; then
                    echo "Success, All pods are running!"
                    echo "Pod Status:"
                    oc get pods -n breakfix006 -o template --template='{{range .items}}{{.metadata.name}} {{.status.phase}}{{"\n"}}{{end}}'
                else
                    echo "Error, Checking Pod Status:"
                    oc get pods -n breakfix006 -o template --template='{{range .items}}{{.metadata.name}} {{.status.phase}}{{"\n"}}{{end}}'
                fi
            else
                echo "Failed to grade scenario $scenario, ensure you have run Start first."
            fi
            ;;
        finish)
            if [ -f "/tmp/.breakfix006" ]; then
                echo "Cleaning $scenario"

                oc delete -n breakfix006 -f /home/student/deployment-selinux.yaml >/dev/null 2>&1

                for i in `oc get pods -n breakfix006 | awk 'NR>2 {print $1}'`; do oc delete pod $i -n breakfix006 --grace-period=0 --force; done >/dev/null 2>&1

                oc delete pvc -n breakfix006 myclaim >/dev/null 2>&1

                oc delete project breakfix006 >/dev/null 2>&1

                echo "Scenario $scenario has been cleaned up."
            else
                echo "Failed to clean up after scenario $scenario, ensure you have run Start first."
            fi
            ;;
    esac
}


function checks() {
    local action=$1
    local scenario=$2

    if [ -z "$action" ]; then
        echo "Error: The first argument is empty or missing." >&2
        echo "Usage: $0 start|grade|finish breakfix006" >&2
        exit 1
    else
        if [ -z "$scenario" ]; then
            echo "Error: The second argument is empty or missing." >&2
            echo "Usage: $0 start|grade|finish breakfix006" >&2
            exit 1
        fi
    fi
}


function main() {
    local rc=1
    local action=$1
    local scenario=$2

    checks $action $scenario

    echo "Running $action action against scenario $scenario"
    rc=$?

    print_result $action $scenario $rc

    exit $rc
}

main $@
