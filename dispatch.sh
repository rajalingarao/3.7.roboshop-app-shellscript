#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0" .sh)
LOGFILE="/tmp/${SCRIPT_NAME}-${TIMESTAMP}.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ "$USERID" -ne 0 ]; then
    echo -e "${R}Please run this script as root${N}"
    exit 1
else
    echo -e "${G}Root user detected${N}"
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... ${R}FAILED${N}"
        exit 1
    else
        echo -e "$2 ... ${G}SUCCESS${N}"
    fi
}
#Adds the Go workspace binary directory to your system PATH.
export GOPATH=/app/go
export PATH=$PATH:$GOPATH/bin
VALIDATE $? "Adds the Go workspace binary directory to your system PATH"

#Sets the Go build cache directory to /tmp/go-build-cache.
export GOCACHE=/tmp/go-build-cache
mkdir -p $GOCACHE
VALIDATE $? "Sets the Go build cache directory to /tmp/go-build-cache"

dnf install golang -y &>>"$LOGFILE"
VALIDATE $? "Installing GoLang"

id roboshop &>>"$LOGFILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin \
    --comment "roboshop system user" roboshop &>>"$LOGFILE"
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists ... ${Y}SKIPPING${N}"
fi

rm -rf /app &>>"$LOGFILE"
mkdir -p /app &>>"$LOGFILE"
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-builds.s3.amazonaws.com/dispatch.zip
VALIDATE $? "Downloading Dispatch code"

cd /app
unzip -o /tmp/dispatch.zip &>>"$LOGFILE"
VALIDATE $? "Extracting Dispatch code"

go mod init dispatch &>>"$LOGFILE"
go mod tidy &>>"$LOGFILE"
VALIDATE $? "Downloading Go dependencies"

go build &>>"$LOGFILE"
VALIDATE $? "Building Dispatch application"

cp /home/ec2-user/3.7.roboshop-app-shellscript/dispatch.service /etc/systemd/system/dispatch.service &>>"$LOGFILE"
VALIDATE $? "Copying systemd service file"

systemctl daemon-reload &>>"$LOGFILE"
VALIDATE $? "Reloading systemd daemon"

systemctl enable dispatch &>>"$LOGFILE"
VALIDATE $? "Enabling Dispatch service"

systemctl start dispatch &>>"$LOGFILE"
VALIDATE $? "Starting Dispatch service"

echo -e "${G}Dispatch installation completed successfully${N}"
echo "Log file: $LOGFILE"

echo "***************************************"
sudo systemctl status dispatch
echo "***************************************"
sudo ps -ef | grep dispatch
echo "***************************************"