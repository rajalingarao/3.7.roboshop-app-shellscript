#!/bin/bash

# ---------------------------------------
# Dispatch Service Installation Script
# ---------------------------------------

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename "$0" .sh)
LOGFILE="/tmp/${SCRIPT_NAME}-${TIMESTAMP}.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# ---------------------------------------
# Root Check
# ---------------------------------------
if [ "$USERID" -ne 0 ]; then
    echo -e "${R}Please run this script as root${N}"
    exit 1
else
    echo -e "${G}Root user detected${N}"
fi

# ---------------------------------------
# Validate Function
# ---------------------------------------
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... ${R}FAILED${N}"
        exit 1
    else
        echo -e "$2 ... ${G}SUCCESS${N}"
    fi
}

# ---------------------------------------
# Install GoLang
# ---------------------------------------
dnf install golang -y &>>"$LOGFILE"
VALIDATE $? "Installing GoLang"

# ---------------------------------------
# Create roboshop user (system user)
# ---------------------------------------
id roboshop &>>"$LOGFILE"

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin \
    --comment "roboshop system user" roboshop &>>"$LOGFILE"
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists ... ${Y}SKIPPING${N}"
fi

# ---------------------------------------
# Prepare application directory
# ---------------------------------------
rm -rf /app &>>"$LOGFILE"
mkdir -p /app &>>"$LOGFILE"
VALIDATE $? "Creating /app directory"

# ---------------------------------------
# Download Dispatch code
# ---------------------------------------
curl -L -o /tmp/dispatch.zip \
https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>"$LOGFILE"

VALIDATE $? "Downloading Dispatch code"

# ---------------------------------------
# Extract application
# ---------------------------------------
cd /app || exit 1
unzip -o /tmp/dispatch.zip &>>"$LOGFILE"
VALIDATE $? "Extracting Dispatch code"

# ---------------------------------------
# Build Go application
# ---------------------------------------
cd /app || exit 1

go mod init dispatch &>>"$LOGFILE"
go mod tidy &>>"$LOGFILE"
VALIDATE $? "Downloading Go dependencies"

go build &>>"$LOGFILE"
VALIDATE $? "Building Dispatch application"

# ---------------------------------------
# Setup systemd service
# ---------------------------------------
cp /home/ec2-user/3.7.roboshop-app-shellscript/dispatch.service \
/etc/systemd/system/dispatch.service &>>"$LOGFILE"

VALIDATE $? "Copying systemd service file"

# ---------------------------------------
# Reload and start service
# ---------------------------------------
systemctl daemon-reload &>>"$LOGFILE"
VALIDATE $? "Reloading systemd daemon"

systemctl enable dispatch &>>"$LOGFILE"
VALIDATE $? "Enabling Dispatch service"

systemctl start dispatch &>>"$LOGFILE"
VALIDATE $? "Starting Dispatch service"

echo -e "${G}Dispatch installation completed successfully${N}"
echo "Log file: $LOGFILE"

























# #!/bin/bash

# USERID=$(id -u)
# TIMESTAMP=$(date +%F-%H-%M-%S)
# SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
# LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

# R="\e[31m"
# G="\e[32m"
# Y="\e[33m"
# N="\e[0m"

# if [ $USERID -ne 0 ]
# then
#    echo -e "$R Please run this script with root access $N"
#    exit 1
# else
#    echo -e " $G You are super user. $N"
# fi

# VALIDATE(){
# if [ $1 -ne 0 ]
# then
#    echo -e "$2... $R FAILURE $N"
#    exit 1
# else
#    echo -e "$2... $G SUCCESS $N"
# fi
# }

# dnf install golang -y &>>$LOGFILE
# VALIDATE $? "Installing Go Language"

# id roboshop &>>$LOGFILE
# if [ $? -ne 0 ]
# then 
#     useradd roboshop &>>$LOGFILE
#     VALIDATE $? "Creating roboshop user"
# else
#     echo -e "Roboshop user already created..$Y Skipping $N"
# fi

# rm -rf /app &>>$LOGFILE
# VALIDATE $? "Clean up existing directory"

# mkdir -p /app &>>$LOGFILE
# VALIDATE $? "Creating app directory"

# curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOGFILE
# VALIDATE $? "Downloading Dispatch application"

# cd /app &>>$LOGFILE
# VALIDATE $? "Moving to app directory"

# unzip /tmp/dispatch.zip &>>$LOGFILE
# VALIDATE $? "extracting Dispatch"

# cd /app &>>$LOGFILE
# VALIDATE $? "Moving to app directory"

# go mod init dispatch &>>$LOGFILE
# VALIDATE $? "Initiating dispatch"

# # export GOPATH=/root/go
# # mkdir -p $GOPATH

# go get &>>$LOGFILE
# VALIDATE $? "get Dispatch dependencies"

# #Fix 1: Use go mod tidy instead of go get
# # go mod tidy &>>$LOGFILE
# # VALIDATE $? "Downloading dependencies"

# go build &>>$LOGFILE
# VALIDATE $? "build Dispatch"

# cp /home/ec2-user/3.7.roboshop-app-shellscript/dispatch.service /etc/systemd/system/dispatch.service &>>$LOGFILE
# VALIDATE $? "Copied payment service"

# systemctl daemon-reload &>>$LOGFILE
# VALIDATE $? "Daemon Reload"

# systemctl enable dispatch &>>$LOGFILE
# VALIDATE $? "Enable dispatch"

# systemctl start dispatch &>>$LOGFILE
# VALIDATE $? "start dispatch"
