# Production-Grade AWS EKS Terraform Infrastructure

## Overview

This Terraform project provisions a **production-ready AWS EKS cluster** designed for:

- Jenkins-based CI/CD workflows
- Platform team ownership
- Long-term enterprise operations
- Multiple application teams

---

## Architecture Decisions

### 1. **Modular Structure**

- **Rationale**: Separation of concerns enables reuse, testing, and maintainability
- **Modules**: VPC, EKS, Node Groups, IAM
- **Benefits**: Each module can be versioned and tested independently

### 2. **Private Networking by Default**

- **Rationale**: Security-first approach for production workloads
- **Implementation**: Nodes run in private subnets; control plane has controlled access
- **NAT Gateway**: Enabled by default for internet access (cost: ~$32/month per gateway)
- **Optimization**: Option to use single NAT Gateway across AZs for cost savings (reduces HA)

### 3. **Managed Node Groups**

- **Rationale**: AWS-managed updates, security patches, and lifecycle management
- **Default Configuration**: ON_DEMAND instances (SPOT available but not default)
- **Scaling**: Configurable min/desired/max (defaults: 1/2/5)
- **AMI**: Amazon Linux 2 (AL2_x86_64) - widely tested and supported

### 4. **Control Plane Logging Enabled**

- **Types**: api, audit, authenticator, controllerManager, scheduler
- **Rationale**: Required for compliance, security auditing, and troubleshooting
- **Retention**: 7 days (configurable in `modules/eks/main.tf`)

### 5. **OIDC Provider Enabled (IRSA-Ready)**

- **Rationale**: IAM Roles for Service Accounts enables secure AWS service access from pods
- **Usage**: Service accounts can assume IAM roles without storing credentials
- **Implementation**: OIDC provider automatically created and configured

### 6. **EKS Version Selection**

- **Version**: 1.28 (default)
- **Rationale**: Stable, widely-adopted version with modern Kubernetes features
- **TODO**: Verify this version is supported in your AWS region
- **Note**: AWS supports 1-2 minor versions behind current

### 7. **KMS Encryption**

- **Scope**: Secrets encryption at rest
- **Key Rotation**: Enabled
- **Rationale**: Enterprise security requirement

### 8. **aws-auth ConfigMap Management**

- **Default**: Terraform manages it (`manage_aws_auth_configmap = true`)
- **Alternative**: Set to `false` if platform team manages manually or via GitOps
- **Rationale**: Explicit decision point to avoid conflicts

### 9. **Jenkins Authentication Model**

- **Method**: IAM role-based authentication via aws-auth ConfigMap
- **Assumption**: Jenkins assumes an IAM role that is granted cluster access
- **TODO**: Provide Jenkins IAM role ARN in variables
- **Note**: Jenkins must have permissions to assume the role and generate kubeconfig

### 10. **No Assumptions Made**

- All uncertain values are marked with explicit TODO placeholders
- No hardcoded secrets or credentials
- No silent defaults for critical values

---

## Project Structure

```
.
├── main.tf                    # Root module - orchestrates all resources
├── variables.tf               # Input variables with TODO placeholders
├── outputs.tf                 # Cluster and resource outputs
├── locals.tf                  # Local values and computed variables
├── versions.tf                # Terraform and provider version constraints
├── providers.tf               # AWS and Kubernetes provider configuration
├── backend.tf                 # Remote state configuration (S3 + DynamoDB)
├── .gitignore                 # Git ignore patterns
├── README.md                  # This file
└── modules/
    ├── vpc/                   # VPC, subnets, NAT Gateway, route tables
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks/                   # EKS cluster, OIDC provider, KMS, CloudWatch logs
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── node_groups/           # Managed node groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── iam/                   # IAM roles for cluster and node groups
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Required Values to Fill Before Apply

### Critical Configuration (MUST be provided)

1. **AWS Region**

   - Variable: `aws_region`
   - Current: `________REPLACE_WITH_AWS_REGION________`
   - Example: `"us-east-1"`

2. **EKS Cluster Name**

   - Variable: `cluster_name`
   - Current: `________REPLACE_WITH_EKS_CLUSTER_NAME________`
   - Example: `"production-eks-cluster"`
   - Note: Must be unique within AWS account/region

3. **EKS Version**

   - Variable: `eks_version`
   - Current: `"1.28"`
   - Action: Verify this version is supported in your region
   - Command to check: `aws eks describe-addon-versions --kubernetes-version 1.28 --region <region>`

4. **VPC CIDR Block**

   - Variable: `vpc_cidr`
   - Current: `________REPLACE_WITH_VPC_CIDR_BLOCK________`
   - Example: `"10.0.0.0/16"`
   - Note: Ensure it doesn't conflict with existing networks (VPN, on-premises, etc.)

5. **Availability Zones**

   - Variable: `availability_zones`
   - Current: `["________REPLACE_WITH_AZ_1________", ...]`
   - Example: `["us-east-1a", "us-east-1b", "us-east-1c"]`
   - Action: Verify these AZs exist in your region

6. **Private Subnet CIDRs**

   - Variable: `private_subnet_cidrs`
   - Current: `["________REPLACE_WITH_PRIVATE_SUBNET_1_CIDR________", ...]`
   - Example: `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]`
   - Note: Must be within VPC CIDR, non-overlapping

7. **Public Subnet CIDRs** (if `enable_public_subnets = true`)

   - Variable: `public_subnet_cidrs`
   - Example: `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]`

8. **Node Group Instance Types**

   - Variable: `node_group_instance_types`
   - Current: `["________REPLACE_WITH_NODE_INSTANCE_TYPE________"]`
   - Example: `["t3.large"]` or `["m5.large", "m5.xlarge"]`
   - Considerations:
     - CPU/memory requirements
     - Cost optimization
     - Workload characteristics

9. **Node Scaling Configuration**

   - Variables: `node_group_min_size`, `node_group_desired_size`, `node_group_max_size`
   - Current defaults: `1`, `2`, `5`
   - Action: Adjust based on workload requirements and cost constraints

10. **Jenkins IAM Role ARN**

    - Variable: `jenkins_iam_role_arn`
    - Current: `________REPLACE_WITH_JENKINS_IAM_ROLE_ARN________`
    - Example: `"arn:aws:iam::123456789012:role/jenkins-eks-access"`
    - Note: This role must have permissions to assume node group role or use `eks:DescribeCluster`

11. **Environment Name**
    - Variable: `environment`
    - Current: `________REPLACE_WITH_ENVIRONMENT_NAME________`
    - Example: `"prod"`, `"staging"`, `"dev"`

### Backend Configuration (MUST be configured before first `terraform init`)

1. **S3 Bucket for State**

   - File: `backend.tf`
   - Replace: `________REPLACE_WITH_S3_BUCKET_NAME_FOR_TERRAFORM_STATE________`
   - Action: Create bucket before initializing Terraform

2. **DynamoDB Table for Locking**

   - File: `backend.tf`
   - Replace: `________REPLACE_WITH_DYNAMODB_TABLE_NAME_FOR_LOCKING________`
   - Action: Create table before initializing Terraform

3. **Backend Region**
   - File: `backend.tf`
   - Replace: `________REPLACE_WITH_AWS_REGION_FOR_BACKEND________`

See `backend.tf` comments for creation commands.

---

## Security & Operations Notes

### Why This Setup is Safe

1. **No Hardcoded Credentials**

   - All authentication uses IAM roles
   - Secrets are managed via AWS Secrets Manager or Kubernetes secrets

2. **Least-Privilege IAM**

   - Separate roles for cluster and node groups
   - Node groups have minimal required permissions

3. **Private Networking**

   - Nodes in private subnets (no direct internet exposure)
   - Control plane endpoints can be restricted via `endpoint_public_access_cidrs`

4. **Encryption at Rest**

   - KMS encryption for secrets
   - EBS volumes encrypted by default (if EBS CSI driver used)

5. **Audit Trail**

   - CloudWatch logs for all control plane activities
   - AWS CloudTrail for API calls

6. **No Auto-Apply**
   - `terraform apply` must be executed manually
   - No automatic destruction enabled

### What Must Be Reviewed Before Production

1. **Network Security**

   - Review security groups (default EKS security groups created)
   - Consider Network Policies for pod-to-pod communication
   - Evaluate VPC endpoint usage for AWS service access (cost vs. security)

2. **Node Group Configuration**

   - Instance types and sizes
   - Scaling limits (prevent cost overruns)
   - Taints/labels for workload placement

3. **Access Control**

   - Review aws-auth ConfigMap entries
   - Consider RBAC policies for fine-grained Kubernetes access
   - Evaluate need for additional admin users/roles

4. **Compliance Requirements**

   - Log retention periods (currently 7 days)
   - Encryption key rotation policies
   - Backup/disaster recovery strategy

5. **Cost Optimization**

   - NAT Gateway usage (consider single NAT if HA not required)
   - Node group sizing and scaling
   - Reserved instances for predictable workloads

6. **Monitoring & Observability**
   - Configure CloudWatch Container Insights
   - Set up Prometheus/Grafana (if required)
   - Configure alerting for cluster/node health

### CI/CD Allowed and Forbidden

#### ✅ Allowed (Recommended)

- **Jenkins Jobs**:

  - Run `terraform plan` on pull requests
  - Run `terraform apply` only after human approval
  - Generate and validate kubeconfig via AWS CLI
  - Deploy Kubernetes manifests via kubectl/helm

- **GitOps Workflows**:
  - ArgoCD/Flux for application deployments (if `manage_aws_auth_configmap = false`)
  - Helm charts for application management

#### ❌ Forbidden (Safety)

- **NEVER**:
  - Auto-apply Terraform on merge
  - Run `terraform destroy` in CI/CD (must be manual)
  - Store kubeconfig files in version control
  - Hardcode AWS credentials in Jenkinsfiles
  - Allow unrestricted cluster admin access

---

## Jenkins ↔ EKS Authentication Model

### Overview

Jenkins authenticates to the EKS cluster using **IAM role-based authentication** via the `aws-auth` ConfigMap.

### Implementation

1. **Jenkins IAM Role**

   - Jenkins assumes an IAM role (provided via `jenkins_iam_role_arn` variable)
   - This role is granted `system:masters` group in aws-auth ConfigMap

2. **Kubeconfig Generation**

   - Jenkins generates kubeconfig using AWS CLI:
     ```bash
     aws eks update-kubeconfig --region <region> --name <cluster-name>
     ```
   - AWS CLI uses the assumed IAM role credentials

3. **Required Permissions for Jenkins Role**
   - `eks:DescribeCluster` (to generate kubeconfig)
   - `eks:ListClusters` (optional, for discovery)
   - The role must be able to assume itself or use instance profile

### TODO

- [ ] Identify Jenkins IAM role ARN
- [ ] Verify Jenkins has permissions to assume the role
- [ ] Test kubeconfig generation from Jenkins environment
- [ ] Document Jenkins pipeline steps for cluster access

---

## aws-auth ConfigMap Ownership Decision

### Current Configuration

- **Default**: `manage_aws_auth_configmap = true` (Terraform manages it)

### Decision Points

#### Option 1: Terraform Manages (Current Default)

- **Pros**: Infrastructure as Code, versioned, auditable
- **Cons**: Manual changes outside Terraform can cause drift
- **Use Case**: Centralized platform team managing all access

#### Option 2: Platform Team Manages Manually

- **Pros**: Flexibility for rapid access changes
- **Cons**: Not versioned, manual process, potential for mistakes
- **Use Case**: Frequent access changes, smaller teams

#### Option 3: GitOps Manages

- **Pros**: Versioned in Git, auditable, can integrate with approval workflows
- **Cons**: Requires GitOps setup, additional complexity
- **Use Case**: Large organizations with GitOps workflows

### Recommendation

- **Initial Setup**: Use Terraform (`manage_aws_auth_configmap = true`)
- **Long-term**: Consider migrating to GitOps if your organization uses it
- **Action**: Set `manage_aws_auth_configmap = false` in `variables.tf` if you choose manual or GitOps management

---

## Usage

### Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform >= 1.5.0** installed
3. **kubectl** installed (for cluster access)
4. **Backend resources created** (S3 bucket, DynamoDB table)

### Initial Setup

1. **Fill all TODO placeholders** in `variables.tf` and `backend.tf`

2. **Create backend resources**:

   ```bash
   # Example (replace placeholders)
   aws s3 mb s3://terraform-state-bucket --region us-east-1
   aws s3api put-bucket-versioning --bucket terraform-state-bucket --versioning-configuration Status=Enabled
   aws s3api put-bucket-encryption --bucket terraform-state-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

3. **Initialize Terraform**:

   ```bash
   terraform init
   ```

4. **Review plan** (MANDATORY):

   ```bash
   terraform plan -out=tfplan
   ```

5. **Apply** (after human review):
   ```bash
   terraform apply tfplan
   ```

### Accessing the Cluster

After applying, generate kubeconfig:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

Verify access:

```bash
kubectl get nodes
kubectl get namespaces
```

---

## Cost Considerations

### Estimated Monthly Costs (Approximate)

- **EKS Control Plane**: ~$73/month
- **NAT Gateway**: ~$32/month per gateway (3 AZs = ~$96/month with HA, or ~$32/month with single NAT)
- **EC2 Instances**: Depends on instance types and count
  - t3.large (2 instances): ~$60/month
  - m5.large (2 instances): ~$134/month
- **CloudWatch Logs**: ~$0.50/GB ingested (first 5GB free)
- **EBS Volumes**: Included in EC2 (default 50GB per node)
- **Data Transfer**: Varies based on usage

### Cost Optimization Tips

1. Use single NAT Gateway if HA not required
2. Consider SPOT instances for non-critical workloads
3. Right-size node groups based on actual usage
4. Use cluster autoscaler to scale down during low usage
5. Enable VPC endpoints for AWS services (if data transfer costs are high)

---

## Maintenance & Updates

### EKS Version Upgrades

1. Check supported versions:

   ```bash
   aws eks describe-addon-versions --kubernetes-version <current-version> --region <region>
   ```

2. Update `eks_version` variable

3. Plan and apply (AWS handles control plane upgrade automatically)

4. Update node groups (separate operation, can be done via AWS Console or Terraform)

### Node Group Updates

- Managed node groups support automatic AMI updates
- Scaling changes can be made via Terraform variables
- Instance type changes may require node group recreation (plan carefully)

### Security Patches

- EKS control plane: AWS manages automatically
- Node AMIs: Updated via node group updates (can be automated)

---

## Troubleshooting

### Common Issues

1. **"Error: InvalidParameterException: Subnets specified must be in at least two different Availability Zones"**

   - Solution: Ensure subnets span at least 2 AZs

2. **"Error: Insufficient permissions"**

   - Solution: Verify IAM roles have required policies attached

3. **"Error: VPC CIDR conflicts with existing network"**

   - Solution: Choose a different VPC CIDR block

4. **Nodes not joining cluster**
   - Check: Node group IAM role has required policies
   - Check: Security groups allow communication between nodes and control plane
   - Check: Nodes can reach control plane endpoint (if private)

---

## Additional Resources

- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

---

## Support & Contributions

This is a production-grade baseline. Customize as needed for your organization's requirements.

**Remember**: Always review `terraform plan` output before applying in production!
