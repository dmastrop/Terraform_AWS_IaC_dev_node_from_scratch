# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "mtc_vpc" {
  cidr_block = "10.123.0.0/16"
  #  note strings must be in double quotes
  enable_dns_hostnames = true
  enable_dns_support   = true
  # this is default for support but include it so that reader knows about it

  tags = {
    Name = "dev"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "mtc_public_subnet" {
  vpc_id = aws_vpc.mtc_vpc.id
  # to access vpc_id resource, need a resource id.
  # we can get the reference id using the "terfaform state list" command.
  # aws_vpc.mtc_vpc is how we can reference the vpc
  # do not quote this. It is NOT a string.
  # the item is "id" and this needs to be appended at the end.
  # vpc_id = aws_vpc.mtc_vpc.id   id is the attribute we need.
  cidr_block = "10.123.1.0/24"
  # this is a subnet within the vpn cidr_block (see above).
  map_public_ip_on_launch = true
  # it will be assigned a public ip address that we will be able to SSH to.
  availability_zone = "us-west-1a"
  # there are resources that help verify the availablility_zone

  tags = {
    Name = "dev-public"
    # this will tell us it is a public subnet!!
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# we will do this a bit differently breaking up the aws_route_table and aws_route into separate resources
resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id = aws_route_table.mtc_public_rt.id
  # this refers to the above resource
  destination_cidr_block = "0.0.0.0/0"
  # all ip addresses go to this gateway
  gateway_id = aws_internet_gateway.mtc_internet_gateway.id
  # this is our gateway specified above.
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "mtc_public_assoc" {
  subnet_id      = aws_subnet.mtc_public_subnet.id
  route_table_id = aws_route_table.mtc_public_rt.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mtc_sg" {
  name = "dev_sg"
  # we don't need a tag because it has a name. You can tag it if you want
  description = "dev security group"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # this means any protocol

    cidr_blocks = ["98.234.0.0/16"]
    #cidr_blocks = ["98.234.32.176/32"]
    # [] because this can be a comma separated list
    # NOTE that this original IP address changed after the 7/25 internet outage.
    # the new IP address of my PC is 98.234.160.157.  To avoid having to change this
    # for each new outage, expand the CIDR block to 98.234.0.0/16
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # this allows all traffic outbound
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
# use the terraform file function instead of pasting the public key in this file::
# https://developer.hashicorp.com/terraform/language/functions/file 
resource "aws_key_pair" "mtc_auth" {
    key_name = "mtckey"
    public_key = file("~/.ssh/mtckey.pub")
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "dev_node" {
    instance_type = "t2.micro"
    ami = data.aws_ami.server_ami.id
    # this is from the datasources.tf file and note data must be prepended unlike resources
    
    key_name = aws_key_pair.mtc_auth.id
    # see above
    # note: run terraform state show aws_key_pair.mtc_auth
    # there is a key_name and that can be used instead of .id at the end
    # but .id is fine here as well.
    vpc_security_group_ids = [aws_security_group.mtc_sg.id]
    # see above for security group
    subnet_id = aws_subnet.mtc_public_subnet.id
    # see above for subnet

    # extract the contents of the userdata.tpl in root directory
    # this data is required to set up docker engine and install dependencies
    # on the EC2 linux node to bootstrap it.
    # use the terraform file function again.
    user_data = file("userdata.tpl")

    root_block_device {
        volume_size =10
        # 8 is default but 10 is still free-tier
        # this will give us a larger hard drive
    }

    tags = {
        Name = "dev-node"
    }

    # https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
    # note that the provisioner is inside of the aws_instance resource
    provisioner "local-exec" {
        # https://developer.hashicorp.com/terraform/language/functions/templatefile
        #command = templatefile("windows-ssh-config.tpl")
        #command = templatefile("linux-mac-ssh-config.tpl", {
        # add interopolation syntax for variable for operating system
        # variables in terraform are of the form *** var. **** 
        # see variables.tf file    Here we are interpolating var.host_os for the operating system.
        # https://developer.hashicorp.com/terraform/language/values/variables
        command = templatefile("${var.host_os}-ssh-config.tpl", {
            hostname = self.public_ip,
            user = "ubuntu",
            identityfile = "~/.ssh/mtckey"
            # identityfile is the private key from the keypair that we created
        })
        # note the () wraps the {}
        # interpreter defaults to bash
        # windows::
        #interpreter = ["Powershell", "-Command"]
        # linux, mac::
        #interpreter = ["bash", "-c"]
        # https://developer.hashicorp.com/terraform/language/expressions/conditionals
        # use a conditional for the interpreter. Iff linux-mac use bash, if not use Powershell
        interpreter = var.host_os == "linux-mac" ? ["bash", "-c"] : ["Powershell", "-Command"]
    }
}
