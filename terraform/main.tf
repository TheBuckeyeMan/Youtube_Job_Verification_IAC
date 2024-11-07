data "aws_ecr_image" "latest_image" {
  repository_name = "youtube-containers"
  image_tag       = "youtube-job-verification"
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
  bucket = "landing-data-bucket-1220-16492640"  # Existing S3 bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.api_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "Youtube/fun-facts/"    # Folder prefix in the bucket
    filter_suffix       = "Fact.json"             # File name to trigger the Lambda
  }
}

# Allow the S3 bucket to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_invocation" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::landing-data-bucket-1220-16492640"  # Source bucket ARN
}