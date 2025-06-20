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

VALIDATE() {

if [ $1 -ne 0 ]
    then 
        echo -e "$2....$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2....$G SUCCESS $N" | tee -a $LOG_FILE
    fi         
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Install python3 packages" 



id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating roboshop system user"
else 
    echo -e "system user roboshop already created....$Y skipping $N"
fi 

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading payment zip file"

rm -rf /app/*
cd /app 
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment file" 

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "installing dependencies" 

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service 
VALIDATE $? "copying payment service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reloading payment"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enabling payment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "starting payment" 

END_TIME=$(date +%s) 
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "script execution completed successfully. $Y time taken is: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE 