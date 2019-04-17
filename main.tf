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
