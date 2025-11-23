#!/bin/bash

source config/dev-config.sh

# Replace placeholder with actual email
sed "s/{{EMAIL_ADDRESS}}/$ALERT_EMAIL/g" notifications.json.template > notifications.json

echo "✅ Generated notifications.json with email: $ALERT_EMAIL"
