# Phase 09 — Route 53 DNS

## Overview

This phase configures DNS for the application using Amazon Route 53.

The objective is to expose the Kubernetes application through a custom domain instead of accessing the application through the AWS Load Balancer DNS name directly.

In this implementation, the custom domain is:

`pittylittle.shop`

The DNS architecture uses:

- GoDaddy — Domain registrar
- Amazon Route 53 — Authoritative DNS service
- Route 53 Hosted Zone — DNS management for the domain
- AWS Load Balancer — Public endpoint for the Kubernetes application

---

## Objectives

The main objectives of this phase are:

1. Create an Amazon Route 53 hosted zone.
2. Configure Route 53 as the authoritative DNS provider.
3. Update the domain nameservers at the registrar.
4. Create DNS records for the application.
5. Map the custom domain to the AWS Load Balancer.
6. Validate DNS resolution.
7. Validate application accessibility through the custom domain.

---

## Architecture

```text
                         Internet
                             |
                             |
                    pittylittle.shop
                             |
                             v
                    +----------------+
                    |    GoDaddy     |
                    | Domain         |
                    | Registrar      |
                    +-------+--------+
                            |
                    NS Delegation
                            |
                            v
                    +----------------+
                    | Amazon Route53 |
                    | Hosted Zone    |
                    +-------+--------+
                            |
                       DNS Record
                            |
                            v
                    +----------------+
                    | AWS Load       |
                    | Balancer       |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    | Kubernetes /   |
                    | Application    |
                    +----------------+


Prerequisites

Before starting this phase, the following components should already be available:

AWS account
Route 53 access
Registered domain
Kubernetes cluster
Kubernetes application
Public AWS Load Balancer
Application accessible through the Load Balancer DNS name

Example:

AWS Load Balancer DNS
<load-balancer-dns-name>

The application should be verified through the Load Balancer before configuring DNS.

1. Create Route 53 Hosted Zone

Open the AWS Console.

Navigate to:

AWS Console
    |
    +-- Route 53
          |
          +-- Hosted zones

Create a new hosted zone.

Domain:

pittylittle.shop

Type:

Public hosted zone

After creation, Route 53 provides four authoritative nameservers.

Example:

ns-xxxx.awsdns-xx.com
ns-xxxx.awsdns-xx.net
ns-xxxx.awsdns-xx.org
ns-xxxx.awsdns-xx.co.uk

Use the actual nameservers provided by your Route 53 hosted zone.

2. Configure Nameservers in GoDaddy

The domain was registered through GoDaddy.

Route 53 becomes authoritative only after the domain's nameservers are changed at the registrar.

Open the domain management page in GoDaddy.

Navigate to:

Domain
    |
    +-- DNS
         |
         +-- Nameservers

Replace the existing GoDaddy nameservers with the four nameservers provided by Route 53.

Example:

ns-xxxx.awsdns-xx.com
ns-xxxx.awsdns-xx.net
ns-xxxx.awsdns-xx.org
ns-xxxx.awsdns-xx.co.uk

Save the changes.

3. Verify Nameserver Delegation

From a workstation, verify that the domain is delegated to Route 53.

Windows:

nslookup -type=NS pittylittle.shop

Expected result:

pittylittle.shop
    nameserver = ns-xxxx.awsdns-xx.com
    nameserver = ns-xxxx.awsdns-xx.net
    nameserver = ns-xxxx.awsdns-xx.org
    nameserver = ns-xxxx.awsdns-xx.co.uk

The returned nameservers should match the nameservers assigned by the Route 53 hosted zone.

4. Identify the Application Load Balancer

The Kubernetes application is exposed through an AWS Load Balancer.

Check the Kubernetes service:

kubectl get svc -A

Example:

NAME             TYPE           CLUSTER-IP      EXTERNAL-IP
frontend         LoadBalancer   10.x.x.x        <load-balancer-dns>

Get the Load Balancer information:

kubectl get svc frontend -o wide

The EXTERNAL-IP should resolve to an AWS Load Balancer DNS name.

5. Create Route 53 DNS Record

Open:

AWS Console
    |
    +-- Route 53
          |
          +-- Hosted zones
                |
                +-- pittylittle.shop

Create a DNS record.

For the root domain:

Record name:

pittylittle.shop

Recommended configuration when the endpoint is an AWS Load Balancer:

Record type:
A

Enable:

Alias

Select the appropriate AWS Load Balancer as the alias target.

The resulting DNS configuration should conceptually look like:

pittylittle.shop
        |
        v
Route 53 A / Alias
        |
        v
AWS Load Balancer
        |
        v
Kubernetes Service
        |
        v
Application
6. Configure www Subdomain

If the application should also be accessible through:

www.pittylittle.shop

create another DNS record.

Recommended configuration:

Name:

www

Type:

A

Enable:

Alias

Point the record to the same AWS Load Balancer.

Alternatively, www can be configured as a CNAME depending on the chosen DNS architecture.

7. DNS Validation

After creating the records, verify DNS resolution.

For the root domain:

nslookup pittylittle.shop

or:

nslookup -type=A pittylittle.shop

For the www hostname:

nslookup www.pittylittle.shop

The DNS response should resolve to the configured AWS endpoint.

8. Verify from Multiple DNS Resolvers

DNS propagation can vary depending on resolver caching.

Check using:

nslookup pittylittle.shop

Also verify the authoritative nameservers:

nslookup -type=NS pittylittle.shop

The authoritative nameservers should be the Route 53 nameservers.

9. Application Validation

Once DNS resolution is working, open:

http://pittylittle.shop

The request flow should be:

Browser
   |
   v
pittylittle.shop
   |
   v
Route 53
   |
   v
AWS Load Balancer
   |
   v
Kubernetes Service
   |
   v
Application Pod

The application UI should load successfully.

10. Troubleshooting
DNS does not resolve

Check:

nslookup -type=NS pittylittle.shop

If the nameservers are still pointing to the old provider, the GoDaddy nameserver delegation has not completed.

Verify that the Route 53 nameservers were copied correctly into GoDaddy.

Root domain works but www does not

Check:

nslookup www.pittylittle.shop

If www returns:

Non-existent domain

create a Route 53 record for:

www.pittylittle.shop
DNS resolves but application is unavailable

First verify the Load Balancer directly.

Check:

kubectl get svc -A

Verify that the Kubernetes service has a valid external endpoint.

Then test the Load Balancer DNS name directly.

If the Load Balancer itself is unavailable, troubleshoot Kubernetes or AWS Load Balancer configuration before troubleshooting Route 53.

Application works through Load Balancer but not through domain

Check the Route 53 record.

Verify:

Domain
   |
   +-- Correct hosted zone
   |
   +-- Correct record
   |
   +-- Correct Load Balancer target

Also verify:

nslookup pittylittle.shop
Intermittent DNS resolution

Intermittent behavior can occur because of DNS caching and resolver propagation.

Check the authoritative Route 53 nameservers directly if required.

Also verify that there are no conflicting DNS records at the registrar.

Once Route 53 is authoritative, DNS records should be managed from the Route 53 hosted zone.

11. DNS Validation Commands

Useful commands used during this phase:

Check nameservers
nslookup -type=NS pittylittle.shop
Check A record
nslookup -type=A pittylittle.shop
Check www record
nslookup -type=CNAME www.pittylittle.shop
Check Kubernetes services
kubectl get svc -A
Check Kubernetes ingress
kubectl get ingress -A
12. Evidence to Capture

Store implementation evidence under:

evidence/09-route53/

Recommended evidence:

01-route53-hosted-zone.png
02-route53-nameservers.png
03-godaddy-nameservers.png
04-route53-dns-record.png
05-load-balancer-endpoint.png
06-nslookup-nameserver.png
07-nslookup-domain.png
08-application-custom-domain.png

Evidence should demonstrate:

Route 53 hosted zone creation.
Route 53 nameservers.
GoDaddy nameserver delegation.
DNS record configuration.
AWS Load Balancer endpoint.
Successful DNS resolution.
Successful application access through the custom domain.

Do not store credentials, access keys, tokens, or other secrets in the repository.

13. Validation Checklist
Validation	Status
Route 53 hosted zone created	Completed / Pending
Public hosted zone configured	Completed / Pending
GoDaddy nameservers updated	Completed / Pending
Route 53 nameserver delegation verified	Completed / Pending
AWS Load Balancer identified	Completed / Pending
Route 53 A/Alias record configured	Completed / Pending
www record configured	Completed / Pending
DNS resolution verified	Completed / Pending
Application accessible through domain	Completed / Pending
14. Phase Outcome

At the end of this phase, the application is accessible through a custom domain instead of requiring users to access the AWS Load Balancer DNS name directly.

The final request path is:

User
 |
 v
pittylittle.shop
 |
 v
Amazon Route 53
 |
 v
AWS Load Balancer
 |
 v
Kubernetes Service
 |
 v
Application

This establishes the DNS layer required for the application platform.

15. Important Note

Route 53 is responsible for DNS resolution.

It does not itself provide HTTPS/TLS termination.

If HTTPS is required, the next implementation should include:

Route 53
    |
    v
HTTPS / TLS Certificate
    |
    v
AWS Load Balancer
    |
    v
Kubernetes Application

The certificate and HTTPS configuration should be documented separately from the DNS configuration.

Phase 09 Completed

The Route 53 DNS layer has been implemented and validated when:

The domain resolves through Route 53.
The DNS record points to the application endpoint.
The application is accessible through the custom domain.
DNS configuration is documented.
Implementation evidence is stored under:


