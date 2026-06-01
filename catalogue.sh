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

rm -rf /app &>> $LOGFILE
VALIDATE $? "clean up existing directory"

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>>$LOGFILE
VALIDATE $? "Downloading catalogue code"

cd /app  &>>$LOGFILE
VALIDATE $? "Moving to app directory"

unzip /tmp/catalogue.zip &>>$LOGFILE
VALIDATE $? "extracting catalogue"

npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies"

cp /home/ec2-user/3.7.roboshop-app-shellscript/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGFILE
VALIDATE $? "Copied catalogue service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon Reload"

systemctl enable catalogue &>>$LOGFILE
VALIDATE $? "Enabling catalogue"

systemctl start catalogue &>>$LOGFILE
VALIDATE $? "starting catalogue"

cp /home/ec2-user/3.7.roboshop-app-shellscript/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGFILE
VALIDATE $? "Copied mongo repo"

dnf install mongodb-mongosh -y &>>$LOGFILE
VALIDATE $? "Installing mongo client"

SCHEMA_EXISTS=$(mongosh --host $MONGO_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')") &>>$LOGFILE
if [ $SCHEMA_EXISTS -lt 0 ] 
then
  echo -e "Schema does not exists... $G LOADING $N"
  mongosh --host $MONGO_HOST < /app/schema/catalogue.js &>>$LOGFILE
  VALIDATE $? "Loading Catalogue data"
else
  echo -e "Schema already loaded... $Y SKIPPING $N" 
fi

systemctl restart catalogue &>>$LOGFILE
VALIDATE $? "Restarting catalogue"

echo -e "${G}Catalogue installation completed successfully${N}"
echo "Log file: $LOGFILE"

echo "***************************************"
sudo systemctl status catalogue
echo "***************************************"
sudo ps -ef | grep catalogue
echo "***************************************"