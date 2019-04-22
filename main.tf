provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "win_2019_base_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }

  owners = ["amazon"]
}

data "aws_availability_zones" "azs" {}

# Instance
resource "aws_instance" "octopus_server" {
  ami               = "${data.aws_ami.win_2019_base_ami.id}"
  instance_type     = "t3.micro"
  availability_zone = "${element(data.aws_availability_zones.azs.names, 0)}"
  key_name          = "${var.keyName}"

  associate_public_ip_address = false
  user_data                   = "${file("userdata")}"

  iam_instance_profile = "${aws_iam_instance_profile.ec2_describe.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
  }

  tags {
    Name = "disk-test-server"
  }
}

# EBS Data volume
resource "aws_ebs_volume" "octopus_data" {
  availability_zone = "${element(data.aws_availability_zones.azs.names, 0)}"
  size              = 60
  type              = "gp2"

  tags = {
    Name = "test-disk"
  }
}

resource "aws_volume_attachment" "octopus_data_attachment" {
  device_name = "xvdb"
  volume_id   = "${aws_ebs_volume.octopus_data.id}"
  instance_id = "${aws_instance.octopus_server.id}"
}

resource "aws_ebs_volume" "octopus_data_2" {
  availability_zone = "${element(data.aws_availability_zones.azs.names, 0)}"
  size              = 60
  type              = "gp2"

  tags = {
    Name = "test-disk-2"
  }
}

resource "aws_volume_attachment" "octopus_data_2_attachment" {
  device_name = "xvdc"
  volume_id   = "${aws_ebs_volume.octopus_data_2.id}"
  instance_id = "${aws_instance.octopus_server.id}"
}

# Instance IAM permisions
resource "aws_iam_instance_profile" "ec2_describe" {
  name = "ec2_describe"
  role = "${aws_iam_role.test_instance_role.name}"
}

resource "aws_iam_policy" "get_ec2_instance_info" {
  name        = "get_ec2_instance_info"
  description = "Allow getting info on ec2 instances: Describe"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    } 
  ]
}
EOF
}

resource "aws_iam_role" "test_instance_role" {
  name        = "test_instance_role"
  description = "Allow EC2 to assume iam policy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "test_instance" {
  role       = "${aws_iam_role.test_instance_role.name}"
  policy_arn = "${aws_iam_policy.get_ec2_instance_info.arn}"
}
