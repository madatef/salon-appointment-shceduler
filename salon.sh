#!/bin/bash

PSQL="psql -U freecodecamp -d salon -t -c"

check_service_id() {
    service_id=$($PSQL "SELECT service_id FROM services WHERE service_id = $1")
    if [ -z "$service_id" ]; then
        return 1
    fi
    return 0
}

get_customer_id() {
    customer_id=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$1'")
    echo "$customer_id"
}

# Display a numbered list of services without redundant spaces
echo "Services we offer:"
services=$($PSQL "SELECT service_id, name FROM services")
index=1
echo "$services" | while IFS="|" read service_id service_name; do
    # Remove leading/trailing spaces and print the service in the correct format
    service_name=$(echo "$service_name" | xargs)
    echo "$index) $service_name"
    ((index++))
done

# Loop to ensure the user picks a valid service
while true; do
    echo "Please enter the service_id:"
    read SERVICE_ID_SELECTED

    check_service_id $SERVICE_ID_SELECTED
    if [ $? -ne 0 ]; then
        echo "Invalid service_id selected. Here are the available services again."
        # Display the services again
        index=1
        echo "$services" | while IFS="|" read service_id service_name; do
            service_name=$(echo "$service_name" | xargs)
            echo "$index) $service_name"
            ((index++))
        done
    else
        break
    fi
done

echo "Please enter your phone number:"
read CUSTOMER_PHONE

CUSTOMER_ID=$(get_customer_id "$CUSTOMER_PHONE")

if [ -z "$CUSTOMER_ID" ]; then
    echo "You are not a registered customer. Please enter your name:"
    read CUSTOMER_NAME
    $PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')"
    CUSTOMER_ID=$(get_customer_id "$CUSTOMER_PHONE")
else
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID")
fi

echo "Please enter the appointment time (e.g., 10:30):"
read SERVICE_TIME

$PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')"

SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
