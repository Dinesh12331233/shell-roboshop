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

echo "Please enter rabbitmq password to setup"
read -s RABBITMQ_PASSWORD

VALIDATE() {

if [ $1 -ne 0 ]
    then 
        echo -e "$2....$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2....$G SUCCESS $N" | tee -a $LOG_FILE
    fi         
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo 
VALIDATE $? "adding rabbitmq repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "installing rabbitmq server"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enabling rabbitmq server"

systemctl start rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "starting rabbitmq server" 

rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD  &>>$LOG_FILE #password=roboshop123 
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"



END_TIME=$(date +%s) 
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "script execution completed successfully. $Y time taken is: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE 

