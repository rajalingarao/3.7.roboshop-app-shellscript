#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]
then
   echo -e "$R Please run this script with root access $N"
   exit 1
else
   echo -e " $G You are super user. $N"
fi

VALIDATE(){
if [ $1 -ne 0 ]
then
   echo -e "$2... $R FAILURE $N"
   exit 1
else
   echo -e "$2... $G SUCCESS $N"
fi
}

dnf install python3.11 gcc python3-devel -y &>>$LOGFILE
VALIDATE $? "Installing Python"

id roboshop &>>$LOGFILE
if [ $? -ne 0 ]
then 
    useradd roboshop &>>$LOGFILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "Roboshop user already created..$Y Skipping $N"
fi

rm -rf /app &>>$LOGFILE
VALIDATE $? "Clean up existing directory"

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>>$LOGFILE
VALIDATE $? "Downloading Shipping application"

cd /app
VALIDATE $? "Moving to app directory"

unzip /tmp/payment.zip &>>$LOGFILE
VALIDATE $? "extracting payment"

pip3.11 install -r requirements.txt &>>$LOGFILE
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/3.7.roboshop-app-shellscript/payment.service /etc/systemd/system/payment.service &>>$LOGFILE
VALIDATE $? "Copied payment service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon Reload"

systemctl enable payment &>>$LOGFILE
VALIDATE $? "Enable payment"

systemctl start payment &>>$LOGFILE
VALIDATE $? "start payment"

echo -e "${G}Payment installation completed successfully${N}"
echo "Log file: $LOGFILE"

echo "***************************************"
sudo systemctl status payment
echo "***************************************"
sudo ps -ef | grep payment
echo "***************************************"