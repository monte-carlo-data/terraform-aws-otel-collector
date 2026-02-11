moved {
  from = aws_cloudwatch_log_group.log_group
  to   = module.otel_collector[0].aws_cloudwatch_log_group.log_group
}

moved {
  from = aws_security_group.security_group
  to   = module.otel_collector[0].aws_security_group.security_group
}

moved {
  from = aws_security_group_rule.security_group_ingress
  to   = module.otel_collector[0].aws_security_group_rule.security_group_ingress
}

moved {
  from = aws_lb.network_load_balancer
  to   = module.otel_collector[0].aws_lb.network_load_balancer
}

moved {
  from = aws_lb_target_group.target_group_grpc
  to   = module.otel_collector[0].aws_lb_target_group.target_group_grpc
}

moved {
  from = aws_lb_target_group.target_group_http
  to   = module.otel_collector[0].aws_lb_target_group.target_group_http
}

moved {
  from = aws_lb_listener.listener_grpc
  to   = module.otel_collector[0].aws_lb_listener.listener_grpc
}

moved {
  from = aws_lb_listener.listener_http
  to   = module.otel_collector[0].aws_lb_listener.listener_http
}

moved {
  from = aws_ecs_cluster.ecs_cluster
  to   = module.otel_collector[0].aws_ecs_cluster.ecs_cluster
}

moved {
  from = aws_iam_role.task_execution_role
  to   = module.otel_collector[0].aws_iam_role.task_execution_role
}

moved {
  from = aws_iam_role_policy_attachment.task_execution_role_policy
  to   = module.otel_collector[0].aws_iam_role_policy_attachment.task_execution_role_policy
}

moved {
  from = aws_iam_role.task_role
  to   = module.otel_collector[0].aws_iam_role.task_role
}

moved {
  from = aws_iam_role_policy.task_role_s3_policy
  to   = module.otel_collector[0].aws_iam_role_policy.task_role_s3_policy
}

moved {
  from = aws_ecs_task_definition.task_definition
  to   = module.otel_collector[0].aws_ecs_task_definition.task_definition
}

moved {
  from = aws_ecs_service.ecs_service
  to   = module.otel_collector[0].aws_ecs_service.ecs_service
}

moved {
  from = aws_iam_role.external_access_role
  to   = module.otel_storage.aws_iam_role.external_access_role
}

moved {
  from = aws_iam_policy.external_access_s3_read_only_policy
  to   = module.otel_storage.aws_iam_policy.external_access_s3_read_only_policy
}

moved {
  from = aws_iam_role_policy_attachment.external_access_policy_attachment
  to   = module.otel_storage.aws_iam_role_policy_attachment.external_access_policy_attachment
}
