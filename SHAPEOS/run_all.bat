@echo off
cd /d D:\IOT_APP\iot-project-main\ai_engine

start cmd /k "python ml_recommendation.py"
start cmd /k "python csv_ai_streamer.py"

exit
