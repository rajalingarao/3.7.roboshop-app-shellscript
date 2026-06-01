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

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing Nginx Server"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabling Nginx server"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting Nginx server"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Removing existing content"

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>>$LOGFILE
VALIDATE $? "Downloading web code"

cd /usr/share/nginx/html &>>$LOGFILE
unzip /tmp/web.zip &>>$LOGFILE
VALIDATE $? "Extracting the web app"

cp /home/ec2-user/3.7.roboshop-app-shellscript/roboshop.conf /etc/nginx/default.d/roboshop.conf &>>$LOGFILE
VALIDATE $? "Copied roboshop conf"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting nginx Server"

echo -e "${G}Web/Nginx installation completed successfully${N}"
echo "Log file: $LOGFILE"
echo "***************************************"
sudo systemctl status nginx
echo "***************************************"
sudo ps -ef | grep nginx
echo "***************************************"

