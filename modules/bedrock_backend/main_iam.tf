# IAMロールの定義
resource "aws_iam_role" "slack_bolt_app_bedrock_backend_role" {
  name               = "${var.app_name}-bedrock-backend-role"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.lambda_bedrock_assume_role.json
}

# Lambda用のAssume Role Policyを定義するデータブロック
data "aws_iam_policy_document" "lambda_bedrock_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# カスタムポリシードキュメントの定義
data "aws_iam_policy_document" "lambda_bedrock_backend" {
  statement {
    sid    = "sqs"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage"
    ]
    resources = [
      var.queue_arn
    ]
  }

  statement {
    sid    = "bedrock"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid       = "loggroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid    = "logevents"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.app_name}-bedrock-backend:*"
    ]
  }
}

# IAMポリシーリソース
resource "aws_iam_policy" "lambda_bedrock_backend" {
  name   = "${var.app_name}-lambda-bedrock-backend-policy"
  policy = data.aws_iam_policy_document.lambda_bedrock_backend.json
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock_backend" {
  role       = aws_iam_role.slack_bolt_app_bedrock_backend_role.name
  policy_arn = aws_iam_policy.lambda_bedrock_backend.arn
}
