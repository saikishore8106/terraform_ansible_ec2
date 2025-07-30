
#!/bin/bash

cd "$(dirname "$0")"

# extract IPs
terraform output -json public_ips | jq -r '.[]' > ip_list.txt
KEY_PATH=$(terraform output -raw private_key_path)

echo "[ec2_instances]" > ../ansible/inventory.ini
while read ip; do
  echo "$ip ansible_user=ec2-user ansible_ssh_private_key_file=$KEY_PATH" >> ../ansible/inventory.ini
done < ip_list.txt

echo "Generated inventory.ini for Ansible:"
cat ../ansible/inventory.ini
