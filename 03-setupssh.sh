

chmod 400 .auth/ec2tutorial.pem    # Owner can only read (recommended)

ssh -i "./.auth/ec2tutorial.pem" ec2-user@44.203.55.2
ssh -i "./.auth/ec2tutorial.pem" ec2-user@ec2-54-165-137-142.compute-1.amazonaws.com

ssh -i "./.auth/ec2tutorial.pem" 54.165.137.142