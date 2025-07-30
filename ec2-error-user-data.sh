#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello ERROR world from $(hostname)</h1>" > /var/www/html/special_error.html
