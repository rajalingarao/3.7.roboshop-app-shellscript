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

dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installing of MySQL Server"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enabling of MySQL Server"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "Starting the MySQL server"

mysql -h mysql.lithesh.shop -uroot -pRoboShop@1 -e 'show databases;' &>>$LOGFILE
if [ $? -ne 0 ] 
then
   mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOGFILE
   VALIDATE $? "MySQL Root password setup done"
else
   echo -e "MySQL Root password is already setup...$Y SKIPPING $N"
fi