data "aws_ecr_image" "latest_image" {
  repository_name = "youtube-containers"
  image_tag       = "JobCheckService"
}

data "aws_iam_role" "existing_lambda_role" {
  name = "lambda_role_for_s3_access" #Name of the iam role that gives your lambda permissions
}

resource "aws_lambda_function" "api_lambda" {
  function_name = "youtube-job-verification"
  role          = data.aws_iam_role.existing_lambda_role.arn

  package_type = "Image"
  image_uri    = "${data.aws_ecr_image.latest_image.image_uri}"

  environment {
    variables = {
      Api_Key = var.Api_Key
      EMAIL      = var.EMAIL
      EMAIL_KEY  = var.EMAIL_KEY
      EMAIL_TO   = var.EMAIL_TO
      EMAIL_HOST = var.EMAIL_HOST
    }
  }

  timeout = 30 #Adjust the timeout of the function IN SECONDS
  memory_size = 512 #Adjust the Memory of the function
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name = aws_lambda_function.api_lambda.function_name #Gives the AWS Lambda function a URL for us to trigger
  authorization_type = "NONE"
}

#Code to trigger lambda on file upload

# Add the S3 bucket notification to trigger the Lambda on file upload
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "logging-event-driven-bucket-1220-16492640"  # Existing S3 bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.api_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "youtube-app/"    # Folder prefix in the bucket
    filter_suffix       = "youtube-logs.csv"             # File name to trigger the Lambda
  }
}

# Allow the S3 bucket to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_invocation" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::logging-event-driven-bucket-1220-16492640"  # Source bucket ARN
}

# Inline policy to allow Lambda invocation
resource "aws_iam_role_policy" "lambda_invoke_inline_policy" {
  name   = "LambdaInvokeOtherServicesInlinePolicy"
  role   = data.aws_iam_role.existing_lambda_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          "arn:aws:lambda:us-east-2:339712758982:function:youtube-service-1",
          "arn:aws:lambda:us-east-2:339712758982:function:youtube-service-2",
          "arn:aws:lambda:us-east-2:339712758982:function:youtube-service-3",
          "arn:aws:lambda:us-east-2:339712758982:function:youtube-service-4",
          "arn:aws:lambda:us-east-2:339712758982:function:youtube-service-5",
          "arn:aws:lambda:us-east-2:339712758982:function:youtube-service-6"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",                # Permission to run an ECS task
          "ecs:DescribeTasks",          # Optional: Describe ECS tasks
          "iam:PassRole"                # Required to pass a task execution role
        ],
        Resource = [
          "arn:aws:ecs:us-east-2:339712758982:cluster/youtube-cluster",         # ECS cluster ARN
          "arn:aws:ecs:us-east-2:339712758982:task-definition/youtube-service-4:1", # ECS task definition ARN
          "arn:aws:iam::339712758982:role/ecs-task-execution-role"          # ECS task execution role
        ]
      }
    ]
  })
}
