#!/bin/bash

print_usage_and_exit() {
  echo "Usage: $0 <command>"
  echo ""
  echo "Available commands:"
  echo ""
  echo "  builder create <arch> <vcpu>    Creates a new amd/arm builder instance with 4, 8, 16 or 32 vCPUs"
  echo "  builder connect                 Establishes an SSH connection to the builder instance"
  echo "  builder terminate               Terminates the builder instance"
  echo "  builder status                  Checks if there is an existing builder instance"
  echo ""
  exit 1
}

if [ $# -lt 1 ]; then
  print_usage_and_exit
fi

export AWS_REGION="us-east-2"

instance_name="builder"
ssh_key_path="$HOME/.ssh/jonatanklosko-aws-default.pem"

case "$1" in
  "create")
    if [ $# -ne 3 ]; then
      print_usage_and_exit
    fi


    case "$2" in
        "amd") instance_group="c6a"; image_id="ami-0430580de6244e02e" ;;
        "arm") instance_group="c6g"; image_id="ami-0071e4b30f26879e2" ;;
        *) print_usage_and_exit ;;
    esac

    case "$3" in
        "4") instance_type="$instance_group.xlarge" ;;
        "8") instance_type="$instance_group.2xlarge" ;;
        "16") instance_type="$instance_group.4xlarge" ;;
        "32") instance_type="$instance_group.8xlarge" ;;
        *) print_usage_and_exit ;;
    esac

    aws ec2 run-instances \
      --image-id $image_id  \
      --instance-type $instance_type \
      --count 1 \
      --security-group-ids sg-05c6b4c3b47d41b51 \
      --key-name default \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
      --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":50,"DeleteOnTermination":true}}]' \
      --user-data $'#!/bin/bash \n\
        sudo apt update \n\
        sudo apt install -y git \n\
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common \n\
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \n\
        sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \n\
        sudo apt install -y docker-ce \n\
        sudo usermod -a -G docker ubuntu'
  ;;

  "connect")
    public_ip="$(
      aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text
    )"
    ssh -i $ssh_key_path -o StrictHostKeychecking=no ubuntu@$public_ip
  ;;

  "terminate")
    instance_id="$(
      aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text
    )"
    aws ec2 terminate-instances --instance-ids $instance_id
  ;;

  "status")
    instance_id="$(
      aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text
    )"
    if [ -z "$instance_id" ]; then
      echo "No builder instance found"
    else
      echo "Builder instance with $instance_id running"
    fi
  ;;

  *)
    print_usage_and_exit
  ;;
esac
