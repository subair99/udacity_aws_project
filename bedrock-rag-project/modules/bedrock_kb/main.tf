# main.tf - Bedrock Knowledge Base Module (Manual Database Setup)

# IAM Role for Bedrock
resource "aws_iam_role" "bedrock_kb_role" {
  name = "${var.knowledge_base_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

# Full Access Policy Attachment
resource "aws_iam_role_policy_attachment" "bedrock_kb_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  role       = aws_iam_role.bedrock_kb_role.name
}

# RDS Data API Policy
resource "aws_iam_policy" "rds_data_api_policy" {
  name        = "${var.knowledge_base_name}-rds-data-api-policy"
  path        = "/"
  description = "IAM policy for RDS Data API access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction",
        ]
        Resource = var.aurora_arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.aurora_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_data_api_policy_attachment" {
  policy_arn = aws_iam_policy.rds_data_api_policy.arn
  role       = aws_iam_role.bedrock_kb_role.name
}

# RDS Access Policy with S3
resource "aws_iam_policy" "bedrock_kb_rds_access" {
  name        = "${var.knowledge_base_name}-rds-access"
  path        = "/"
  description = "IAM policy for Bedrock Knowledge Base to access RDS and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.aurora_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_policy_attachment" {
  policy_arn = aws_iam_policy.bedrock_kb_rds_access.arn
  role       = aws_iam_role.bedrock_kb_role.name
}

# Wait for IAM policies to propagate
resource "time_sleep" "wait_30_seconds" {
  depends_on = [
    aws_iam_role_policy_attachment.bedrock_kb_policy,
    aws_iam_role_policy_attachment.rds_data_api_policy_attachment,
    aws_iam_role_policy_attachment.rds_policy_attachment
  ]

  create_duration = "30s"
}

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "main" {
  name = var.knowledge_base_name
  role_arn = aws_iam_role.bedrock_kb_role.arn
  
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = var.embedding_model_arn
    }
    type = "VECTOR"
  }
  
  storage_configuration {
    type = "RDS"
    rds_configuration {
      credentials_secret_arn = var.aurora_secret_arn
      database_name = var.aurora_db_name
      resource_arn = var.aurora_arn
      table_name = "${var.aurora_schema_name}.${var.aurora_table_name}"
      field_mapping {
        primary_key_field = var.aurora_primary_key_field
        vector_field   = var.aurora_vector_field
        text_field     = var.aurora_text_field
        metadata_field = var.aurora_metadata_field
      }
    }
  }
  
  depends_on = [ 
    time_sleep.wait_30_seconds
  ]
}

# Bedrock Data Source for S3
resource "aws_bedrockagent_data_source" "s3_bedrock_bucket" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "s3_bedrock_bucket"
  
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.s3_bucket_arn
    }
  }
  
  depends_on = [ 
    aws_bedrockagent_knowledge_base.main 
  ]
}