#!/bin/bash

INSTANCE_IP=$(terraform output -raw fashion_assistant_public_ip)
KEY_PATH="${HOME}/.ssh/fashion-assistant"

case "$1" in
    "logs")
        ssh -i "$KEY_PATH" ubuntu@"$INSTANCE_IP" "pm2 logs fashion-assistant-backend"
        ;;
    "status")
        ssh -i "$KEY_PATH" ubuntu@"$INSTANCE_IP" "pm2 status"
        ;;
    "monit")
        ssh -i "$KEY_PATH" ubuntu@"$INSTANCE_IP" "pm2 monit"
        ;;
    "test")
        curl http://"$INSTANCE_IP":3000
        ;;
    *)
        echo "Usage: ./monitor.sh [logs|status|monit|test]"
        ;;
esac 