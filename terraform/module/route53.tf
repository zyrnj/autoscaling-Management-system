data "aws_route53_zone" "zyrnj" {
  name = "demo1.zyrnj.me"   // replace with your domain name
  private_zone = false
}


resource "aws_route53_record" "zyrnj" {
  zone_id = data.aws_route53_zone.zyrnj.zone_id
  name    = "demo1.zyrnj.me"    // replace with your domain name
  type    = "A"
  ttl     = 300              // set the TTL value to your desired value

  records = [
    aws_instance.web.public_ip
  ]
}