#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

MONGO_HOST=mongodb.lithesh.shop

if [ $USERID -ne 0 ]
then
   echo -e "$R Please run this script with root access $N"
   exit 1
else
   echo -e " $G You are super cart. $N"
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

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling of default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling of nodejs:20 version"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs"

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

curl -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip &>>$LOGFILE
VALIDATE $? "Downloading cart code"

cd /app
VALIDATE $? "Moving to app directory"

unzip /tmp/cart.zip &>>$LOGFILE
VALIDATE $? "extracting cart"

npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies"

cp /home/ec2-user/3.7.roboshop-app-shellscript/cart.service /etc/systemd/system/cart.service &>>$LOGFILE
VALIDATE $? "Copied cart service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon Reload"

systemctl enable cart &>>$LOGFILE
VALIDATE $? "Enabling cart"

systemctl start cart &>>$LOGFILE
VALIDATE $? "starting cart"

echo -e "${G}Cart installation completed successfully${N}"
echo "Log file: $LOGFILE"

echo "***************************************"
sudo systemctl status cart
echo "***************************************"
sudo ps -ef | grep cart
echo "***************************************"