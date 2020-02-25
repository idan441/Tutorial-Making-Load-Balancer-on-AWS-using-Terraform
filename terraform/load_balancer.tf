
###################################################
####### Make a load balancer in Amazon aws. #######
###################################################
### In this solution I show how to make a load #### 
#### balancer in Amazon aws with an costum AMI ####
###################################################



### Example 2 - How to make a load balancer in amazon AWS . ( for the TED-application ) 

  #This examples is a full solution for beginner and advanced users of the Amazon aws services. 


#Notes - 
  # This code is based on a former solution I have made for making two VPC and two subnets. 
  # This tf file is written for Terraform version 0.12 ! The syntax may differ in different versions. 
  # You need to set up your access key information in the access_key.csv file! Also, if you want to be able to ssh to your instances you need to set a key-pair for them manually in the amazon aws console. In this example I picked the name "terra.pem" for my public key, though it is not used needed in order to run this script, in case I would like to ssh to the EC2 instances who will be created - then I will need that key! 

#In all example I will be using an application named "TED-app" which is a Java Spring application which queries the TED's website for lectures. It then shows the results of the lectures search. This application is web-based and working on port 9191 with HTTP protocol. The application source code is located in the TED-app directory. 
  #I have made an amazon machine image (ami) which already includes the app and all of it's configuration. 
  #An amazon machine image (ami) is basically and EC2 instance image which includes already made files and configuration. Mainly we use images which are just the operating system (OS) but here I use na image which includes the TED-app and all configuration already made. 
  #For more explanation see the section named "Define an AMI with the application and configurations" in this solution. 


# Checklist - Steps to perform - 
# 0. Make an AMI (Amazon Machine image, which will be the image set up on the EC2 instance) and have the AMI id. 
# 0. set the vpc, subnets - and all other netowrking issues. ( Done at the former solution. ) 
# 1. Make a security group with the premissions for the instances. ( In my case port 9191 accesable so the guests can surf to the server. ) 
# 2. set launch configuration. 
# 3. set auto-scaling group. 
# 4. set load balancer. 
# Each section is based on the one before it! SO MAKE SURE TO DO THEM IN THE RIGHT ORDER! 



#Helpful websites - 
# An example for making loading balance with ssl certificate - https://blog.valouille.fr/post/2018-03-22-how-to-use-terraform-to-deploy-an-alb-application-load-balancer-with-multiple-ssl-certificates/





##############################################################################################################
########### Define the VPC and two subnets in two different availability zones! ##############################
########### This part is from based on my former solution of how to define a vpc with two subnets! ###########
########### For an example of this part working please see that solution. ####################################
##############################################################################################################



##################################################
############### Set the variables ################
##################################################


#Make two variables for 2 availability zones. (=AZ)
  #In this example I will be making two subnets, each one in a different avalability zone. (AZ) 
  #Availability zone is an internal area and infrastructure inside an amazon aws region. For my example I am using Ohio region (us-east-2) which has 3 availability zones (AZ) - a, b and c . 
variable "region" {
  default ="us-east-2"
}
variable "availability_zone1" {
    default = "us-east-2a"
}
variable "availability_zone2" {
    default = "us-east-2b"
}


######################################################################
############### Set the CIDRs for the VPC and subnets ################
############### Also a small lesson about networking! ################
######################################################################


#First of all I will expalain a few concepts about networking and cloud technologies - 

#VPC - 
  #The amazon cloud is a large servers infrastructure including many different costumers. In order to isolate my EC2 instances I will need to make a "small private" cloud inside the amazon cloud. And that is a VPC! 
  #VPC stand for - virtual private cloud, which is actually an enclosed isolated cloud inside a bigger cloud service. 

#Subnets - 
  #Each VPC contains subnets - which are internal networks. 
  #Each subnet is having a range of ip addresses which are available for EC2 instances. ( Each instance is given an ip address, and with these ip addresses they can connect to each other - AND HERE IS THE AMAZIN PART - all of that in my own virtual private cloud (VPC) which I have made! ) 
  #By making a subnet you can isolate groups of EC2 instances from other subnets in your own VPC . ( So for example I can have a small subnet of 4 EC2 instances - and to control and make a unique security policy for them. ) 
  #Each subnet can be in one availability zone (AZ) and all EC2 instances who are part of the subnet will be on that AZ. 

#CIDR - 
  #To define a subnet you need to define it's IP addresses range - and for that you need to define a classes inter-domain routing. (CIDR) 
  #CIDR is basically a way to defined a network size - you choose the fixed number in the IP address - and the end-stations numbers which are not fixed. 
  #* I won't explain about how to calculate CIDR , you can search for it on google. *

#How my defined network will look like? 
  #In my example I am using a CIDR of 10.1.0.0/24 for the VPC - which means that all IP addresses will start with 10.1.0 - and the last number will be differnt. That means that there will be 256 IP addresses in my VPC ranging from 10.0.1.0 to 10.0.1.255 . 
  #Later, I will be dividing the VPC to two subnets, each will include 128 ip adresses. ( subnet 1 will range from 10.0.1.0 to 10.0.1.127 and subnet 2 will range from 10.0.1.128 to 10.0.1.255 . ) 
  #Each subnet will also have a CIDR in order to define its ip addresses range. 

#
  #Important concept - for every EC2 instance an ip address needs to be assigned - whether automatically or manually when creating the EC2 instance. In this example I will be creating 2 instances adn will assign them ip addresses manually! 
  #A note - amazon is taking 4 ip addresses from every subnet, in order to use it for routing and networking - first number is the network name (that's globally not only in amazon) , second number is the router ip address which connect the subnet to other networks, the third number is save for future use of amazon - and the last number is for broadcasting. 
    #Example - for subnet 1 with a CIDR of 10.1.0.0/25 where the ip range is from 10.1.0.0 to 10.1.0.127 : 
      #10.1.0.0 is the network name and you can't use it. (That is general in all networking world - not only in amazon! ) 
      #10.1.0.1 is the network router, and the EC2 instances in the network will use this router to connect to each other and to other subnets. ( and the internet if you open the network for the web. ) 
      #10.1.0.2 is saved by amazon for future uses and therefore can't be assigned to an EC2 instance. 
      #10.1.0.127 - the last number on the netwrok (=the last number on the range) is used for broadcasting. 

  #For calculating the ip ranges more easier - I used this computer - 
    # http://jodies.de/ipcalc?host=10.1.0.0&mask1=25&mask2=
    # The link below shows the calculation of subnet1 CIDR which I will define below. 

    

#Define a CIDR for the VPC. 
variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default = "10.1.0.0/24" # Note that some IP addresses are considered public and some private, the private ones are FREE - and this ip address of 10.1.0.0 is a free one. (This range is called "Class A" and is used for small private networks. ) 
}

#The CIDR for every subnet need to be different so no IP overlap will happen. (Amazon AWS will show error in case it happens - and will not make the subnets, meaning the "terraform apply" command will show errors. )
variable "cidr_subnet1" {
  description = "CIDR block for the subnet"
  default = "10.1.0.0/25"
  #Ip range 10.1.0.0 - 10.1.0.127 = total of 128 addresses. ( From them amazon will use first 4 and last 1 so it is neto 123 . )
}
variable "cidr_subnet2" {
  description = "CIDR block for the subnet"
  default = "10.1.0.128/25"
  #Ip range 10.1.0.128 - 10.1.0.255 = total of 128 addresses. ( From them amazon will use first 4 and last 1 so it is neto 123 . )
}


#Here I will be making a tag called production and I will add it to the resources (EC2 instances, VPN, subnets etc... ) in order to be able to categorize them for comftability. You don't have to do it - it's just to make things easier! 
variable "environment_tag" {
  description = "Environment tag"
  default = "Production"
}



###########################
#### Connect to amazon ####
###########################

#Provide a provider (AWS) and credentials for login. 
  #Here I pick region us-east-2 which is Ohio, and includes 3 availability zones. ( In short AZ. ) 
  #The credentials are saved in a file called accesKeys.csv which is located in my directory. Just put you credentials in order for you to login. 
  #Remember to make sure not to share your credentials! 
provider "aws" {
 region = var.region 
 shared_credentials_file = "./accessKeys.csv"
  #More information here about how to login to AWS using terraform  - https://blog.gruntwork.io/authenticating-to-aws-with-the-credentials-file-d16c0fbcbf9e
}



#########################################################################################
######## Set the VPC and subnets and connect them together with a routing table #########
#########################################################################################

#Set the VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_vpc #As defined in the variable section - the CIDR of the VPC is "10.1.0.0/24" - this is a private IP address range - class A - NOT COSTING CASH!!! 
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = var.environment_tag 
    #Environment name in this case "PROD" = production. ( In this example it doesn't matter and is just for comfortability. ) 
  }
}

#Define 2 subnets for this example. 
resource "aws_subnet" "subnet_public1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet1 #Defined in the variables section. 
  map_public_ip_on_launch = "true"
  availability_zone = var.availability_zone1 #us-east-2b, see variables section. 
  tags = {
    Environment = var.environment_tag
  }
}
resource "aws_subnet" "subnet_public2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet2 #Defind in the variables section. 
  map_public_ip_on_launch = "true"
  availability_zone = var.availability_zone2 #us-east-2a, see variables section. 
  tags = {
    Environment = var.environment_tag
  }
}


#What is a routing table? 
  #Each VPC is having a routing table, which is basically a table (list) of it's routers. 
  #When a computer wants to contact another computer in the same network (subnet) it uses the networks route. 
  #When a computer wants to contact another computer in a different network - then it contact it's network router, which in turn contacts the router of the other network - which in turn contact the computer on that network. 
  #In order for the router of the two networks to know each other - they need to connect to a routing table - which tells them the ip addresses of the other routes. ( In amazon it is the second number on the network remember? 10.1.0.2 and 10.1.0.128 in my subnets! :D ) 


#What is an internet gateway? 
  #It is an amazon object which basically adding another "router" to the VPC's routing table - a router which is connected to the web. 
  #In simple words - if you add an internet gateway - then your VPC can be connected to the internet. ( And not isolated anymore. ) 
  #Why would I like to do it? Because I want to access the TED-app from my browser, and therefore the EC2 instances needs to be connected to the internet. 
resource "aws_internet_gateway" "igw" { # Allow access of the instances to the web, by opening an internet gateway and attaching it to the routing table. 
  vpc_id = aws_vpc.vpc.id
  tags = {
    Environment = var.environment_tag
  }
}

#Add a line for the routing table which opens the instances to all outside IPs (To the web) which is 0.0.0.0/0
resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
      Environment = var.environment_tag
  }
}

#Add the two subnets to the routing table - so they can be connected between each other. ( Also because there is an internet gateway then they will be able to connect to the internet. ) 
resource "aws_route_table_association" "rta_subnet1_public" {
  subnet_id      = aws_subnet.subnet_public1.id
  route_table_id = aws_route_table.rtb_public.id #rtb_pubic is a routing table defined in teh above paragraph, which can connect between the subnets and the gateway. 
}
resource "aws_route_table_association" "rta_subnet2_public" {
  subnet_id      = aws_subnet.subnet_public2.id
  route_table_id = aws_route_table.rtb_public.id #rtb_pubic is a routing table defined in teh above paragraph, which can connect between the subnets and the gateway. 
}




##### END OF THE VPC AND SUBNETS DEFINING! ##### 
##### If you want to see a demonstration of how it works - please refer to my repositroy, to day1 . ### 


##############################################################
######## Beggining of the load balancer definition ! #########
##############################################################







##############################################################
### Define an AMI with the application and configurations! ###
##############################################################

#Why do you need an AMI when lanching a load-balancer? 
  #Because the instances are created automatically by the launch configuration, there is not "time" to setup it. Therefore the instance should already be "ready" with all configuration. 

#How to make you own AMI: 
  #So I made an AMI (Amazon Machine Image) which is basically an image, which includes the application and all configuration. 
  #In order to make an AMI you need to manually create an instance, install the application and define all configuration. Afterwards right click on the instance id in the amazon console and choose to make an AMI image. The new AMI you created includes the original image (ubuntu/debian/windows/etc..) and the definition. After making the AMI you can launch instances with it - those instances will include the OS image and the application and its configuration. 
  #Now after making the AMI you can launch it countless of times - with your application installed! 
  #An important note - because the instances are launched automatically by the launch configuration - they must start the application automatically! THerefore, when making the AMI make sure that it is set in a way which the application will automatically start upon start of the instance. ( In my case I used crontab, which is a component of the Ubuntu system, in order to launch the aplciation when the system is launched. ) 

#Define a variable with the ami id. 
variable "my_ami_id" {
  description = "Base AMI to launch the instances - The TED-search app ubuntu 18.04 image which I have made. "
  default = "ami-0ad4e8f13655edfef" #This is the ami id which amazon gave to my image - it is an ubuntu image with java installed, the TED-app installed an automatically launched at system start, and all other configurations needed. 
}


#Create security group which will allow to allow access to the instance from the web. 
resource "aws_security_group" "security_group_9191" {
  name = "sg_9191"
  vpc_id = aws_vpc.vpc.id #THe VPC I defined in the above sections... 
  ingress {
      from_port   = 9191 #The TED-app is open on port 9191
      to_port     = 9191
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = var.environment_tag
  }
}


## Creating Launch Configuration
  #This instance will be the application, and the ELB ( Elastic auto-scaling. ) will create more of it if needed. 
  #A launch configuration is basically like "make instance" instructions, which can later be used by the auto-scaling groups to launch the instances. 
  #In simple words - It will tell the auto-scaling group which instance to make and its settings! 

resource "aws_launch_configuration" "ted_app_launch_configuration" {
  #Instance details. 
  image_id               = var.my_ami_id #The ami of the instance which will be uploaded.  
  instance_type          = "t2.micro" #The only free-tier option. 
  name = "ted-app-launch-configruation" #If you leave this section empty - terraform will automatically create a default name. BUt it is important to say that in all cases the launch configuration must have a name! 
  
  #Set security group - with the ports to have access to the instances and their running applications! 
  security_groups        = [aws_security_group.security_group_9191.id] #This security group will open port 9191 access to the internet! 

  #The auto-scaling group will use the launch_configuration in order to create the instances according to these settings! 
}


##############################################################
####### Define a target group and auto-scaling group! ########
##############################################################

resource "aws_alb_target_group" "target_group_example_for_ted_app" {
  #The target group is a group which will contain the group of instances who will be up by the system. 
  #The LB (load balancer) will route to the target group - which will route to one of the instances. 
  name        = "ted-app-target-group"
  port        = 9191 #The port to connect to the application, in my case it is 9191 for the TED-app. 
  protocol    = "HTTP" #The protocol which is required to contact the application. The LB service is working with http/https - in my case I am using http to contact to the TED-app. 
  target_type = "instance" #Choose how to target to your instances running the application - ip will refer to their ip address, instances will refer to the instance id. 
  vpc_id      = aws_vpc.vpc.id


  #Health check is not a must! 
    #The health check gives details to the loading balancer about HOW (protocol) and WHERE (path) to do the health check for the application. 
    #The health check is actually very simple - it tries to acces the application by connecting to it - if there is no answer then the load-balancer will assume the instance is having a problem - and it will stop refering users to it and instead will refer them to other instances. ( If needed, then it will launch more instances, until the amount of "max-size" - which is defined in the auto-scaling group. I defined it in the next paragraph. ) 
    #In my case to acces the ted-app you need to use HTTP protocl under the root path "/" . (="http://address.com/")
  health_check {
                  protocol = "HTTP"
                  path = "/"
               }       
}



## Creating AutoScaling Group
  #Basically, when using this service then it will make many instances of the same type - so they can *potentially* backup each other. ( This service will not balance between the instances - so each one will be accessed manually by its IP adress or DNS address! Later a Load Balancer will be set and will manage the traffic between the instances. (LB = load balncing in the computers world) )
  #Why did I say *potentially* ? Because it does make multiple instances when needed - HOWEVER it doesn't refer the users to any of the instances. ( i.e there can be 2 instances but the user need to manually enter each one of them. ) 
  #The auto-scaling group need a defined instance to be able to launch many instances of it - and this informatipn is passed through Launch Configutaion. ( Which I defined in the prior paragraph! ) 
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.ted_app_launch_configuration.id #This will tell the auto-scale to use the launch configuration that I defined. (It is to note that here I refer to the id of the launch configuration which I made, but actually it is not set yet because I didn't run the script. When the script will run using the command terraform apply - it will create the launch configuration - and then it will save the id - and will output it here at the auto-scale group. ) 
  #name = "auto_scaling_group_ted_app" #If the name won't be set here manually - then the Terraform script will pick an automatic name when being applied using the terraform applied command. 
  

  #Set the amount of times the instance will be created by the auto-scaling group. 
    #Min amount = the minimum amount of instances at any time. ( THEY COST CASH - SO PICK WISELY! ) 
    #Max amount = In case there is a big use of the current instances - the auto-scaling group will launch more instances of it. This is the maximum of instances who will be launched! 
  min_size = 1 #Min amount of instances. 
  desired_capacity = 1 #This is the amount of instances which should be, while every-time the auto-scale-group will try to reach that amount. ( needs to be in a range between the min_size and max_size. ) 
  max_size = 2 #Max amount of instances. 

  #load_balancers = [aws_alb.ted_app_load_balancer.id]
  target_group_arns = [aws_alb_target_group.target_group_example_for_ted_app.arn] #A list of the target groups. A note: arn = amazon resource name - like a serial ID for each object created in the aws. It is produced when the object si being created in the aws by the user/console/terraform. 
  vpc_zone_identifier = [aws_subnet.subnet_public1.id, aws_subnet.subnet_public2.id] #The list of subnets that the instances will be launched at. In this case I use the ones I set. ( A note: In the aws console you need to pick a VPC and then it will let you choose the subnets you defined in it, however here you need to write the subnets name by yourself - but you must make sure they are in the VPC! You don't actually need to write the VPC here in the auto-scale-group resource definition. ) 
}



##############################################################
######### Define a the load balancer (LB) - at last! #########
##############################################################


#So what is actually the load balancer? 
  #It is actually an nginx server - which proxy (=refering to other servers) the users. 
  #In this case the nginx server will proxy the EC2 instances which are created by the auto-scaling group. 
  #To make it clear - the auto-scaling group makes the EC2 instances and manages them, and the load balancer will refer the guests to them. 

  #It is to note that the load balancer is updated automatically with the addresses of the EC2 instances that were launched by the auto-scaling group. 



# Security Group for LB (Load balancing)
  #First of all, let's make a security group for the load-balancer so it will defined the ports that guests can access to. 
  #The load balancer is an nginx server, and it works on the default HTTP protocl which uses port 80 as a default. 
  #The open ports are  port 80 (for guest comming in the load-balancer) and for port 9191 . (for the ted-app) Note that the IP is an own choice, and can be changed according to the desired port. 
resource "aws_security_group" "lb_security_group" {
  name = "terraform-example-elb"
  vpc_id = aws_vpc.vpc.id #THe VPC I defined in the above sections... In order for the security group to be attached to the load balancer - they have to be in the same vpc. 

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80 #nginx server working with HTTP protocol. 
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 9191 #The TED-app port. Note that you can configure the web access better, but I put this port too just to make it more easy to understand. 
    to_port = 9191
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




#Creating ELB. (Elastic load balancer - which is the new type of load balancer by Amazon. ) 

  #What is Elastic load balancer? This is a service which sets a proxy server - which can send the users connecting to it - to other EC2 instances. If one EC2 instance is busy/not-wroking/etc then it (the ELB) will send the user to another EC2 instance. 
  #The EC2 intances are defined in the auto-scaling groups in the former paragraphs. 

  #An important note - this example is showing the use of the new load-balance service, which is used for web-apps. There is also an older version of the load balancer service. The older service is refered in terraform as "aws_lb" (load balancer) while the new one is reffered as "aws_alb" . ( Application loading balancer. )
resource "aws_alb" "ted_app_load_balancer" {
  load_balancer_type = "application"
  name = "ted-app-lb" #Again - the name is optional, if not chosen - then the system will automatically will create one. HOWEVER IT IS IMPORTANT TO SAY - the name defined - will be a part of the DNS address. ( The address you will use to acces the ELB proxy server from the browser. )   


  enable_deletion_protection = false #By default it is defined to true, which makes it impossible to delete the load balancer until you change it! That means that "terraform destroy" won't be able delete the load-balancer unless enable_deletion_protection is set to false! 


  #Important note - if you use subnets in ELB - then you need to have a security group! In more simple words - I use VPC (Virtual private cloud) which has subnet which I have created - and I need to choose which ports to expose. The ELB is also a server in this VPC - so I have to open access ports in order to make it possibel for guests to enter my server. (port 80, defined in the above paragraph. ) 
  subnets = [aws_subnet.subnet_public1.id, aws_subnet.subnet_public2.id] #For the load balancer to work - at least two different subnet in *TWO DIFFERENT* AVAILABILITY ZONES need to be choosen. 
  security_groups = [aws_security_group.security_group_9191.id, aws_security_group.lb_security_group.id] #A list of the security groups that for the elb server. This is like instance security group - you need to choose which ports and protocol the ELB server will use. In my case I need port 80 for public use and port 9191 for contact with the instances. 

  tags = {
    Environment = var.environment_tag
  }
}



#Last things - make load balancer listener! 
  #Listener is important!!! 
  #Listener is a rule which can be attached to a load-balancer. It tells the server which port to open for the guests to access it. 
  #In simple words - it defines the load balancer on which port and with which protocl to listen. 
  #I chose to use HTTP protocol and port 80 which is the default port for HTTP access.   

resource "aws_alb_listener" "listener_ted_app" {
  #Here you define to the load balancer server how the guests will access it. 
  port = 80 #Users will access the ELB server via port 80 . 
  protocol = "HTTP" #User will acces thruogh http protocol - but you can also use https protocol if you want to. 
  
  #Important - here I attach the listener to the load balancer! 
  load_balancer_arn = aws_alb.ted_app_load_balancer.arn #Please note that you need to mention the arn (amazon resource name) and not id! ARN is like id but has a different value. When setting up the load balance resource the aws gives it an arn. 


  #Here you need to tell the listener what to do with the guests. 
    #I defined FROM WHERE users will connect to the server. ( In the last lines, via port 80 with HTTP protocol. )
    #Now I need to define the server WHERE to proxy the guests.  
  default_action {
                    target_group_arn	=	aws_alb_target_group.target_group_example_for_ted_app.arn #Here I tell the server to which EC2 instances it should proxy. (Actually I tell it the target_group which tells it the EC2 instances details. ) Note that it requires the arn and not the id! 
                    type			=	"forward" #Here I say the server to take the guests' requests and forward them to the EC2 instances of the target_group. 
                 }
  
  #what exactly listener is? 
    #You can sum it from this output which I saw in the aws console after create it with "terraform apply" command - " Port Configuration      80 (HTTP) forwarding to 9191 (HTTP) " . 
}


##############################################################
######### Testing and understanding the concepts #########
##############################################################

#To make all the resources enter the directory via terminal and enter the command - "terraform apply" 
  #Please note that creating all this architecture can take a few minutes! Also you need to be waiting until the TED-app will start working. 

#Try the load balancer: 
  #Enter the aws console and choose "load balancer" in the menu. 
  #Check the newly created load balancer. 
  #The load balancer is having a DNS address - enter it and it will take you to the EC2 instances. 
  #Enter via port 80 ( Because I opened the nginx load balancer server to that port. ) and it will refer to the EC2 instances on port 9191 . 

#Try the target group - 
  #Now enter to one of the EC2 instances and "sabotage" it. 
  #Wait until the health check is failing, and then try to enter the load balancer DNS address. Because the EC2 instance failed the health check - the laod balance will proxy to it. 
  #Now try to terminate the EC2 instaces. Wait until the health checks are done - and see that the target group will make new instances instead of those who were terminated. (It will try to get to the desired_capacity as defined in the auto-scaling group. )


