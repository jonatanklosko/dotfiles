#!/bin/bash

print_usage_and_exit() {
  echo "Usage: $0 <command>"
  echo ""
  echo "Available commands:"
  echo ""
  echo "  builder create <name> <arch> <vcpu>    Creates a new amd/arm builder instance with 4, 8, 16 or 32 vCPUs"
  echo "  builder connect <name>                 Establishes an SSH connection to the builder instance"
  echo "  builder terminate <name>               Terminates the builder instance"
  echo "  builder list                           Lists all running builder instances"
  echo ""
  exit 1
}

if [ $# -lt 1 ]; then
  print_usage_and_exit
fi

export AWS_REGION="us-east-2"

instance_name_prefix="builder-"
ssh_key_path="$HOME/.ssh/jonatanklosko-aws-default.pem"

case "$1" in
  "create")
    if [ $# -ne 4 ]; then
      print_usage_and_exit
    fi

    name="$2"; arch="$3"; vcpu="$4"

    case "$arch" in
        "amd") instance_group="c7a"; image_id="ami-0430580de6244e02e" ;;
        "arm") instance_group="c7g"; image_id="ami-0071e4b30f26879e2" ;;
        *) print_usage_and_exit ;;
    esac

    case "$vcpu" in
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
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name_prefix$name},{Key=arch,Value=$arch},{Key=vcpu,Value=$vcpu}]" \
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
    if [ $# -ne 2 ]; then
      print_usage_and_exit
    fi

    name="$2"

    public_ip="$(
      aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name_prefix$name" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text
    )"

    if [ -z "$public_ip" ]; then
      echo "Instance with name '$name' not found"
    else
      ssh -i $ssh_key_path -o StrictHostKeychecking=no ubuntu@$public_ip
    fi
  ;;

  "terminate")
    if [ $# -ne 2 ]; then
      print_usage_and_exit
    fi

    name="$2"

    instance_id="$(
      aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name_prefix$name" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text
    )"

    if [ -z "$instance_id" ]; then
      echo "Instance with name '$name' not found"
    else
      aws ec2 terminate-instances --instance-ids $instance_id
    fi
  ;;

  "list")
    instances="$(
      aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$instance_name_prefix*" "Name=instance-state-name,Values=running" \
        --output json
    )"

    num_instances="$(echo $instances | jq 'length')"

    if [ "$num_instances" = "0" ]; then
      echo "No builder instance found"
    else
      echo "$num_instances builder instance running:"
      echo $instances | jq '.Reservations[].Instances[] | {id: .InstanceId, ip: .PublicIpAddress, tags: (.Tags | from_entries)}'
    fi
  ;;

  *)
    print_usage_and_exit
  ;;
esac
