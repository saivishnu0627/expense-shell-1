#!/bin/bash

source ./common.sh

check_root
echo "Please enter DB password:"
read -s mysql_root_password

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabiling the nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabiling nodejs:20 version"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing the nodejs"

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "creating the expense user"
else
    echo -e "Expense user already created.. $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "creating the app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading backend code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Extracted backend code"

npm install &>>$LOGFILE
VALIDATE $? "Installing the node.js dependeiencs"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "copied backend service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon remload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "enabling backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "installing MYSQL Client"

mysql -h 172.31.27.211 -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Schema loading"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting Backend"


