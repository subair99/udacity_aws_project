provider "aws" {
  region = "us-west-2"  
}

module "bedrock_kb" {
  source = "../modules/bedrock_kb" 

  knowledge_base_name = "my-bedrock-kb"
  
  # Aurora configuration
  aurora_arn        = "arn:aws:rds:us-west-2:741714103560:cluster:my-aurora-serverless" #UPDATE
  aurora_db_name    = "myapp"
  aurora_endpoint   = "my-aurora-serverless.cluster-czmo0as2m2ip.us-west-2.rds.amazonaws.com" #UPDATE
  
  # Table configuration
  aurora_schema_name = "bedrock_integration"
  aurora_table_name = "bedrock_kb"
  aurora_primary_key_field = "id"
  aurora_metadata_field = "metadata"
  aurora_text_field = "chunks"
  aurora_vector_field = "embedding"
  
  # ADD THIS INSTEAD:
  database_user = "dbadmin"
  
  aurora_secret_arn = "arn:aws:secretsmanager:us-west-2:741714103560:secret:my-aurora-serverless-pF9Zxk" #UPDATE
  s3_bucket_arn = "arn:aws:s3:::bedrock-kb-741714103560" #UPDATE
  embedding_model_arn = "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v2:0"
}