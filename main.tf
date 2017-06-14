module "404_container_definition" {
  source = "github.com/mergermarket/tf_ecs_container_definition.git"

  name           = "404"
  image          = "mergermarket/404"
  cpu            = "16"
  memory         = "16"
  container_port = "8000"
}

module "404_task_definition" {
  source = "github.com/mergermarket/tf_ecs_task_definition"

  family                = "${join("", slice(split("", format("%s-%s", var.env, var.component)), 0, length(format("%s-%s", var.env, var.component)) > 22 ? 23 : length(format("%s-%s", var.env, var.component))))}-404"
  container_definitions = ["${module.404_container_definition.rendered}"]
}

module "404_ecs_service" {
  source = "github.com/mergermarket/tf_load_balanced_ecs_service"

  name            = "${format("%s-%s-404", var.env, var.component)}"
  container_name  = "404"
  container_port  = "8000"
  vpc_id          = "${var.platform_config["vpc"]}"
  task_definition = "${module.404_task_definition.arn}"
  desired_count   = "${var.env == "live" ? 2 : 1}"
}

module "alb" {
  source = "github.com/mergermarket/tf_alb"

  name                     = "${format("%s-%s-router", var.env, var.component)}"
  vpc_id                   = "${var.platform_config["vpc"]}"
  subnet_ids               = ["${split(",", var.platform_config["private_subnets"])}"]
  extra_security_groups    = "${var.extra_security_groups}"
  certificate_arn          = "${var.platform_config["elb_certificates.${replace(var.dns_domain, "/\\./", "_")}"]}"
  default_target_group_arn = "${module.404_ecs_service.target_group_arn}"
}
