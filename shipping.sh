#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

MYSQL_HOST=mysql.lithesh.shop

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

dnf install maven -y &>>$LOGFILE
VALIDATE $? "Installing Maven"

id roboshop &>>$LOGFILE
if [ $? -ne 0 ]
then 
    useradd roboshop &>>$LOGFILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "Roboshop user already created..$Y Skipping $N"
fi

rm -rf /app &>>$LOGFILE
VALIDATE $? "Clean up existing directory"

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>>$LOGFILE
VALIDATE $? "Downloading shipping application"

cd /app
VALIDATE $? "Moving to app directory"

unzip /tmp/shipping.zip &>>$LOGFILE
VALIDATE $? "Extracked Shipping code"

mvn clean package &>>$LOGFILE
VALIDATE $? "Packaging shipping"

mv target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE $? "Renaming the artifact"

cp /home/ec2-user/3.7.roboshop-app-shellscript/shipping.service /etc/systemd/system/shipping.service &>>$LOGFILE
VALIDATE $? "Copied Service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon Reload"

systemctl enable shipping &>>$LOGFILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>>$LOGFILE
VALIDATE $? "starting shipping"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing Mysql Client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOGFILE
if [ $? -ne 0 ];
then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGFILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOGFILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGFILE
    VALIDATE $? "Loaded data into mysql database..."
else
  echo -e "Schema already loaded... $Y SKIPPING $N" 
fi

systemctl restart shipping &>>$LOGFILE
VALIDATE $? "Restarting shipping"


echo -e "${G}Shipping installation completed successfully${N}"
echo "Log file: $LOGFILE"

echo "***************************************"
sudo systemctl status shipping
echo "***************************************"
sudo ps -ef | grep shipping
echo "***************************************"