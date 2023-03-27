# Notes 

### Changes

Changed provider configuration to 0.13\
Changed tags to tag in aws_autoscaling_group\
Moved all files into modules\
Moved user-data into ./user-data

### Documentation notes
To ssh to the bastion\
ssh -i <public_key ec2-user@<bastion-public-ip>

### Improvements
Enable session manager and remove bastion\

Change the name of the internal and external elbs which are currently\

master - internal-master.eu-west-2.elb.amazonaws.com\
master - master.eu-west-2.elb.amazonaws.com

### Questions
How is this set
echo $HOSTEDZONE_NAME\
echo $AWS_DEFAULT_REGION




