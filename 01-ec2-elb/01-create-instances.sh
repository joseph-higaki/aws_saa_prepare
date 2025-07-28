aws ec2 run-instances 
--image-id "ami-0150ccaf51ab55a51" 
--instance-type "t3.micro" 
--key-name "ec2 tutorial" 
--network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0}' 
--credit-specification '{"CpuCredits":"unlimited"}' 
--tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"My Static Web Server"}]}' 
--metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' 
--private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' 
--count "2" 