# Assignment 1 — EC2 with Terraform

## Objective

Write Terraform to launch an EC2 instance running Apache in AWS, verified by a GitHub Actions workflow that provisions, tests, and tears down the infrastructure automatically.

Your instance should:

- use the Ubuntu 24.04 LTS AMI (`ami-025d99823a4caad37`) in `us-east-1`
- be a `t3.micro` instance type
- have a security group that allows inbound HTTP traffic on port 80
- use the provided `init-mp.yaml` as user data to install and start Apache
- output the public IP address so the workflow can test it

## Repository Structure

```
cc-ec2-tf/
├── .github/workflows/terraform.yml   # provided — do not modify
├── init-mp.yaml                       # provided — cloud-init config from week 2
├── main.tf                            # you create this
├── variables.tf                       # you create this
├── outputs.tf                         # you create this
└── .gitignore
```

## Prerequisites

Before pushing code, you need to create a remote state bucket, set up an IAM user, and configure GitHub secrets.

<details>
<summary><strong>1. Create the remote state bucket</strong></summary>

The GitHub Actions runner is a fresh VM every run — local state doesn't survive between runs. An S3 backend keeps Terraform state in a bucket so it's always available.

Create the bucket (do this once, manually):

```bash
aws s3api create-bucket \
  --bucket itcc-tfstate-<your-pitt-username> \
  --region us-east-1
```

Enable versioning so you can recover a previous state file if something goes wrong:

```bash
aws s3api put-bucket-versioning \
  --bucket itcc-tfstate-<your-pitt-username> \
  --versioning-configuration Status=Enabled
```

The bucket name must be globally unique. Replace `<your-pitt-username>` with your Pitt username.

</details>

<details>
<summary><strong>2. Create an IAM user and attach permissions</strong></summary>

> We haven't covered the IAM role/user/permissions structure yet — that's coming in week 7. For now, we're just creating a system user that GitHub Actions can use to spin up a VM with a security group. Follow the commands below and it will make more sense later.

Create a user named `github-actions-assignment-1` with **programmatic access only** (no console access):

```bash
aws iam create-user --user-name github-actions-assignment-1
```

The workflow needs to manage EC2 instances, security groups, read VPC/subnet info, and access the S3 remote state bucket. Create and attach an inline policy:

```bash
aws iam put-user-policy \
  --user-name github-actions-assignment-1 \
  --policy-name ec2-terraform-policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeImages",
          "ec2:CreateTags",
          "ec2:DescribeTags",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:DescribeVolumes",
          "ec2:ModifyInstanceAttribute"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::itcc-tfstate-<your-pitt-username>",
          "arn:aws:s3:::itcc-tfstate-<your-pitt-username>/*"
        ]
      }
    ]
  }'
```

</details>

<details>
<summary><strong>3. Create access keys and add to GitHub</strong></summary>

Generate credentials for the IAM user:

```bash
aws iam create-access-key --user-name github-actions-assignment-1
```

Copy the `AccessKeyId` and `SecretAccessKey` from the output, then add them as repository secrets:

1. go to your Github Repo --> **Settings** --> **Secrets and variables** --> **Actions**
2. add `AWS_ACCESS_KEY_ID` with the access key ID
3. add `AWS_SECRET_ACCESS_KEY` with the secret access key

</details>

## What You Need to Write

Refer to the [Terraform Intro](https://github.com/dansc0de/cloud-computing-fall-2026/blob/main/week-03/terraform-intro.md) doc in the starter repo. Your Terraform needs:

- a provider block for AWS in `us-east-1`
- a security group allowing HTTP inbound (port 80) and all outbound
- an EC2 instance using the AMI, security group, and `init-mp.yaml` as user data
- an output named `public_ip` that exposes the instance's public IP

## Grading

The GitHub Actions workflow will:

1. `terraform init`
2. `terraform apply -auto-approve`
3. wait for the instance to be ready
4. `curl http://<public_ip>` and check for the expected response
5. `terraform destroy -auto-approve`

If the workflow passes, you get full marks. Push to `main` to trigger it.

## Local Testing

Before pushing, test your Terraform locally to catch issues early:

```bash
# set your credentials
export AWS_ACCESS_KEY_ID="your-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"

# run terraform
terraform init
terraform plan
terraform apply

# test the web server
curl http://$(terraform output -raw public_ip)

# clean up when you're done
terraform destroy
```

If `curl` returns `H2P`, your Terraform is working. Commit and push to `main` to run the grading workflow.

## Helpful Links

See [docs/helpful-links.md](docs/helpful-links.md) for Terraform, AWS, and course reference links.
