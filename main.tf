resource "aws_eks_cluster" "main" {
  name                      = "${var.env}-${var.name}"
  role_arn                  = aws_iam_role.eks-iam-role.arn
  version                   = var.k8s_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access  
    endpoint_private_access = var.endpoint_private_access 
    public_access_cidrs     = var.public_access_cidr
    security_group_ids      = [aws_security_group.node.id]
  }
}


resource "aws_security_group" "cluster" {
  name                      = "${var.env}-${var.name}-cluster-sg"
  description               = "Cluster Internal Communications"
  vpc_id                    = var.vpc_id

  egress {
    from_port               = 0
    to_port                 = 0
    protocol                = -1
    cidr_blocks             = ["0.0.0.0/0"]
  }

tags = merge(
    local.common_tags,
    map(
        "Name", "${var.env}-${var.name}-SG"
    )
)
}


resource "aws_security_group_rule" "Cluster-Ingress-HTTPS" {
  from_port                 = "443"
  to_port                   = "443" 
  protocol                  = "tcp"
  type                      = "ingress" 
  description               = "Allows Pods to talk to Cluster"
  security_group_id         = aws_security_group.cluster.id
  source_security_group_id  = aws_security_group.node.id
}

resource "aws_security_group_rule" "Cluster-Ingress-Local-HTTPS" {
  cidr_blocks               = var.local_ip
  from_port                 = "443"
  to_port                   = "443" 
  protocol                  = "tcp"
  type                      = "ingress" 
  description               = "Allows Pods to talk to Cluster"
  security_group_id         = aws_security_group.cluster.id
#  source_security_group_id  = "${aws_security_group.node.id}"
}

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  arn                       = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "AmazonEKSServicePolicy" {
  arn                       = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy-attach" {
  role                      = aws_iam_role.eks-iam-role.name
  policy_arn                = data.aws_iam_policy.AmazonEKSClusterPolicy.arn
}

resource "aws_iam_role_policy_attachment" "eks-service-policy-attach" {
  role                      = aws_iam_role.eks-iam-role.name
  policy_arn                = data.aws_iam_policy.AmazonEKSServicePolicy.arn
}


resource "aws_iam_role" "eks-iam-role" {
  name                      = "${var.env}-${var.name}-iam-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF


}