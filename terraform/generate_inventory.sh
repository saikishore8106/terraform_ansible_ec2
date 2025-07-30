#!/bin/bash

cd "$(dirname "$0")"

# Extract IPs
terraform output -json public_ips | jq -r '.[]' > ip_list.txt

# Get cleaned key path (remove leading ./ if present)
KEY_PATH=$(terraform output -raw private_key_path | sed 's|^\./||')

# Generate inventory file
echo "[ec2_instances]" > ../ansible/inventory.ini
while read ip; do
  echo "$ip ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/$KEY_PATH" >> ../ansible/inventory.ini
done < ip_list.txt

echo "Generated inventory.ini for Ansible:"
cat ../ansible/inventory.ini


