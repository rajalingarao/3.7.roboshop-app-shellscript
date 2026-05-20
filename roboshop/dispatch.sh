#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi


dnf install golang -y &>> $LOGFILE
VALIDATE $? "Installing Golang"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "roboshop user already exist...$Y SKIPPING $N"
fi

rm -rf /app &>> $LOGFILE
VALIDATE $? "clean up existing directory"

mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-builds.s3.amazonaws.com/dispatch.zip &>> $LOGFILE
VALIDATE $? "Downloading dispatch application"

cd /app  &>> $LOGFILE
VALIDATE $? "Moving to app directory"

unzip /tmp/dispatch.zip &>> $LOGFILE
VALIDATE $? "Extracting dispatch application"

go mod init dispatch &>> $LOGFILE
VALIDATE $? "Initiating dispatch application"

go get &>> $LOGFILE
VALIDATE $? "getting dispatch application"

go build &>> $LOGFILE
VALIDATE $? "Buidling dispatch application"

cp /root/3.7.shell-script-roboshop-app/dispatch.service /etc/systemd/system/dispatch.service &>> $LOGFILE
VALIDATE $? "Copying dispatch service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "dispatch - daemon reload"

systemctl enable dispatch   &>> $LOGFILE
VALIDATE $? "Enabling dispatch"

systemctl start dispatch  &>> $LOGFILE
VALIDATE $? "Starting dispatch"

systemctl status dispatch &>> $LOGFILE
VALIDATE $? "dispatch Status"