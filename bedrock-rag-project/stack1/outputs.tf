# In stack1/outputs.tf (alternative version)
output "aurora" {
  description = "Aurora cluster details"
  value = {
    endpoint     = module.aurora_serverless.cluster_endpoint
    reader_endpoint = module.aurora_serverless.cluster_reader_endpoint
    arn          = module.aurora_serverless.database_arn
    secret_arn   = module.aurora_serverless.database_secretsmanager_secret_arn
    cluster_id   = module.aurora_serverless.cluster_id
  }
}

output "network" {
  description = "Network details"
  value = {
    vpc_id           = module.vpc.vpc_id
    private_subnets  = module.vpc.private_subnets
    public_subnets   = module.vpc.public_subnets
  }
}

output "s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}
