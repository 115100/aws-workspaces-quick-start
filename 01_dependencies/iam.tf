data "aws_iam_policy_document" "workspace_default_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workspace_default" {
  name               = "workspaces_DefaultRole"
  assume_role_policy = data.aws_iam_policy_document.workspace_default_trust.json
}

resource "aws_iam_role_policy_attachment" "workspace_access" {
  role       = aws_iam_role.workspace_default.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspace_self_service_access" {
  role       = aws_iam_role.workspace_default.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}
