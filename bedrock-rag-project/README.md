# AWS Bedrock Knowledge Base with Aurora Serverless

This project sets up an AWS Bedrock Knowledge Base integrated with an Aurora Serverless PostgreSQL database. It also includes scripts for database setup and file upload to S3.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Deployment Steps](#deployment-steps)
5. [Using the Scripts](#using-the-scripts)
6. [Customization](#customization)
7. [Troubleshooting](#troubleshooting)

## Project Overview

This project consists of several components:

1. Stack 1 - Terraform configuration for creating:
   - A VPC
   - An Aurora Serverless PostgreSQL cluster
   - s3 Bucket to hold documents
   - Necessary IAM roles and policies

2. Stack 2 - Terraform configuration for creating:
   - A Bedrock Knowledge Base
   - Necessary IAM roles and policies

3. A set of SQL queries to prepare the Postgres database for vector storage

4. A Python script for uploading files to an s3 bucket

The goal is to create a Bedrock Knowledge Base that can leverage data stored in an Aurora Serverless database, with the ability to easily upload supporting documents to S3. This will allow us to ask the LLM for information from the documentation.


## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured with appropriate credentials
- Terraform installed (version 0.12 or later)
- Python 3.10 or later
- pip (Python package manager)


## Project Structure

```
project-root/
│
├── stack1
|   ├── main.tf
|   ├── outputs.tf
|   └── variables.tf
|
├── stack2
|   ├── main.tf
|   ├── outputs.tf
|   └── variables.tf
|
├── modules/
│   ├── aurora_serverless/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
|   |
│   └── bedrock_kb/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── scripts/
│   ├── aurora_sql.sql
│   └── upload_to_s3.py
│
├── spec-sheets/
│   └── machine_files.pdf
│
├── __init__.py
│
├── .gitignore
│
├── app.py
│
├── bedrock_utils.py
│
├── README.md
│
└── requirements.txt
```


## Deployment Steps

For several weeks I was unable to recreate this project until I realised that the AWS platform has upgraded most of its services leading to several errors during building. These are the steps I took to ensure the project was completed using the original codes provided.

1. Create a Github repository udacity_aws_project, only add the .gitignore and LICENCE, then create codespaces
<br>

2. Install the AWS CLI v2
   ```
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```
  <br>

3. To check the version run
   ```
   aws --version
   ```
<br>

4. Remove the awscliv2.zip download
   ```
   rm awscliv2.zip
   ```
<br>

5. Install Teraform
   ```
   wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```
<br>

6. Install venv if it's not already installed, on Ubuntu/Debian
   ```
   sudo apt-get install python3-venv
   ```
<br>

7. Create a new directory for the project and navigate to it
   ```
   mkdir bedrock-rag-project
   cd bedrock-rag-project
   ```
<br>

8. Create and activate a virtual environment
   ```
   python -m venv venv
   source venv/bin/activate
   ```
<br>

9. Clone this repository to the local machine
   ```
   git clone https://github.com/udacity/cd13926-Building-Generative-AI-Applications-with-Amazon-Bedrock-and-Python-project-solution.git
   ```
<br>

10. Move all the files to bedrock-rag-project using the move_files.py file and delete the cd13926... folder
   ```
   python move_files.py
   ```
<br>

11. Configure AWS CLI with your credentials, last two stay the same
   ```
   aws configure
   ```
<br>

12. The required input are shown below
   ```
   AWS Access Key ID: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # UPDATE
   AWS Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # UPDATE
   Default Region Name: us-west-2
   Default Output Format: json
   ```
<br>

13. Get the session token
   ```
   eval $(aws sts get-session-token \
      --serial-number arn:aws:iam::xxxxxxxxxxxx:mfa/virtual-token \  # UPDATE
      --token-code xxxxxx \  # UPDATE
      --duration-seconds 28800 \
      --region us-west-2 \
      --output json | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)"')
   ```
<br>

14. Check Authentication
   ```
   aws sts get-caller-identity
   ```
<br>

15. Navigate to the project Stack 1. This stack includes VPC, Aurora servlerless and S3
   ```
   cd stack1
   ```
<br>

16. Initialize Terraform
   ```
   terraform init
   ```
<br>

17. Deploy Terraform
   ```
   terraform apply -auto-approve 
   ```
- -auto-approve to avaid typing yes all the time
<br>

18. Error1 - Deprecated attribute S3
<p align="center">
  <img src="./errors/Error1-Deprecated_attribute_S3.jpg">
</p>

- Change version = "3.0" on line 51 of stack1/main.tf to version = "5.0" and save
<br>

19. If error is encountered update and use
   ```
   rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup && terraform init 
   ```
<br>

20. The deploy the infrastructure
   ```
   terraform apply -auto-approve
   ```
<br>

21. Error2 - Deprecated attribute vpc
<p align="center">
  <img src="./errors/Error2-Deprecated_attribute_vpc.jpg">
</p>

- Change version = "5.0" on line 7 of stack1/main.tf to version = "6.0" and save
<br>

22. Error3 - data.aws_region.current[0].name
<p align="center">
  <img src="./errors/Error3-Creating_RDS_Cluster.jpg">
</p>

- Change default = "15.4" on line 9 of modules/database/variables.tf to default = "15.12", save and redeploy the infrastructure
<br>

23. After the Terraform deployment is complete, note the outputs, particularly the Aurora cluster endpoint. Below is the structure
   ```
   aurora_endpoint = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   db_endpoint = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   db_reader_endpoint = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   private_subnet_ids = [
   "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   ]
   public_subnet_ids = [
   "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   ]
   rds_secret_arn = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   s3_bucket_name = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   vpc_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   ```
<br>

24. Edit stack1/outputs.tf and database/outputs.tf to get the new output structure shown below
   ```
   aurora = {
   "arn" = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   "cluster_id" = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   "endpoint" = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   "reader_endpoint" = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   "secret_arn" = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   }
   network = {
   "private_subnets" = [
      "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   ]
   "public_subnets" = [
      "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
   ]
   "vpc_id" = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   }
   s3_bucket_arn = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   ```
<br>

25. Navigate to the scripts directory
   ```
   - Prepare the Aurora Postgres database. This is done by running the sql queries in the script/ folder. 
   - This can be done through Amazon RDS console and the Query Editor.
   ```
<br>

26. Error4 - Creating Bedrock Agent Knowledge Base
<p align="center">
  <img src="./errors/Error4-Creating_Bedrock_Agent_Knowledge_Base.jpg">
</p>

- Edit scripts/aurora_sql.sql
- Edit stack2/main.tf
- Edit modules/bedrock_kb/main.tf
- Edit modules/bedrock_kb/variables.tf
<br>

27. Run the sql query below to check of the creation was successful 
   ```
   SELECT table_schema, table_name FROM information_schema.tables WHERE table_name = 'bedrock_kb';
   ```
<br>

28. Navigate to the Stack2 directory, this stack includes Bedrock Knowledgebase 
   ```
   cd ../stack2
   ```
<br>

29. Initialize Terraform 
   ```
   terraform init
   ```
<br>

30. If corrections are made use destroy everything 
   ```
   terraform destroy -auto-approve
   ```
<br>

31. The clean the state 
   ```
   rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup && terraform init
   ```
<br>

32. Deploy the infrastructure 
   ```
   terraform apply -auto-approve
   ```
<br>

33. The structure of the output should be as shown below 
   ```
   bedrock_knowledge_base_arn = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   bedrock_knowledge_base_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   ```
<br>

34. Change directory to bedrock-rag-project 
   ```
   cd ../
   ```
<br>

35. Install the requirements file 
   ```
   pip install --upgrade pip
   pip install -r requirements.txt
   ```
<br>

36. Upload pdf files to S3, place your files in the spec-sheets folder, make sure to update the S3 bucket name in the script before running.
   ```
   python scripts/upload_to_s3.py
   ```
<br>

37. Complete chat app using the code below, kb_id is the Knowledge Base ID
   ```
   chat_with_kb.py kb_id
   ```