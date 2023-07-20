data "aws_ami" "server_ami" {
    most_recent = true
    owners = ["099720109477"]
    # this is the AMI owner (see word doc)

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
        # this is the AMI name (see word doc)
        # use * for the date
    }
}
# This is the ami for the development node that will be instantiated on EC2
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
