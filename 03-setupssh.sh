

chmod 400 .auth/ec2tutorial.pem    # Owner can only read (recommended)

ssh -i "./.auth/ec2tutorial.pem" ec2-user@44.203.55.2
