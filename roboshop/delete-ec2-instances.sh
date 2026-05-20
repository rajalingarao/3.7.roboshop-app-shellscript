#!/bin/bash

# List of instance names (tags)
instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "web" "dispatch")
domain_name="lithesh.shop"
hosted_zone_id="Z01686671NYDIP6ZJB3D7"


# Terminate EC2 instances
echo "Terminating EC2 instances..."
for name in "${instances[@]}"; do
    echo "Searching for EC2 instances with tag Name=$name..."

    instance_ids=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$name" "Name=instance-state-name,Values=running,pending,stopped" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)

    if [ -n "$instance_ids" ]; then
        echo "Terminating instance(s) for $name: $instance_ids"
        aws ec2 terminate-instances --instance-ids $instance_ids
    else
        echo "No EC2 instances found for $name"
    fi
done

# Wait for termination
echo "Waiting for instances to terminate..."
aws ec2 wait instance-terminated --filters Name=tag:Name,Values="${instances[@]}"

# Delete Route53 records
echo "Deleting Route53 records..."
for name in "${instances[@]}"; do
    fqdn="$name.$domain_name."

    ip=$(aws route53 list-resource-record-sets \
        --hosted-zone-id $hosted_zone_id \
        --query "ResourceRecordSets[?Name == '$fqdn' && Type == 'A'].ResourceRecords[0].Value" \
        --output text)

    if [ -n "$ip" ]; then
        echo "Deleting DNS record for $fqdn -> $ip"
        aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch "
        {
          \"Comment\": \"Deleting record for $fqdn\",
          \"Changes\": [{
            \"Action\": \"DELETE\",
            \"ResourceRecordSet\": {
              \"Name\": \"$fqdn\",
              \"Type\": \"A\",
              \"TTL\": 1,
              \"ResourceRecords\": [{ \"Value\": \"$ip\" }]
            }
          }]
        }"
    else
        echo "No DNS record found for $fqdn"
    fi
done

echo "Cleanup complete."
