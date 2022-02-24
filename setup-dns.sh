#!/bin/sh

. ./env.sh

# cat << EOF > policy.json
# {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Action": [
#           "route53:ChangeResourceRecordSets"
#         ],
#         "Resource": [
#           "arn:aws:route53:::hostedzone/*"
#         ]
#       },
#       {
#         "Effect": "Allow",
#         "Action": [
#           "route53:ListHostedZones",
#           "route53:ListResourceRecordSets"
#         ],
#         "Resource": [
#           "*"
#         ]
#       }
#     ]
#   }
# EOF

POLICY_ARN=arn:aws:iam::810085911474:policy/ampc-sandbox-us-east-1-external-dns

eksctl delete iamserviceaccount --name ampgw-external-dns-svcacc-gm --namespace default --cluster $ENVIRONMENT
eksctl utils associate-iam-oidc-provider --approve --region=us-east-1 --cluster=$ENVIRONMENT 
eksctl create iamserviceaccount --approve --name ampgw-external-dns-svcacc-gm --namespace default --cluster $ENVIRONMENT --attach-policy-arn $POLICY_ARN --override-existing-serviceaccounts

kubectl apply -f externaldns.yaml