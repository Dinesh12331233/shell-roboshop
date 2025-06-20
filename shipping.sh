#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

#checking the user has root access or not
if [ $USERID -ne 0 ]
then
    echo -e "$R Error: you must have root access to execute the script $N " | tee -a $LOG_FILE
    exit 1
else 
    echo "you are root user.you have root access" | tee -a $LOG_FILE
fi 

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

VALIDATE() {

if [ $1 -ne 0 ]
    then 
        echo -e "$2....$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2....$G SUCCESS $N" | tee -a $LOG_FILE
    fi         
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "installing maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating roboshop system user"
else 
    echo -e "system user roboshop already created....$Y skipping $N"
fi 

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading shipping zip file"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping shipping file" 

mvn clean package &>>$LOG_FILE
VALIDATE $? "packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving and renaming jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service 

systemctl daemon-reload 
VALIDATE $? "reloading "

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enabling shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql" 

mysql -h mysql.deepthi.tech -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities'
if [ $? -ne 0 ] 
then
    mysql -h mysql.deepthi.tech -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.deepthi.tech -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.deepthi.tech -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "loading data into MYSQL"
else 
    echo -e "Data is already loaded into MYSQL... $Y skipping $N "
fi
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting shipping"

END_TIME=$(date +%s) 
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "script execution completed successfully. $Y time taken is: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE 
